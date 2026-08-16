import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import 'operario_shared_widgets.dart';
import 'task_card.dart';

enum EstadoFiltro { todos, enProceso, pendiente, retrasada }

enum PrioridadFiltro { todas, alta, media, baja }

/// Pantalla "Tareas Asignadas": lista de tareas activas del operario con
/// búsqueda y filtros de estado/prioridad. No incluye el botón de reportar
/// progreso (esa acción vive en ReportarAvancesView).
class TareasAsignadasView extends StatefulWidget {
  final List<Orden> ordenes;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const TareasAsignadasView({
    super.key,
    required this.ordenes,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<TareasAsignadasView> createState() => _TareasAsignadasViewState();
}

class _TareasAsignadasViewState extends State<TareasAsignadasView> {
  EstadoFiltro _estado = EstadoFiltro.todos;
  PrioridadFiltro _prioridad = PrioridadFiltro.todas;
  String _query = '';

  bool _matchEstado(Orden o) {
    switch (_estado) {
      case EstadoFiltro.todos:
        return true;
      case EstadoFiltro.enProceso:
        return o.isEnProceso;
      case EstadoFiltro.pendiente:
        return o.isPendiente;
      case EstadoFiltro.retrasada:
        return o.isRetrasada;
    }
  }

  bool _matchPrioridad(Orden o) {
    switch (_prioridad) {
      case PrioridadFiltro.todas:
        return true;
      case PrioridadFiltro.alta:
        return o.isAlta;
      case PrioridadFiltro.media:
        return !o.isAlta && !o.isBaja;
      case PrioridadFiltro.baja:
        return o.isBaja;
    }
  }

  bool _matchQuery(Orden o) {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase();
    return o.producto.toLowerCase().contains(q) ||
        o.codigoOrden.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final activas = widget.ordenes.where((o) => !o.isCompletada).toList();
    final filtradas = activas
        .where((o) => _matchEstado(o) && _matchPrioridad(o) && _matchQuery(o))
        .toList();

    final enProceso = activas.where((o) => o.isEnProceso).length;
    final completadas = widget.ordenes.where((o) => o.isCompletada).length;
    final pausadas = activas.where((o) => o.isPendiente).length;

    return Column(
      children: [
        const OperarioHeader(
          title: 'Tareas Asignadas',
          subtitle: 'Gestiona y haz seguimiento a tus ordenes',
        ),
        Expanded(
          child: widget.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.navy))
              : widget.error != null
                  ? ErrorState(
                      message: widget.error!, onRetry: widget.onRefresh)
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: widget.onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                        children: [
                          SearchBox(
                            hint: 'Buscar tareas...',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilterDropdown<EstadoFiltro>(
                                  value: _estado,
                                  items: const {
                                    EstadoFiltro.todos: 'Todos los estados',
                                    EstadoFiltro.enProceso: 'En proceso',
                                    EstadoFiltro.pendiente: 'Pendiente',
                                    EstadoFiltro.retrasada: 'Retrasada',
                                  },
                                  onChanged: (v) =>
                                      setState(() => _estado = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilterDropdown<PrioridadFiltro>(
                                  value: _prioridad,
                                  items: const {
                                    PrioridadFiltro.todas:
                                        'Todas las prioridades',
                                    PrioridadFiltro.alta: 'Alta',
                                    PrioridadFiltro.media: 'Media',
                                    PrioridadFiltro.baja: 'Baja',
                                  },
                                  onChanged: (v) =>
                                      setState(() => _prioridad = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _StatsGrid(
                            enProceso: enProceso,
                            completadas: completadas,
                            pausadas: pausadas,
                            total: widget.ordenes.length,
                          ),
                          const SizedBox(height: 14),
                          SectionTitle(
                            icon: Icons.assignment_outlined,
                            label: 'Mis Tareas',
                            count: filtradas.length,
                            countLabel: 'tareas',
                          ),
                          const SizedBox(height: 8),
                          if (filtradas.isEmpty)
                            EmptyState(
                              label: activas.isEmpty
                                  ? 'No tienes tareas activas'
                                  : 'Ningun resultado con estos filtros',
                            ),
                          ...filtradas.map(
                            (o) => TaskCard(
                              orden: o,
                              showDescription: true,
                              showMateriales: true,
                              showScale: false,
                              // Sin bottomAction: esta vista no reporta progreso.
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int enProceso;
  final int completadas;
  final int pausadas;
  final int total;

  const _StatsGrid({
    required this.enProceso,
    required this.completadas,
    required this.pausadas,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('En Proceso', enProceso, Icons.assignment_outlined,
          AppColors.iconOp),
      _StatItem('Completadas', completadas, Icons.check_circle_outline,
          AppColors.iconActive),
      _StatItem('Pausadas', pausadas, Icons.pause_circle_outline,
          AppColors.iconClient),
      _StatItem('Total', total, Icons.assignment_turned_in_outlined,
          AppColors.navy),
    ];
    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) => _StatCard(item: stats[index]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(width: 3, color: item.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.value}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                          Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 15, color: item.color),
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
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}
