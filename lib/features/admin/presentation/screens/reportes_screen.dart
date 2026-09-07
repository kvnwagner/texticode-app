import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/services/reporte_pdf_service.dart';
import '../../data/services/excel_reporte_service.dart';

const _tiposFiltro = ['Todos los tipos', 'Pedidos', 'Eficiencia', 'Inventario'];

/// Pantalla "Reportes" — sigue los mismos tokens visuales del resto del
/// panel admin (mismo header y mismas cards de métrica que Clientes).
///
/// Los 4 KPI se calculan en tiempo real a partir de las órdenes reales
/// (OrdenRepository). "Descargar" y "Exportar Excel" abren una vista
/// previa real (PDF con PdfPreview, Excel con una tabla) antes de
/// imprimir/compartir — igual patrón que el comprobante de entrega en
/// ClientesScreen (_ComprobantePreviewSheet).
///
/// ⚠️ Nota sobre "Pendientes": el ENUM real de `Estado` en la base de
/// datos es `En Proceso | Completada | Pausado` (ver comentario en
/// orden_model.dart) — el valor 'Pendiente' NUNCA llega desde el backend.
/// El cálculo anterior comparaba contra 'Pendiente' y por eso ese KPI y
/// el reporte correspondiente siempre mostraban 0. Aquí se usa `Pausado`,
/// el estado real más cercano a "pedido detenido / sin avanzar".
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

/// Agrupa lo necesario para generar tanto la vista previa como el
/// archivo final de un reporte, para no duplicar la lógica entre el
/// botón "Descargar" y "Exportar Excel".
class _TablaReporte {
  final String titulo;
  final String subtitulo;
  final List<String> headers;
  final List<List<String>> filas;

  /// Pesos relativos de ancho por columna (mismo largo que headers).
  /// Sin esto, PDF y Excel autoajustan cada columna a su contenido y
  /// con columnas de texto largo mezcladas con columnas cortas el
  /// resultado se ve desparejo/distorsionado.
  final List<int> columnFlex;

  const _TablaReporte({
    required this.titulo,
    required this.subtitulo,
    required this.headers,
    required this.filas,
    required this.columnFlex,
  });

  /// Excel usa anchos absolutos, no pesos relativos — se escala el
  /// mismo columnFlex a un rango razonable (16–34) en vez de duplicar
  /// los números en dos lugares distintos.
  List<double> get columnWidthsExcel =>
      columnFlex.map((f) => 14.0 + (f * 6.0)).toList();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _ordenRepo = OrdenRepository();
  final _materialRepo = MaterialRepository();

  List<Orden> _ordenes = [];
  List<MaterialItem> _materiales = [];
  bool _loading = true;
  String? _error;
  String _filtro = 'Todos los tipos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ordenes = await _ordenRepo.getOrdenes();
      List<MaterialItem> materiales = [];
      try {
        materiales = await _materialRepo.getMateriales();
      } catch (_) {
        // Si falla materiales no bloqueamos toda la pantalla de reportes.
      }
      if (!mounted) return;
      setState(() {
        _ordenes = ordenes;
        _materiales = materiales;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── KPIs reales ───────────────────────────────────────────────────────
  int get _total => _ordenes.length;
  int get _completados => _ordenes.where((o) => o.isCompletada).length;

  // Corregido: 'Pendiente' no existe en el ENUM real (En Proceso |
  // Completada | Pausado). Se usa Pausado, el estado real más cercano.
  int get _pendientes => _ordenes.where((o) => o.isPausado).length;

  double get _tasaCompletacion => _total == 0 ? 0 : (_completados / _total) * 100;

  bool _visible(String tipo) => _filtro == 'Todos los tipos' || _filtro == tipo;

  // ── Datos de cada reporte (se usan tanto para el PDF como el Excel) ────

  _TablaReporte _tablaPedidos() => _TablaReporte(
        titulo: 'Pedidos',
        subtitulo: _total == 0 ? 'Sin órdenes registradas' : '$_total órdenes registradas',
        headers: const ['Código', 'Producto', 'Cliente', 'Operario', 'Estado', 'Progreso'],
        filas: _ordenes
            .map((o) => [
                  o.codigoOrden,
                  o.producto,
                  o.cliente,
                  o.operario,
                  o.estadoLabel,
                  '${o.progresoPorcentaje}%',
                ])
            .toList(),
        columnFlex: const [2, 3, 3, 3, 2, 2],
      );

  _TablaReporte _tablaPedidosPendientes() {
    final pendientes = _ordenes.where((o) => o.isPausado).toList();
    return _TablaReporte(
      titulo: 'Pedidos Pendientes',
      subtitulo: pendientes.isEmpty ? 'Sin pedidos pendientes' : '${pendientes.length} pedidos pendientes',
      headers: const ['Código', 'Producto', 'Cliente', 'Operario', 'Estado', 'Progreso'],
      filas: pendientes
          .map((o) => [
                o.codigoOrden,
                o.producto,
                o.cliente,
                o.operario,
                o.estadoLabel,
                '${o.progresoPorcentaje}%',
              ])
          .toList(),
      columnFlex: const [2, 3, 3, 3, 2, 2],
    );
  }

  _TablaReporte _tablaEficiencia() {
    final porOperario = <String, List<Orden>>{};
    for (final o in _ordenes) {
      porOperario.putIfAbsent(o.operario, () => []).add(o);
    }
    return _TablaReporte(
      titulo: 'Eficiencia Operaria',
      subtitulo: porOperario.isEmpty
          ? 'Sin datos de operarios'
          : '${porOperario.length} operarios con órdenes asignadas',
      headers: const ['Operario', 'Órdenes Asignadas', 'Completadas', '% Completación'],
      filas: porOperario.entries.map((e) {
        final totalOp = e.value.length;
        final compOp = e.value.where((o) => o.isCompletada).length;
        final pct = totalOp == 0 ? 0 : ((compOp / totalOp) * 100).round();
        return [e.key, '$totalOp', '$compOp', '$pct%'];
      }).toList(),
      columnFlex: const [3, 2, 2, 2],
    );
  }

  _TablaReporte _tablaInventario() => _TablaReporte(
        titulo: 'Inventario',
        subtitulo: _materiales.isEmpty
            ? 'Sin materiales registrados'
            : '${_materiales.length} materiales en inventario',
        headers: const ['Material', 'Categoría', 'Stock', 'Mínimo', 'Máximo'],
        filas: _materiales
            .map((m) => [
                  m.nombre,
                  m.categoria,
                  '${m.stockActual} ${m.unidad}',
                  '${m.stockMinimo}',
                  '${m.stockMaximo}',
                ])
            .toList(),
        columnFlex: const [3, 2, 2, 1, 1],
      );

  // ── Vista previa PDF / Excel ─────────────────────────────────────────

  void _verPdf(_TablaReporte t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportePdfPreviewSheet(
        titulo: t.titulo,
        subtitulo: t.subtitulo,
        headers: t.headers,
        filas: t.filas,
        columnFlex: t.columnFlex,
      ),
    );
  }

  void _verExcel(_TablaReporte t, String nombreArchivo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReporteExcelPreviewSheet(
        titulo: t.titulo,
        headers: t.headers,
        filas: t.filas,
        onExportar: () => _exportarExcel(t, nombreArchivo),
      ),
    );
  }

  Future<void> _exportarExcel(_TablaReporte t, String nombreArchivo) async {
    final bytes = ExcelReporteService.generar(
      titulo: t.titulo,
      headers: t.headers,
      filas: t.filas,
      columnWidths: t.columnWidthsExcel,
    );
    await _compartirBytes(bytes, nombreArchivo);
  }

  Future<void> _compartirBytes(List<int> bytes, String nombreArchivo) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombreArchivo');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Texticode');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        color: AppColors.navy,
                        onRefresh: _cargar,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            _buildKpis(),
                            _buildSectionHeader(),
                            if (_visible('Pedidos')) _buildReportCard(
                              icon: Icons.description_outlined,
                              titulo: 'Reporte de Pedidos Mensuales',
                              subtitulo: _tablaPedidos().subtitulo,
                              onDescargar: () => _verPdf(_tablaPedidos()),
                              onExportarExcel: () => _verExcel(_tablaPedidos(), 'reporte_pedidos.xlsx'),
                            ),
                            if (_visible('Pedidos')) _buildReportCard(
                              icon: Icons.pending_actions_outlined,
                              titulo: 'Reporte de Pedidos Pendientes',
                              subtitulo: _tablaPedidosPendientes().subtitulo,
                              onDescargar: () => _verPdf(_tablaPedidosPendientes()),
                              onExportarExcel: () =>
                                  _verExcel(_tablaPedidosPendientes(), 'reporte_pedidos_pendientes.xlsx'),
                            ),
                            if (_visible('Eficiencia')) _buildReportCard(
                              icon: Icons.bar_chart_rounded,
                              titulo: 'Reporte de Eficiencia Operaria',
                              subtitulo: _tablaEficiencia().subtitulo,
                              onDescargar: () => _verPdf(_tablaEficiencia()),
                              onExportarExcel: () => _verExcel(_tablaEficiencia(), 'reporte_eficiencia.xlsx'),
                            ),
                            if (_visible('Inventario')) _buildReportCard(
                              icon: Icons.table_chart_outlined,
                              titulo: 'Reporte de Inventario',
                              subtitulo: _tablaInventario().subtitulo,
                              onDescargar: () => _verPdf(_tablaInventario()),
                              onExportarExcel: () => _verExcel(_tablaInventario(), 'reporte_inventario.xlsx'),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Encabezado (mismo estilo que Clientes: sin descripción, logo
  //    55x55, línea separadora en la parte inferior) ────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            height: 55,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF2D5478)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Reportes',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  // ── KPIs: mismo diseño que _buildMetricCard de Clientes (barra lateral
  //    de color + icono circular), en grilla de 2x2 para las 4 métricas ──

  Widget _buildKpis() {
    final items = <_MetricItem>[
      _MetricItem('Pedidos Totales', '$_total', Icons.description_outlined, AppColors.navy),
      _MetricItem('Completados', '$_completados', Icons.verified_user_outlined, AppColors.iconActive),
      _MetricItem('Tasa Completación', '${_tasaCompletacion.toStringAsFixed(1)}%', Icons.trending_up_rounded,
          AppColors.purple),
      _MetricItem('Pendientes', '$_pendientes', Icons.pause_circle_outline, AppColors.iconClient),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 128,
        ),
        itemBuilder: (context, i) => _buildMetricCard(items[i]),
      ),
    );
  }

  Widget _buildMetricCard(_MetricItem metric) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3.5, color: metric.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(metric.icon, size: 17, color: metric.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.value,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: metric.color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Encabezado de sección: el filtro conserva su estilo original
  //    (fondo claro, borde, ícono + texto + flecha) pero vive aquí en
  //    vez de en una fila propia arriba del todo. Se usa PopupMenuButton
  //    en vez de un Positioned fijo porque este control ahora está
  //    dentro del ListView con scroll — un Positioned con coordenadas
  //    fijas se desalinearía apenas el usuario scrollea. PopupMenuButton
  //    se ancla solo al botón sin importar el scroll. ─────────────────

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Reportes Disponibles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: Colors.white,
            offset: const Offset(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            onSelected: (v) => setState(() => _filtro = v),
            itemBuilder: (context) => _tiposFiltro.map((t) {
              final selected = t == _filtro;
              return PopupMenuItem<String>(
                value: t,
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? AppColors.navy : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      _filtro,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 15, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onDescargar,
    required VoidCallback onExportarExcel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.searchBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 17, color: AppColors.navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitulo,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.badgeOpGreenBg, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Generado',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.badgeOpGreenText)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDescargar,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Vista previa', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportarExcel,
                    icon: const Icon(Icons.table_chart_outlined, size: 14),
                    label: const Text('Exportar Excel', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.badgeOpGreenText,
                      side: BorderSide(color: AppColors.badgeOpGreenText.withValues(alpha: 0.4)),
                      backgroundColor: AppColors.badgeOpGreenBg,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem(this.label, this.value, this.icon, this.color);
}

// ── Vista previa del PDF de un reporte (mismo patrón que
//    _ComprobantePreviewSheet en clientes_screen.dart) ───────────────────

class _ReportePdfPreviewSheet extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<String> headers;
  final List<List<String>> filas;
  final List<int> columnFlex;

  const _ReportePdfPreviewSheet({
    required this.titulo,
    required this.subtitulo,
    required this.headers,
    required this.filas,
    required this.columnFlex,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reporte de $titulo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: ReportePdfService.generar(
                    titulo: titulo,
                    subtitulo: subtitulo,
                    headers: headers,
                    filas: filas,
                    columnFlex: columnFlex,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.navy),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'No se pudo generar la vista previa.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      );
                    }

                    return PdfPreview(
                      build: (format) async => snapshot.data!,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      allowSharing: true,
                      allowPrinting: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Vista previa del Excel de un reporte: como un .xlsx no se puede
//    renderizar visualmente igual que un PDF, se arma una tabla con los
//    mismos datos y el mismo estilo (header navy, filas zebra) que va a
//    tener el archivo real, con un botón para exportar/compartir. ───────

class _ReporteExcelPreviewSheet extends StatefulWidget {
  final String titulo;
  final List<String> headers;
  final List<List<String>> filas;
  final Future<void> Function() onExportar;

  const _ReporteExcelPreviewSheet({
    required this.titulo,
    required this.headers,
    required this.filas,
    required this.onExportar,
  });

  @override
  State<_ReporteExcelPreviewSheet> createState() => _ReporteExcelPreviewSheetState();
}

class _ReporteExcelPreviewSheetState extends State<_ReporteExcelPreviewSheet> {
  bool _exportando = false;

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      await widget.onExportar();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar el reporte: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reporte de ${widget.titulo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.filas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay datos para exportar.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildTabla(),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _exportando || widget.filas.isEmpty ? null : _exportar,
                    icon: _exportando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.ios_share, size: 18),
                    label: Text(_exportando ? 'Exportando…' : 'Exportar y compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabla() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
      child: Table(
        border: TableBorder.symmetric(inside: const BorderSide(color: AppColors.cardBorder)),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.navy),
            children: widget.headers
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        h,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ))
                .toList(),
          ),
          ...widget.filas.asMap().entries.map((entry) {
            final esImpar = entry.key.isOdd;
            return TableRow(
              decoration: BoxDecoration(color: esImpar ? AppColors.searchBg : Colors.white),
              children: entry.value
                  .map((v) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Text(
                          v,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}