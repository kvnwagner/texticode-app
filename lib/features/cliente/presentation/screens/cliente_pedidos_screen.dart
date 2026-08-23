import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart' show ErrorState;
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

enum _EstadoFiltro { todos, pendiente, enProceso, completada, retrasada }

class _ClientePedidosScreenState extends State<ClientePedidosScreen> {
  String _query = '';
  _EstadoFiltro _filter = _EstadoFiltro.todos;

  bool _matchFiltro(Orden o) {
    switch (_filter) {
      case _EstadoFiltro.todos:
        return true;
      case _EstadoFiltro.pendiente:
        return o.isPendiente;
      case _EstadoFiltro.enProceso:
        return o.isEnProceso;
      case _EstadoFiltro.completada:
        return o.isCompletada;
      case _EstadoFiltro.retrasada:
        return o.isRetrasada;
    }
  }

  String _label(_EstadoFiltro f) {
    switch (f) {
      case _EstadoFiltro.todos:
        return 'Todos';
      case _EstadoFiltro.pendiente:
        return 'Pendiente';
      case _EstadoFiltro.enProceso:
        return 'En proceso';
      case _EstadoFiltro.completada:
        return 'Completada';
      case _EstadoFiltro.retrasada:
        return 'Retrasada';
    }
  }

  Color _color(_EstadoFiltro f) {
    switch (f) {
      case _EstadoFiltro.todos:
        return AppColors.navy;
      case _EstadoFiltro.pendiente:
        return AppColors.textMuted;
      case _EstadoFiltro.enProceso:
        return AppColors.purple;
      case _EstadoFiltro.completada:
        return AppColors.iconActive;
      case _EstadoFiltro.retrasada:
        return AppColors.errorText;
    }
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      onRefresh: widget.onRefresh,
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
                              itemBuilder: (context, i) =>
                                  ClienteOrderCard(orden: filtered[i]),
                            ),
                    ),
        ),
      ],
    );
  }
}