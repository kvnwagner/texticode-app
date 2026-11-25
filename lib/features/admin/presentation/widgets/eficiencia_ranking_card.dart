import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/eficiencia_operario_model.dart';

/// Card de ranking, equivalente a una fila de la tabla web
/// ("Ranking de Operarios") pero pensada para mobile.
class EficienciaRankingCard extends StatelessWidget {
  final EficienciaOperario operario;
  final int rank;
  final double maxPrendasPorDia;
  final VoidCallback onVerDetalle;

  const EficienciaRankingCard({
    super.key,
    required this.operario,
    required this.rank,
    required this.maxPrendasPorDia,
    required this.onVerDetalle,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFF92400E);
    if (rank == 2) return const Color(0xFF475569);
    if (rank == 3) return const Color(0xFF9A3412);
    return AppColors.textMuted;
  }

  Color get _rankBg {
    if (rank == 1) return const Color(0xFFFEF3C7);
    if (rank == 2) return const Color(0xFFF1F5F9);
    if (rank == 3) return const Color(0xFFFDE8D4);
    return AppColors.searchBg;
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final av = AppColors.avatarPalette[operario.idUsuario % AppColors.avatarPalette.length];
    final barPct =
        maxPrendasPorDia <= 0 ? 0.0 : (operario.prendasPorDia / maxPrendasPorDia).clamp(0, 1).toDouble();
    final color = eficienciaRendimientoColor(operario.rendimiento);

    return GestureDetector(
      onTap: onVerDetalle,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _rankBg, shape: BoxShape.circle),
                  child: Text('$rank',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _rankColor)),
                ),
                const SizedBox(width: 10),
                AvatarWidget(initials: operario.initials, size: 38, bg: av['bg']!, text: av['text']!),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(operario.nombreCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('@${operario.nombreUsuario}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: eficienciaRendimientoBg(operario.rendimiento),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(operario.rendimiento,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Prendas / día',
                    style:
                        TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(_fmt(operario.prendasPorDia),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: barPct,
                minHeight: 5,
                backgroundColor: AppColors.inputBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _MiniMetric(
                        label: 'Producidas',
                        value: '${operario.totalUnidadesProducidas}',
                        color: AppColors.navy)),
                _divider(),
                Expanded(
                  child: _MiniMetric(
                    label: 'En retraso',
                    value: '${operario.ordenesEnRetraso}',
                    color: operario.ordenesEnRetraso > 0 ? AppColors.errorText : AppColors.textMuted,
                  ),
                ),
                _divider(),
                Expanded(
                    child: _MiniMetric(
                        label: 'Completadas',
                        value: '${operario.ordenesCompletadas}',
                        color: AppColors.iconActive)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: AppColors.cardBorder, margin: const EdgeInsets.symmetric(horizontal: 6));
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textFaint)),
      ],
    );
  }
}