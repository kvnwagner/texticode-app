import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/cliente_orders_data.dart';

/// Widgets compartidos de las vistas de Cliente.
/// Unificados 1:1 con los patrones visuales de Admin/Operario:
/// mismos colores (AppColors), mismo estilo de stat card (barra lateral +
/// número grande + icono en caja), mismo estilo de card de contenido
/// (franja de color + badges + barra de progreso con escala), mismo
/// header (sin logout — el logout vive en Perfil).

/// Colores de estado de pedido, mapeados a la MISMA paleta que usa
/// Admin/Operario (ver operario_shared_widgets.dart -> statusColors):
///   En progreso -> purple/purpleBg (igual que "En proceso")
///   Completado  -> iconActive/badgeOpGreenBg (igual que "Completada")
///   Pausado     -> textMuted/searchBg (igual que "Pendiente")
(Color, Color) clienteStatusColors(String status) {
  switch (status) {
    case 'En progreso':
      return (AppColors.statusInProgressBg, AppColors.statusInProgressText);
    case 'Completado':
      return (AppColors.statusCompletedBg, AppColors.statusCompletedText);
    case 'Pausado':
      return (AppColors.statusPendingBg, AppColors.textMuted);
    default:
      return (AppColors.statusPendingBg, AppColors.textMuted);
  }
}

/// Badge de estado — mismo componente visual que StatusBadge de
/// operario_shared_widgets.dart (padding, radio, tipografía idénticos).
class ClienteStatusBadge extends StatelessWidget {
  final String status;
  const ClienteStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = clienteStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}

/// Barra de progreso — mismo radio/altura que la de TaskCard.
class ClienteProgressBar extends StatelessWidget {
  final int pct;
  final Color color;
  const ClienteProgressBar({super.key, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: pct / 100,
        minHeight: 6,
        backgroundColor: AppColors.cardBorder,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Header de sección — mismo patrón que _buildSectionHeader de
/// admin_home_screen.dart (título + circulo navy con contador).
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

/// Header con logo — EXACTAMENTE el mismo patrón visual que el header de
/// admin_home_screen.dart / operario_shared_widgets.dart (OperarioHeader):
/// fondo blanco, borde inferior, logo cuadrado 38x38 con esquinas
/// redondeadas, título + subtítulo. SIN botón de logout — ahora vive
/// únicamente en ClientePerfilScreen, igual que en Admin/Operario.
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

/// Stat card — EXACTAMENTE el mismo diseño que _buildStatCard de
/// admin_home_screen.dart / produccion_screen.dart / inventario_screen.dart:
/// barra lateral de color de 3.5px, número grande + label debajo a la
/// izquierda, icono en caja redondeada a la derecha.
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

/// Card de pedido — EXACTAMENTE el mismo diseño que TaskCard
/// (operario/presentation/screens/task_card.dart): franja de color
/// lateral de 3px según estado, código pequeño en gris, badge de estado,
/// título en bold, fila de metadata, barra de progreso con escala
/// 0-25-50-75-100 debajo.
class ClienteOrderCard extends StatelessWidget {
  final ClienteOrder order;
  const ClienteOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeText) = clienteStatusColors(order.status);
    final progressColor = order.status == 'Completado'
        ? AppColors.iconActive
        : (order.status == 'Pausado' ? AppColors.textFaint : AppColors.purple);
    const scaleMarks = [0, 25, 50, 75, 100];

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
              Container(width: 3, color: badgeText),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClienteStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Progreso de fabricación',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '${order.pct}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClienteProgressBar(pct: order.pct, color: progressColor),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: scaleMarks
                            .map((m) => Text('$m',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight:
                                        order.pct >= m ? FontWeight.w800 : FontWeight.w400,
                                    color: order.pct >= m
                                        ? progressColor
                                        : AppColors.textFaint)))
                            .toList(),
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
                                'Material: ${order.material}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              'Entrega: ${order.delivery}',
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