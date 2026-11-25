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
import '../../data/models/eficiencia_operario_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/eficiencia_repository.dart';
import '../../data/services/reporte_pdf_service.dart';
import '../../data/services/excel_reporte_service.dart';

const _tiposFiltro = ['Todos los tipos', 'Pedidos', 'Eficiencia', 'Inventario'];

/// Pantalla "Reportes" — sigue los mismos tokens visuales del resto del
/// panel admin (mismo header y mismas cards de métrica que Clientes).
///
/// Los 4 KPI se calculan en tiempo real a partir de las órdenes reales
/// (OrdenRepository). "PDF" abre una vista previa real (con zoom
/// directo por imagen) antes de imprimir/compartir — igual patrón que
/// el comprobante de entrega en ClientesScreen (_ComprobantePreviewSheet).
/// "Excel" exporta y comparte directo, sin vista previa intermedia.
///
/// ⚠️ Nota sobre "Pendientes": son todas las órdenes que NO están
/// Completadas (En Proceso, Retrasada o Pausada). El cálculo anterior
/// comparaba únicamente contra un único estado puntual y dejaba fuera
/// órdenes reales en proceso/retrasadas, mostrando un conteo más bajo
/// del real.
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

  final List<int> columnFlex;

  /// Índice (0-based) de la columna "Estado" en [headers]/cada fila de
  /// [filas], si el reporte tiene una. Null en Eficiencia/Inventario,
  /// que no tienen esa columna.
  final int? estadoColumnIndex;

  const _TablaReporte({
    required this.titulo,
    required this.subtitulo,
    required this.headers,
    required this.filas,
    required this.columnFlex,
    this.estadoColumnIndex,
  });

  List<double> get columnWidthsExcel =>
      columnFlex.map((f) => 14.0 + (f * 6.0)).toList();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _ordenRepo = OrdenRepository();
  final _materialRepo = MaterialRepository();
  final _eficienciaRepo = EficienciaRepository();

  List<Orden> _ordenes = [];
  List<MaterialItem> _materiales = [];
  List<EficienciaOperario> _operarios = [];
  String? _errorOperarios;
  bool _loading = true;
  String? _error;
  String _filtro = 'Todos los tipos';

  /// '' = todos los períodos. Si no, clave "YYYY-MM" de un mes que
  /// realmente tiene al menos una orden (nunca se ofrece un mes vacío).
  String _mesFiltro = '';

  static const _nombresMeses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  /// Clave "YYYY-MM" de la fecha límite de una orden, o null si no tiene
  /// fecha válida (esas órdenes no participan del filtro de mes).
  String? _mesKeyDe(Orden o) {
    if (o.fechaLimite == null || o.fechaLimite!.isEmpty) return null;
    final d = DateTime.tryParse(o.fechaLimite!);
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  String _mesLabel(String key) {
    final partes = key.split('-');
    final anio = partes[0];
    final mes = int.parse(partes[1]);
    return '${_nombresMeses[mes - 1]} $anio';
  }

  /// Meses que realmente existen en los datos cargados, más recientes
  /// primero. Nunca incluye un mes sin órdenes.
  List<String> get _mesesDisponibles {
    final claves = <String>{};
    for (final o in _ordenes) {
      final k = _mesKeyDe(o);
      if (k != null) claves.add(k);
    }
    final lista = claves.toList()..sort((a, b) => b.compareTo(a));
    return lista;
  }

  List<Orden> get _ordenesDelPeriodo {
    if (_mesFiltro.isEmpty) return _ordenes;
    return _ordenes.where((o) => _mesKeyDe(o) == _mesFiltro).toList();
  }

  String get _periodoLabel =>
      _mesFiltro.isEmpty ? 'Todos los períodos' : _mesLabel(_mesFiltro);

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
      if (!mounted) return;
      setState(() {
        _ordenes = ordenes;
        final clavesActuales = <String>{
          for (final o in ordenes)
            if (_mesKeyDe(o) != null) _mesKeyDe(o)!,
        };
        if (_mesFiltro.isNotEmpty && !clavesActuales.contains(_mesFiltro)) {
          _mesFiltro = '';
        }
      });
      // Eficiencia e Inventario se cargan aparte (mismas funciones que
      // usa el selector de mes al cambiar de período), para no
      // duplicar la lógica de "con período" vs "datos actuales".
      await Future.wait([
        _actualizarEficienciaPorPeriodo(),
        _actualizarInventarioPorPeriodo(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Trae la eficiencia de operarios para el período actualmente
  /// seleccionado (_mesFiltro). Sin filtro, trae el acumulado histórico
  /// completo (comportamiento de siempre). No toca _loading/_error de
  /// arriba a propósito: se llama también al cambiar de mes desde el
  /// dropdown, y ahí no queremos que toda la pantalla parpadee a un
  /// spinner de carga completa, solo esta tarjeta.
  Future<void> _actualizarEficienciaPorPeriodo() async {
    try {
      final operarios = await _eficienciaRepo.getOperarios(
        periodo: _mesFiltro.isEmpty ? null : _mesFiltro,
      );
      if (!mounted) return;
      setState(() {
        _operarios = operarios;
        _errorOperarios = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _operarios = [];
        _errorOperarios = msg;
      });
      // ignore: avoid_print
      print('EficienciaRepository.getOperarios() falló: $e');
    }
  }

  /// Trae el inventario para el período actualmente seleccionado. Sin
  /// filtro, trae el stock actual (foto del momento, como siempre).
  /// Con un mes elegido, reconstruye el inventario de ese mes a partir
  /// de la bitácora de movimientos — solo hay datos reales desde que
  /// se activó esa migración en adelante; un mes anterior a eso
  /// legítimamente devuelve una lista vacía, no un error.
  Future<void> _actualizarInventarioPorPeriodo() async {
    try {
      final materiales = _mesFiltro.isEmpty
          ? await _materialRepo.getMateriales()
          : await _materialRepo.getHistorialInventario(_mesFiltro);
      if (!mounted) return;
      setState(() => _materiales = materiales);
    } catch (e) {
      if (!mounted) return;
      setState(() => _materiales = []);
      // ignore: avoid_print
      print('Carga de inventario falló: $e');
    }
  }

  int get _total => _ordenes.length;
  int get _completados => _ordenes.where((o) => o.isCompletada).length;
  int get _pendientes => _ordenes.where((o) => !o.isCompletada).length;
  double get _tasaCompletacion => _total == 0 ? 0 : (_completados / _total) * 100;

  bool _visible(String tipo) => _filtro == 'Todos los tipos' || _filtro == tipo;

  _TablaReporte _tablaPedidos() {
    final base = _ordenesDelPeriodo;
    return _TablaReporte(
      titulo: 'Pedidos',
      subtitulo: base.isEmpty
          ? 'Sin órdenes registradas · $_periodoLabel'
          : '${base.length} órdenes registradas · $_periodoLabel',
      headers: const ['Código', 'Producto', 'Cliente', 'Operario', 'Estado', 'Progreso'],
      filas: base
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
      estadoColumnIndex: 4,
    );
  }

  _TablaReporte _tablaPedidosPendientes() {
    final pendientes = _ordenesDelPeriodo.where((o) => !o.isCompletada).toList();
    return _TablaReporte(
      titulo: 'Pedidos Pendientes',
      subtitulo: pendientes.isEmpty
          ? 'Sin pedidos pendientes · $_periodoLabel'
          : '${pendientes.length} pedidos pendientes · $_periodoLabel',
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
      estadoColumnIndex: 4,
    );
  }

  _TablaReporte _tablaEficiencia() {
    final sufijo = _mesFiltro.isEmpty ? 'Datos actuales' : _periodoLabel;
    return _TablaReporte(
      titulo: 'Eficiencia Operaria',
      subtitulo: _errorOperarios != null
          ? 'Error al cargar: $_errorOperarios · $sufijo'
          : _operarios.isEmpty
              ? 'Sin datos de operarios · $sufijo'
              : '${_operarios.length} operarios evaluados · $sufijo',
      headers: const [
        'Operario',
        'Rendimiento',
        'Prendas/Día',
        'Unidades Producidas',
        'Completadas',
        'Retrasadas',
      ],
      filas: _operarios
          .map((o) => [
                o.nombreCompleto,
                o.rendimiento,
                o.prendasPorDia.toStringAsFixed(1),
                '${o.totalUnidadesProducidas}',
                '${o.ordenesCompletadas}',
                '${o.ordenesEnRetraso}',
              ])
          .toList(),
      columnFlex: const [3, 2, 2, 2, 2, 2],
    );
  }

  _TablaReporte _tablaInventario() {
    final sufijo = _mesFiltro.isEmpty ? 'Datos actuales' : _periodoLabel;
    return _TablaReporte(
      titulo: 'Inventario',
      subtitulo: _materiales.isEmpty
          ? (_mesFiltro.isEmpty
              ? 'Sin materiales registrados · $sufijo'
              : 'Sin datos de inventario para este período · $sufijo')
          : '${_materiales.length} materiales en inventario · $sufijo',
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
  }

  bool _exportando = false;

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
        estadoColumnIndex: t.estadoColumnIndex,
      ),
    );
  }

  Future<void> _descargarPdf(_TablaReporte t, String nombreArchivo) async {
    setState(() => _exportando = true);
    try {
      final bytes = await ReportePdfService.generar(
        titulo: t.titulo,
        subtitulo: t.subtitulo,
        headers: t.headers,
        filas: t.filas,
        columnFlex: t.columnFlex,
        estadoColumnIndex: t.estadoColumnIndex,
      );
      await Printing.layoutPdf(onLayout: (_) => bytes, name: nombreArchivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _descargarExcel(_TablaReporte t, String nombreArchivo) async {
    setState(() => _exportando = true);
    try {
      await _exportarExcel(t, nombreArchivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarExcel(_TablaReporte t, String nombreArchivo) async {
    final bytes = ExcelReporteService.generar(
      titulo: t.titulo,
      headers: t.headers,
      filas: t.filas,
      columnWidths: t.columnWidthsExcel,
      estadoColumnIndex: t.estadoColumnIndex,
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
      child: Stack(
        children: [
          Column(
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
                                if (_visible('Pedidos'))
                                  _buildReportCard(
                                    icon: Icons.description_outlined,
                                    titulo: 'Reporte de Pedidos Mensuales',
                                    subtitulo: _tablaPedidos().subtitulo,
                                    onVer: () => _verPdf(_tablaPedidos()),
                                    onDescargar: () => _descargarPdf(_tablaPedidos(), 'reporte_pedidos.pdf'),
                                    onExportarExcel: () =>
                                        _descargarExcel(_tablaPedidos(), 'reporte_pedidos.xlsx'),
                                  ),
                                if (_visible('Pedidos'))
                                  _buildReportCard(
                                    icon: Icons.pending_actions_outlined,
                                    titulo: 'Reporte de Pedidos Pendientes',
                                    subtitulo: _tablaPedidosPendientes().subtitulo,
                                    onVer: () => _verPdf(_tablaPedidosPendientes()),
                                    onDescargar: () => _descargarPdf(
                                        _tablaPedidosPendientes(), 'reporte_pedidos_pendientes.pdf'),
                                    onExportarExcel: () => _descargarExcel(
                                        _tablaPedidosPendientes(), 'reporte_pedidos_pendientes.xlsx'),
                                  ),
                                if (_visible('Eficiencia'))
                                  _buildReportCard(
                                    icon: Icons.bar_chart_rounded,
                                    titulo: 'Reporte de Eficiencia Operaria',
                                    subtitulo: _tablaEficiencia().subtitulo,
                                    onVer: () => _verPdf(_tablaEficiencia()),
                                    onDescargar: () =>
                                        _descargarPdf(_tablaEficiencia(), 'reporte_eficiencia.pdf'),
                                    onExportarExcel: () =>
                                        _descargarExcel(_tablaEficiencia(), 'reporte_eficiencia.xlsx'),
                                  ),
                                if (_visible('Inventario'))
                                  _buildReportCard(
                                    icon: Icons.table_chart_outlined,
                                    titulo: 'Reporte de Inventario',
                                    subtitulo: _tablaInventario().subtitulo,
                                    onVer: () => _verPdf(_tablaInventario()),
                                    onDescargar: () =>
                                        _descargarPdf(_tablaInventario(), 'reporte_inventario.pdf'),
                                    onExportarExcel: () =>
                                        _descargarExcel(_tablaInventario(), 'reporte_inventario.xlsx'),
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
          if (_exportando)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.navy),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            height: 55,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Reportes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpis() {
    final items = <_MetricItem>[
      _MetricItem('Pedidos Totales', '$_total', Icons.description_outlined, AppColors.navy),
      _MetricItem('Completados', '$_completados', Icons.verified_user_outlined, AppColors.iconActive),
      _MetricItem('Tasa Completación', '${_tasaCompletacion.toStringAsFixed(1)}%', Icons.trending_up_rounded,
          AppColors.purple),
      _MetricItem('Pendientes', '$_pendientes', Icons.pause_circle_outline, AppColors.iconClient),
    ];

    // ✅ FIX "universal": la altura fija de 78px funcionaba bien en un
    // celular, pero en otros (distinto tamaño de fuente del sistema,
    // distinta densidad de píxeles) el contenido de la card (número +
    // spacing + label) terminaba siendo más alto que esos 78px, causando
    // el RenderFlex overflow. Ahora la altura se calcula en base al
    // textScaler del dispositivo (MediaQuery), así crece si el usuario
    // tiene fuente grande y se mantiene compacta si no. Además, el
    // número dentro de cada card va envuelto en un FittedBox que lo
    // reduce automáticamente si por cualquier motivo no entra en el
    // espacio disponible, así que nunca puede generar overflow sin
    // importar el tamaño o densidad de pantalla del emulador/celular.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardHeight = 78 * textScale.clamp(1.0, 1.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: cardHeight, // altura responsive, nunca fija
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
          children: [
            Container(width: 3.5, color: metric.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(metric.value,
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.bold, color: metric.color)),
                          ),
                          const SizedBox(height: 3),
                          Text(metric.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(metric.icon, size: 16, color: metric.color),
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

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: Colors.white,
            offset: const Offset(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            onSelected: (v) {
              setState(() => _mesFiltro = v);
              _actualizarEficienciaPorPeriodo();
              _actualizarInventarioPorPeriodo();
            },
            itemBuilder: (context) {
              final meses = _mesesDisponibles;
              return [
                PopupMenuItem<String>(
                  value: '',
                  child: Text(
                    'Todos los períodos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _mesFiltro.isEmpty ? FontWeight.bold : FontWeight.normal,
                      color: _mesFiltro.isEmpty ? AppColors.navy : AppColors.textSecondary,
                    ),
                  ),
                ),
                // Solo se listan meses que realmente tienen al menos una
                // orden registrada — nunca un mes vacío.
                for (final key in meses)
                  PopupMenuItem<String>(
                    value: key,
                    child: Text(
                      _mesLabel(key),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _mesFiltro == key ? FontWeight.bold : FontWeight.normal,
                        color: _mesFiltro == key ? AppColors.navy : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ];
            },
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
                  const Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      _periodoLabel,
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
    required VoidCallback onVer,
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
                  decoration:
                      BoxDecoration(color: AppColors.searchBg, borderRadius: BorderRadius.circular(10)),
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
                      Text(subtitulo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration:
                      BoxDecoration(color: AppColors.badgeOpGreenBg, borderRadius: BorderRadius.circular(20)),
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
                    onPressed: onVer,
                    icon: const Icon(Icons.visibility_outlined, size: 13, color: Colors.white),
                    label: const Text('Ver', style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDescargar,
                    icon: const Icon(Icons.download_outlined, size: 13),
                    label: const Text('PDF', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorText,
                      side: BorderSide(color: AppColors.errorText.withValues(alpha: 0.4)),
                      backgroundColor: AppColors.errorBg,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportarExcel,
                    icon: const Icon(Icons.table_chart_outlined, size: 13),
                    label: const Text('Excel', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.badgeOpGreenText,
                      side: BorderSide(color: AppColors.badgeOpGreenText.withValues(alpha: 0.4)),
                      backgroundColor: AppColors.badgeOpGreenBg,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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

class _ReportePdfPreviewSheet extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final List<String> headers;
  final List<List<String>> filas;
  final List<int> columnFlex;
  final int? estadoColumnIndex;

  const _ReportePdfPreviewSheet({
    required this.titulo,
    required this.subtitulo,
    required this.headers,
    required this.filas,
    required this.columnFlex,
    this.estadoColumnIndex,
  });

  @override
  State<_ReportePdfPreviewSheet> createState() => _ReportePdfPreviewSheetState();
}

class _ReportePdfPreviewSheetState extends State<_ReportePdfPreviewSheet> {
  // Generado UNA sola vez (en initState, no en build). Antes vivía
  // directo en el `future:` de un FutureBuilder dentro de un
  // StatelessWidget — cada vez que DraggableScrollableSheet reconstruía
  // su contenido (al arrastrar o interactuar con el zoom), se disparaba
  // una generación de PDF nueva, sintiéndose como una recarga al azar.
  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = ReportePdfService.generar(
      titulo: widget.titulo,
      subtitulo: widget.subtitulo,
      headers: widget.headers,
      filas: widget.filas,
      columnFlex: widget.columnFlex,
      estadoColumnIndex: widget.estadoColumnIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Pellizca con dos dedos para ampliar cualquier zona del reporte.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textFaint),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: _bytesFuture,
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

                    return _PdfZoomableView(
                      bytes: snapshot.data!,
                      scrollController: scrollController,
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

/// Renderiza cada página del PDF como una imagen y le da zoom directo
/// con InteractiveViewer — pellizcar para ampliar de inmediato, sin
/// tener que "seleccionar" la página primero (a diferencia de
/// PdfPreview, cuyo comportamiento interno exige un toque previo antes
/// de que el pellizco funcione, y no es algo ajustable desde afuera
/// del paquete).
class _PdfZoomableView extends StatefulWidget {
  final Uint8List bytes;
  final ScrollController scrollController;

  const _PdfZoomableView({
    required this.bytes,
    required this.scrollController,
  });

  @override
  State<_PdfZoomableView> createState() => _PdfZoomableViewState();
}

class _PdfZoomableViewState extends State<_PdfZoomableView> {
  late final Future<List<Uint8List>> _pagesFuture;

  @override
  void initState() {
    super.initState();
    _pagesFuture = _rasterizarPaginas();
  }

  Future<List<Uint8List>> _rasterizarPaginas() async {
    final paginas = <Uint8List>[];
    await for (final pagina in Printing.raster(widget.bytes, dpi: 130)) {
      paginas.add(await pagina.toPng());
    }
    return paginas;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Uint8List>>(
      future: _pagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No se pudo generar la vista previa.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          );
        }

        final paginas = snapshot.data!;

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          itemCount: paginas.length,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (paginas.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Página ${i + 1} de ${paginas.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: AppColors.textFaint),
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: Image.memory(paginas[i]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}