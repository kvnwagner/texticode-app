import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_operario_model.dart';
import 'operario_shared_widgets.dart';
import 'task_card.dart';

enum EstadoFiltro { todos, enProceso, pendiente, completada, retrasada }

enum PrioridadFiltro { todas, alta, media, baja }

/// Pantalla "Tareas Asignadas": lista de TODAS las tareas del operario
/// (en proceso, pendientes/pausadas, completadas y retrasadas), con
/// búsqueda y filtros de estado/prioridad. No incluye el botón de
/// reportar progreso (esa acción vive en ReportarAvancesView).
class TareasAsignadasView extends StatefulWidget {
  final List<OrdenOperario> fases;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const TareasAsignadasView({
    super.key,
    required this.fases,
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

  bool _matchEstado(OrdenOperario fase) {
    switch (_estado) {
      case EstadoFiltro.todos:
        return true;
      case EstadoFiltro.enProceso:
        return fase.isEnProceso;
      case EstadoFiltro.pendiente:
        return fase.isPendiente;
      case EstadoFiltro.completada:
        return fase.isCompletada;
      case EstadoFiltro.retrasada:
        return fase.isRetrasada;
    }
  }

  bool _matchPrioridad(OrdenOperario fase) {
    switch (_prioridad) {
      case PrioridadFiltro.todas:
        return true;
      case PrioridadFiltro.alta:
        return fase.isAlta;
      case PrioridadFiltro.media:
        return !fase.isAlta && !fase.isBaja;
      case PrioridadFiltro.baja:
        return fase.isBaja;
    }
  }

  bool _matchQuery(OrdenOperario fase) {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase();
    return (fase.producto ?? '').toLowerCase().contains(q) ||
        fase.codigoOrden.toLowerCase().contains(q) ||
        fase.descripcionFase.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    // Ya NO se excluyen las completadas: esta vista debe mostrar TODAS
    // las tareas asignadas al operario (en proceso, pendientes,
    // completadas y retrasadas). El filtro de estado es lo que decide
    // qué subconjunto ver, no un recorte fijo por defecto.
    final todas = widget.fases;
    final filtradas = todas
        .where((o) => _matchEstado(o) && _matchPrioridad(o) && _matchQuery(o))
        .toList();

    final enProceso = todas.where((o) => o.isEnProceso).length;
    final completadas = todas.where((o) => o.isCompletada).length;
    final retrasadas = todas.where((o) => o.isRetrasada).length;

    return Column(
      children: [
        const OperarioHeader(
          title: 'Tareas Asignadas',
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
                                    EstadoFiltro.completada: 'Completada',
                                    EstadoFiltro.retrasada: 'Retrasada',
                                  },
                                  onChanged: (v) => setState(() => _estado = v),
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
                            retrasadas: retrasadas,
                            total: todas.length,
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
                              label: todas.isEmpty
                                  ? 'No tienes tareas asignadas'
                                  : 'Ningun resultado con estos filtros',
                            ),
                          ...filtradas.map(
                            (fase) => FaseTaskCard(
                              fase: fase,
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
  final int retrasadas;
  final int total;

  const _StatsGrid({
    required this.enProceso,
    required this.completadas,
    required this.retrasadas,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
          'En Proceso', enProceso, Icons.assignment_outlined, AppColors.iconOp),
      _StatItem('Completadas', completadas, Icons.check_circle_outline,
          AppColors.iconActive),
      _StatItem('Retrasadas', retrasadas, Icons.warning_amber_rounded,
          AppColors.errorText),
      _StatItem(
          'Total', total, Icons.assignment_turned_in_outlined, AppColors.navy),
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
