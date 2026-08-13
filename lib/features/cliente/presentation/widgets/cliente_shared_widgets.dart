import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

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

class ClienteDashHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? badge;
  const ClienteDashHeader({super.key, required this.title, this.subtitle, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('KA',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (badge != null) ...[const SizedBox(width: 8), badge!],
                  ],
                ),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header estilo "Gestión de Usuarios": logo + título + subtítulo + logout.
/// Se usa solo en Pedidos y Soporte de Cliente.
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}