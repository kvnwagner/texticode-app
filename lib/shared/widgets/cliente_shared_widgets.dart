import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart'
    show statusColors, priorityColors, StatusBadge, ErrorState;

/// Widgets compartidos de las vistas de Cliente.
/// Reutilizan directamente los mismos helpers de color y el mismo
/// modelo Orden que usan Admin/Operario — cero paleta/estado duplicado.

/// Header con logo — mismo patrón que OperarioHeader / header de Admin.
/// Sin botón de logout (vive en ClientePerfilScreen).
class ClienteLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ClienteLogoHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
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
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.checkroom, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header de sección — mismo patrón que _buildSectionHeader de Admin.
class ClienteSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const ClienteSectionHeader({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration:
                  BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat card — mismo diseño que _buildStatCard de Admin/Operario.
class ClienteStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const ClienteStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            Container(width: 3.5, color: color),
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
                          Text(value,
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(height: 3),
                          Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 15, color: color),
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

/// Card de pedido — recibe un [Orden] REAL (el mismo modelo que usa
/// Admin/Operario) y se ve EXACTAMENTE igual que TaskCard: franja lateral
/// de color por estado, badges de estado y prioridad, título, materiales,
/// barra de progreso con escala 0-25-50-75-100, y footer con operario
/// asignado + fecha de entrega.
class ClienteOrderCard extends StatelessWidget {
  final Orden orden;
  const ClienteOrderCard({super.key, required this.orden});

  @override
  Widget build(BuildContext context) {
    final status = statusColors(orden);
    final priority = priorityColors(orden);
    final progressColor = orden.isCompletada ? AppColors.iconActive : AppColors.purple;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: status.$2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                          StatusBadge(label: orden.estadoLabel, bg: status.$1, text: status.$2),
                          const SizedBox(width: 6),
                          StatusBadge(
                              label: orden.prioridadLabel, bg: priority.$1, text: priority.$2),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        orden.producto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (orden.materiales.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: orden.materiales
                              .take(3)
                              .map((m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.searchBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Text(m,
                                        style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 9),
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
                          Text(
                            '${orden.progresoPorcentaje}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: orden.progreso,
                          minHeight: 6,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScaleMark(0),
                          _ScaleMark(25),
                          _ScaleMark(50),
                          _ScaleMark(75),
                          _ScaleMark(100),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.cardBorder)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                orden.operario.isEmpty
                                    ? 'Operario sin asignar'
                                    : 'Operario: ${orden.operario}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              orden.fechaCorta.isEmpty
                                  ? 'Sin fecha'
                                  : 'Entrega: ${orden.fechaCorta}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleMark extends StatelessWidget {
  final int value;
  const _ScaleMark(this.value);

  @override
  Widget build(BuildContext context) {
    return Text('$value',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textFaint));
  }
}