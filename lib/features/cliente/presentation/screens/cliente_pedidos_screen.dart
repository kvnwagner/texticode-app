import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../admin/data/repositories/orden_material_repository.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart' show ErrorState;
import '../../data/services/orden_pdf_service.dart';
import '../widgets/cliente_shared_widgets.dart';

class ClientePedidosScreen extends StatefulWidget {
  final List<Orden> ordenes;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const ClientePedidosScreen({
    super.key,
    required this.ordenes,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<ClientePedidosScreen> createState() => _ClientePedidosScreenState();
}

enum _EstadoFiltro { todos, retrasada, enProceso, completada }

class _ClientePedidosScreenState extends State<ClientePedidosScreen> {
  final _ordenMaterialRepo = OrdenMaterialRepository();

  String _query = '';
  _EstadoFiltro _filter = _EstadoFiltro.todos;

  // Id de la orden actualmente expandida (acordeón: solo una a la vez).
  int? _expandedOrdenId;
  // Id de la orden cuyo PDF se está generando (para el spinner del botón).
  int? _descargandoOrdenId;

  // ── Materiales reales por orden (Id_Orden -> nombres), obtenidos de
  // la tabla intermedia orden_material vía GET /api/orden-material/orden/:id.
  // `orden.materiales` casi siempre llega vacío porque /api/ordenes no
  // incluye ese campo — por eso las cards mostraban "Material: —" aunque
  // la orden sí tuviera materiales asignados.
  final Map<int, List<String>> _materialesPorOrden = {};

  @override
  void initState() {
    super.initState();
    _cargarMaterialesDeOrdenes(widget.ordenes);
  }

  @override
  void didUpdateWidget(covariant ClientePedidosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ordenes != oldWidget.ordenes) {
      _cargarMaterialesDeOrdenes(widget.ordenes);
    }
  }

  /// Trae los materiales reales de cada orden desde orden_material. Si
  /// el backend no puede resolver el nombre en algún registro, cae a un
  /// fallback con el Id_Producto para no dejar la card vacía en silencio.
  Future<void> _cargarMaterialesDeOrdenes(List<Orden> ordenes) async {
    final mapa = <int, List<String>>{};
    for (final o in ordenes) {
      try {
        final materiales = await _ordenMaterialRepo.getMaterialesDeOrden(o.idOrden);
        mapa[o.idOrden] = materiales.map((m) {
          final nombre = m['Nombre_Material'] ??
              m['nombre_material'] ??
              m['Nombre_Producto'] ??
              m['NombreMaterial'];
          final cantidad = m['Cantidad_Usada'] ?? m['cantidad_usada'];
          if (nombre != null) {
            return cantidad != null ? '$nombre ($cantidad)' : '$nombre';
          }
          return 'Material #${m['Id_Producto'] ?? ''}';
        }).where((s) => s.trim().isNotEmpty).toList();
      } catch (_) {
        mapa[o.idOrden] = const [];
      }
      if (mounted) setState(() => _materialesPorOrden.addAll(mapa));
    }
  }

  // ── Stats (antes vivían solo en el dashboard eliminado) ──
  int get _total => widget.ordenes.length;
  int get _enProceso => widget.ordenes.where((o) => o.isEnProceso).length;
  int get _completadas => widget.ordenes.where((o) => o.isCompletada).length;
  int get _retrasadas => widget.ordenes.where((o) => o.isRetrasada).length;

  bool _matchFiltro(Orden o) {
    switch (_filter) {
      case _EstadoFiltro.todos:
        return true;
      case _EstadoFiltro.retrasada:
        return o.isRetrasada;
      case _EstadoFiltro.enProceso:
        return o.isEnProceso;
      case _EstadoFiltro.completada:
        return o.isCompletada;
    }
  }

  String _label(_EstadoFiltro f) {
    switch (f) {
      case _EstadoFiltro.todos:
        return 'Todos';
      case _EstadoFiltro.retrasada:
        return 'En retraso';
      case _EstadoFiltro.enProceso:
        return 'En proceso';
      case _EstadoFiltro.completada:
        return 'Completada';
    }
  }

  Color _color(_EstadoFiltro f) {
    switch (f) {
      case _EstadoFiltro.todos:
        return AppColors.navy;
      case _EstadoFiltro.retrasada:
        return AppColors.errorText;
      case _EstadoFiltro.enProceso:
        return AppColors.purple;
      case _EstadoFiltro.completada:
        return AppColors.iconActive;
    }
  }

  /// Alterna la expansión de una card. Si había otra abierta, se cierra
  /// automáticamente (comportamiento de acordeón: solo una a la vez).
  void _toggleExpanded(int idOrden) {
    setState(() {
      _expandedOrdenId = _expandedOrdenId == idOrden ? null : idOrden;
    });
  }

  Future<void> _descargarPdf(Orden orden) async {
    setState(() => _descargandoOrdenId = orden.idOrden);
    try {
      final bytes = await OrdenPdfService.generar(orden: orden);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'pedido-${orden.codigoOrden.isEmpty ? orden.idOrden : orden.codigoOrden}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el PDF del pedido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _descargandoOrdenId = null);
    }
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 78,
        ),
        itemBuilder: (context, i) {
          final items = [
            (Icons.shopping_bag_outlined, '$_total', 'Total pedidos', AppColors.navy),
            (Icons.autorenew_rounded, '$_enProceso', 'En proceso', AppColors.purple),
            (Icons.check_circle_outline, '$_completadas', 'Completados', AppColors.iconActive),
            (Icons.warning_amber_rounded, '$_retrasadas', 'En retraso', AppColors.errorText),
          ];
          final (icon, value, label, color) = items[i];
          return ClienteStatCard(icon: icon, value: value, label: label, color: color);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.ordenes.where((o) {
      final q = _query.toLowerCase();
      final matchQ = q.isEmpty ||
          o.producto.toLowerCase().contains(q) ||
          o.codigoOrden.toLowerCase().contains(q);
      return matchQ && _matchFiltro(o);
    }).toList();

    return Column(
      children: [
        const ClienteLogoHeader(
          title: 'Mis Pedidos',
          subtitle: 'Seguimiento y estado',
        ),
        // ⬅️ nuevo — stat cards que antes solo estaban en el dashboard eliminado.
        if (!widget.loading && widget.error == null) _buildStats(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.inputText),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _EstadoFiltro.values.map((f) {
              final active = _filter == f;
              final col = _color(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? col : col.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: active ? col : col.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_label(f),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : col)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
              : widget.error != null
                  ? ErrorState(message: widget.error!, onRetry: widget.onRefresh)
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: () async {
                        await widget.onRefresh();
                        await _cargarMaterialesDeOrdenes(widget.ordenes);
                      },
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60),
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off, size: 32, color: AppColors.textFaint),
                                      SizedBox(height: 8),
                                      Text('No se encontraron pedidos',
                                          style: TextStyle(
                                              fontSize: 13, color: AppColors.textFaint)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final orden = filtered[i];
                                final isExpanded = _expandedOrdenId == orden.idOrden;
                                return ClienteOrderCard(
                                  orden: orden,
                                  materiales: _materialesPorOrden[orden.idOrden],
                                  expanded: isExpanded,
                                  onTap: () => _toggleExpanded(orden.idOrden),
                                  onDownloadPdf: () => _descargarPdf(orden),
                                  downloading: _descargandoOrdenId == orden.idOrden,
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}