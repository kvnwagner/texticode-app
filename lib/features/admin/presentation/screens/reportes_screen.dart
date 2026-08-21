import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/material_repository.dart';

const _tiposFiltro = ['Todos los tipos', 'Pedidos', 'Eficiencia', 'Inventario'];

/// Pantalla "Reportes" — sigue los mismos tokens visuales del resto del
/// panel admin. Los 4 KPI se calculan en tiempo real a partir de las
/// órdenes reales (OrdenRepository). Los botones "Descargar" y
/// "Exportar Excel" generan un PDF/CSV real con los datos actuales
/// (no hay backend de reportes todavía, así que la generación ocurre
/// en el dispositivo, igual que el comprobante de entrega).
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _ordenRepo = OrdenRepository();
  final _materialRepo = MaterialRepository();

  List<Orden> _ordenes = [];
  List<MaterialItem> _materiales = [];
  bool _loading = true;
  String? _error;
  String _filtro = 'Todos los tipos';
  bool _showFilterDrop = false;
  bool _exportando = false;

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
  int get _pendientes => _ordenes.where((o) => o.estado == 'Pendiente').length;
  double get _tasaCompletacion => _total == 0 ? 0 : (_completados / _total) * 100;

  bool _visible(String tipo) => _filtro == 'Todos los tipos' || _filtro == tipo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildFilterButton(),
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
                                  subtitulo: _total == 0
                                      ? 'Sin órdenes registradas'
                                      : '$_total órdenes registradas',
                                  onDescargar: () => _descargarPdfPedidos(),
                                  onExportarExcel: () => _exportarCsvPedidos(),
                                ),
                                if (_visible('Eficiencia')) _buildReportCard(
                                  icon: Icons.bar_chart_rounded,
                                  titulo: 'Reporte de Eficiencia Operaria',
                                  subtitulo: _total == 0
                                      ? 'Sin datos de operarios'
                                      : '${_ordenes.map((o) => o.operario).toSet().length} operarios con órdenes asignadas',
                                  onDescargar: () => _descargarPdfEficiencia(),
                                  onExportarExcel: () => _exportarCsvEficiencia(),
                                ),
                                if (_visible('Inventario')) _buildReportCard(
                                  icon: Icons.table_chart_outlined,
                                  titulo: 'Reporte de Inventario',
                                  subtitulo: _materiales.isEmpty
                                      ? 'Sin materiales registrados'
                                      : '${_materiales.length} materiales en inventario',
                                  onDescargar: () => _descargarPdfInventario(),
                                  onExportarExcel: () => _exportarCsvInventario(),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
          // Barrera invisible: al abrir el menú, tocar afuera lo cierra.
          if (_showFilterDrop)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _showFilterDrop = false),
              ),
            ),
          // El menú se agrega AL FINAL del Stack de toda la pantalla,
          // así siempre se pinta por encima de las tarjetas de abajo
          // (antes vivía dentro del ListView y las tarjetas siguientes
          // lo tapaban aunque estuviera "encima" visualmente).
          if (_showFilterDrop)
            Positioned(
              top: 106,
              left: 16,
              child: _buildFilterDropdownMenu(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF2D5478)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reportes',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Análisis y estadísticas',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => setState(() => _showFilterDrop = !_showFilterDrop),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(_filtro,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Icon(_showFilterDrop ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdownMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _tiposFiltro.map((t) {
            final selected = t == _filtro;
            return GestureDetector(
              onTap: () => setState(() {
                _filtro = t;
                _showFilterDrop = false;
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy.withValues(alpha: 0.06) : null,
                  border: t != _tiposFiltro.last
                      ? const Border(bottom: BorderSide(color: AppColors.cardBorder))
                      : null,
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? AppColors.navy : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKpis() {
    final items = [
      ('Pedidos Totales', '$_total', AppColors.navy),
      ('Completados', '$_completados', AppColors.iconActive),
      ('Tasa Completación', '${_tasaCompletacion.toStringAsFixed(1)}%', AppColors.purple),
      ('Pendientes', '$_pendientes', AppColors.iconClient),
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
          mainAxisExtent: 84,
        ),
        itemBuilder: (context, i) {
          final (label, value, color) = items[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    final count = [
      if (_visible('Pedidos')) 1,
      if (_visible('Eficiencia')) 1,
      if (_visible('Inventario')) 1,
    ].length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Reportes Disponibles',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: const Text('Descargar', style: TextStyle(fontSize: 11)),
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

  // ══════════════════════════════════════════════════════════════════════
  // EXPORTACIÓN REAL — genera PDF/CSV con los datos reales cargados.
  // No hay backend de reportes: el archivo se arma en el dispositivo,
  // igual que ya haces con el comprobante de entrega en clientes_screen.
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _runExport(Future<void> Function() task) async {
    setState(() => _exportando = true);
    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el reporte: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _descargarPdfPedidos() => _runExport(() async {
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Text('Reporte de Pedidos', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Código', 'Producto', 'Cliente', 'Operario', 'Estado', 'Progreso'],
                data: _ordenes
                    .map((o) => [
                          o.codigoOrden,
                          o.producto,
                          o.cliente,
                          o.operario,
                          o.estadoLabel,
                          '${o.progresoPorcentaje}%',
                        ])
                    .toList(),
              ),
            ],
          ),
        );
        await Printing.layoutPdf(onLayout: (_) => doc.save());
      });

  Future<void> _exportarCsvPedidos() => _runExport(() async {
        final buffer = StringBuffer('Codigo,Producto,Cliente,Operario,Estado,Progreso\n');
        for (final o in _ordenes) {
          buffer.writeln(
              '${o.codigoOrden},${_csvSafe(o.producto)},${_csvSafe(o.cliente)},${_csvSafe(o.operario)},${o.estadoLabel},${o.progresoPorcentaje}%');
        }
        await _compartirCsv(buffer.toString(), 'reporte_pedidos.csv');
      });

  Future<void> _descargarPdfEficiencia() => _runExport(() async {
        final porOperario = <String, List<Orden>>{};
        for (final o in _ordenes) {
          porOperario.putIfAbsent(o.operario, () => []).add(o);
        }
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Text('Reporte de Eficiencia Operaria',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Operario', 'Órdenes Asignadas', 'Completadas', '% Completación'],
                data: porOperario.entries.map((e) {
                  final totalOp = e.value.length;
                  final compOp = e.value.where((o) => o.isCompletada).length;
                  final pct = totalOp == 0 ? 0 : ((compOp / totalOp) * 100).round();
                  return [e.key, '$totalOp', '$compOp', '$pct%'];
                }).toList(),
              ),
            ],
          ),
        );
        await Printing.layoutPdf(onLayout: (_) => doc.save());
      });

  Future<void> _exportarCsvEficiencia() => _runExport(() async {
        final porOperario = <String, List<Orden>>{};
        for (final o in _ordenes) {
          porOperario.putIfAbsent(o.operario, () => []).add(o);
        }
        final buffer = StringBuffer('Operario,OrdenesAsignadas,Completadas,PorcentajeCompletacion\n');
        for (final e in porOperario.entries) {
          final totalOp = e.value.length;
          final compOp = e.value.where((o) => o.isCompletada).length;
          final pct = totalOp == 0 ? 0 : ((compOp / totalOp) * 100).round();
          buffer.writeln('${_csvSafe(e.key)},$totalOp,$compOp,$pct%');
        }
        await _compartirCsv(buffer.toString(), 'reporte_eficiencia.csv');
      });

  Future<void> _descargarPdfInventario() => _runExport(() async {
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Text('Reporte de Inventario', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Material', 'Categoría', 'Stock', 'Mínimo', 'Máximo'],
                data: _materiales
                    .map((m) => [
                          m.nombre,
                          m.categoria,
                          '${m.stockActual} ${m.unidad}',
                          '${m.stockMinimo}',
                          '${m.stockMaximo}',
                        ])
                    .toList(),
              ),
            ],
          ),
        );
        await Printing.layoutPdf(onLayout: (_) => doc.save());
      });

  Future<void> _exportarCsvInventario() => _runExport(() async {
        final buffer = StringBuffer('Material,Categoria,Stock,Unidad,Minimo,Maximo\n');
        for (final m in _materiales) {
          buffer.writeln(
              '${_csvSafe(m.nombre)},${m.categoria},${m.stockActual},${m.unidad},${m.stockMinimo},${m.stockMaximo}');
        }
        await _compartirCsv(buffer.toString(), 'reporte_inventario.csv');
      });

  String _csvSafe(String v) => '"${v.replaceAll('"', '""')}"';

  Future<void> _compartirCsv(String contenido, String nombreArchivo) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombreArchivo');
    await file.writeAsString(contenido);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Texticode');
  }
}