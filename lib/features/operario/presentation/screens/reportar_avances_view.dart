import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import 'operario_shared_widgets.dart';
import 'task_card.dart';

/// Pantalla "Reportar Avances": tabs de Ordenes Activas / Historial, con
/// acciones de Reportar progreso y Pausar por cada orden activa.
class ReportarAvancesView extends StatefulWidget {
  final List<Orden> ordenes;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<Orden> onReport;
  final ValueChanged<Orden> onPause;

  const ReportarAvancesView({
    super.key,
    required this.ordenes,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onReport,
    required this.onPause,
  });

  @override
  State<ReportarAvancesView> createState() => _ReportarAvancesViewState();
}

class _ReportarAvancesViewState extends State<ReportarAvancesView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activas = widget.ordenes.where((o) => !o.isCompletada).toList();
    final historial = widget.ordenes.where((o) => o.isCompletada).toList();
    final selectedList = _tabIndex == 0 ? activas : historial;

    return Column(
      children: [
        const OperarioHeader(
          title: 'Reportar Avances',
          subtitle: 'Actualiza el progreso de tus ordenes asignadas',
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
                          _SegmentedTabs(
                            selectedIndex: _tabIndex,
                            activeCount: activas.length,
                            historyCount: historial.length,
                            onChanged: (i) => setState(() => _tabIndex = i),
                          ),
                          const SizedBox(height: 12),
                          if (selectedList.isEmpty)
                            EmptyState(
                              label: _tabIndex == 0
                                  ? 'No tienes ordenes activas'
                                  : 'No hay reportes en historial',
                            ),
                          ...selectedList.map(
                            (o) => _tabIndex == 0
                                ? TaskCard(
                                    orden: o,
                                    topRightAction: PauseButton(
                                      onPressed: () => widget.onPause(o),
                                    ),
                                    bottomAction: ReportButton(
                                      onPressed: () => widget.onReport(o),
                                    ),
                                  )
                                : _HistoryCard(orden: o),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final int activeCount;
  final int historyCount;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.selectedIndex,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _TabPill(
            selected: selectedIndex == 0,
            label: 'Ordenes Activas',
            count: activeCount,
            onTap: () => onChanged(0),
          ),
          _TabPill(
            selected: selectedIndex == 1,
            label: 'Historial',
            count: historyCount,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final bool selected;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _TabPill({
    required this.selected,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _TinyBadge(value: count, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final int value;
  final bool selected;

  const _TinyBadge({required this.value, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.cardBorder,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Orden orden;

  const _HistoryCard({required this.orden});

  @override
  Widget build(BuildContext context) {
    final priority = priorityColors(orden);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                orden.codigoOrden,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textFaint,
                ),
              ),
              const SizedBox(width: 8),
              const StatusBadge(
                label: 'Completado',
                bg: AppColors.statusCompletedBg,
                text: AppColors.statusCompletedText,
              ),
              const SizedBox(width: 6),
              StatusBadge(
                  label: orden.prioridadLabel,
                  bg: priority.$1,
                  text: priority.$2),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            orden.producto,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prendas: ${orden.cantidadActual}/${orden.cantidadTotal}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Text(
                '100%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.iconActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation(AppColors.iconActive),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Reportes enviados',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _TimelineRow(
            date: orden.fechaCorta.isEmpty
                ? 'Fecha no disponible'
                : orden.fechaCorta,
            percent: '100%',
            text: 'Produccion finalizada y guardada en la base de datos.',
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String date;
  final String percent;
  final String text;

  const _TimelineRow({
    required this.date,
    required this.percent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            color: AppColors.iconActive,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    percent,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iconActive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet para reportar el avance de una orden. Se abre desde
/// [OperarioHomeScreen] (necesita `Navigator`/`ScaffoldMessenger` del árbol
/// de la screen padre).
///
/// Sigue la misma estructura del prototipo web: resumen de
/// prendas hechas / progreso actual / restantes, seguido del campo
/// "Unidades completadas en esta sesión" (incremental — NO es el total
/// acumulado, es lo que el operario avanzó ahora) y una nota opcional.
class ReportProgressSheet extends StatefulWidget {
  final Orden orden;

  /// [unidadesSesion] son las unidades avanzadas EN ESTA SESIÓN (se
  /// suman al avance ya registrado). [nota] es el comentario opcional.
  final Future<void> Function(int unidadesSesion, String? nota) onSubmit;

  const ReportProgressSheet({
    super.key,
    required this.orden,
    required this.onSubmit,
  });

  @override
  State<ReportProgressSheet> createState() => _ReportProgressSheetState();
}

class _ReportProgressSheetState extends State<ReportProgressSheet> {
  final _unidadesController = TextEditingController(text: '0');
  final _notaController = TextEditingController();
  bool _saving = false;
  String? _error;

  int get _restantes =>
      (widget.orden.cantidadTotal - widget.orden.cantidadActual)
          .clamp(0, widget.orden.cantidadTotal);

  @override
  void dispose() {
    _unidadesController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final unidades = int.tryParse(_unidadesController.text.trim());
    if (unidades == null || unidades <= 0) {
      setState(() => _error = 'Ingresa una cantidad mayor a 0.');
      return;
    }
    if (unidades > _restantes) {
      setState(() => _error =
          'No puedes reportar más de las $_restantes prendas que quedan.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        unidades,
        _notaController.text.trim().isEmpty
            ? null
            : _notaController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avance reportado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final orden = widget.orden;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reportar Progreso',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${orden.codigoOrden} — ${orden.producto}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textFaint),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textFaint,
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // ── Resumen: prendas hechas / progreso / quedan ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'PRENDAS HECHAS',
                        value:
                            '${orden.cantidadActual} / ${orden.cantidadTotal}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'PROGRESO ACTUAL',
                        value: '${orden.progresoPorcentaje}%',
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'QUEDAN',
                        value: '$_restantes',
                        valueColor: AppColors.errorText,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _InputLabel('Unidades completadas en esta sesión *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _unidadesController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('0'),
                    ),
                    const SizedBox(height: 14),
                    const _InputLabel('Nota (opcional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notaController,
                      minLines: 3,
                      maxLines: 3,
                      decoration: _inputDecoration('Describe el avance...'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.errorText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(
                                    color: AppColors.cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.send_rounded, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Enviar Reporte',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textFaint),
      filled: true,
      fillColor: AppColors.searchBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.textFaint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;

  const _InputLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}