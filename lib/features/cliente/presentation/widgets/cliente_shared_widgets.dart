import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/cliente_orders_data.dart';

/// Colores auxiliares específicos de las vistas de cliente
/// (no están en AppColors para no tocar el archivo global).
class ClienteColors {
  ClienteColors._();

  static const statusInProgress = Color(0xFF2563EB);
  static const statusInProgressBg = Color(0xFFE0ECFF);
  static const statusDone = Color(0xFF16A34A);
  static const statusDoneBg = Color(0xFFDCFCE7);
  static const statusPaused = Color(0xFF6B7280);
  static const statusPausedBg = Color(0xFFF3F4F6);

  static const profileGradient = [
    Color(0xFF111827),
    Color(0xFF1F3A52),
    Color(0xFF0F2236),
  ];

  static const logoutBorder = Color(0xFFFECACA);
  static const logoutText = Color(0xFFDC2626);
  static const logoutBg = Color(0xFFFEF2F2);
}

class ClienteStatusBadge extends StatelessWidget {
  final String status;
  const ClienteStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, text;
    switch (status) {
      case 'En progreso':
        bg = ClienteColors.statusInProgressBg;
        text = ClienteColors.statusInProgress;
        break;
      case 'Completado':
        bg = ClienteColors.statusDoneBg;
        text = ClienteColors.statusDone;
        break;
      case 'Pausado':
        bg = ClienteColors.statusPausedBg;
        text = ClienteColors.statusPaused;
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}

class ClienteProgressBar extends StatelessWidget {
  final int pct;
  final Color color;
  const ClienteProgressBar({super.key, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct / 100,
        minHeight: 6,
        backgroundColor: AppColors.inputBorder,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class ClienteSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const ClienteSectionHeader({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(999)),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header estilo "Gestión de Usuarios": logo + título + subtítulo + logout.
/// Se usa en Comprobantes, Pedidos y Soporte de Cliente.
class ClienteLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onLogout;

  const ClienteLogoHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppConstants.logoAssetPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.checkroom, size: 18, color: AppColors.navy),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorBorder),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout, size: 16, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de pedido con barra de color lateral + badges + progreso,

class ClienteOrderCard extends StatelessWidget {
  final ClienteOrder order;
  const ClienteOrderCard({super.key, required this.order});

  Color _statusColor() {
    switch (order.status) {
      case 'En progreso':
        return ClienteColors.statusInProgress;
      case 'Completado':
        return ClienteColors.statusDone;
      case 'Pausado':
        return ClienteColors.statusPaused;
      default:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    const scaleMarks = [0, 25, 50, 75, 100];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClienteStatusBadge(status: order.status),
                        const Spacer(),
                        Text(order.id,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFaint)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progreso de fabricación',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        Text('${order.pct}%',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClienteProgressBar(pct: order.pct, color: color),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: scaleMarks
                          .map((m) => Text('$m',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      order.pct >= m ? FontWeight.w800 : FontWeight.w400,
                                  color: order.pct >= m ? color : AppColors.textFaint)))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _metaCol('MATERIAL', order.material)),
                          Expanded(child: _metaCol('ENTREGA ESTIMADA', order.delivery)),
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
    );
  }

  Widget _metaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textFaint)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}