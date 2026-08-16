import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';

/// Header reutilizado por ambas vistas (Tareas Asignadas / Reportar Avances).
class OperarioHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const OperarioHeader({
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
                  child: const Icon(Icons.checkroom,
                      color: Colors.white, size: 18),
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchBox({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              const Icon(Icons.search, size: 16, color: AppColors.textFaint),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.searchBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

/// Dropdown de filtro genérico (reemplaza al antiguo `_FilterPill` decorativo).
class FilterDropdown<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.textFaint),
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String countLabel;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.searchBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count $countLabel',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }
}

class ScaleStyle extends TextStyle {
  const ScaleStyle()
      : super(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textFaint,
        );
}

class EmptyState extends StatelessWidget {
  final String label;

  const EmptyState({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined,
              size: 34, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colores de badge según prioridad de la orden.
(Color, Color) priorityColors(Orden o) {
  if (o.isAlta) return (AppColors.priorityHighBg, AppColors.priorityHighText);
  if (o.isBaja) return (AppColors.statusPendingBg, AppColors.textMuted);
  return (AppColors.priorityMediumBg, AppColors.priorityMediumText);
}

/// Colores de badge/franja según estado de la orden.
(Color, Color) statusColors(Orden o) {
  if (o.isCompletada) {
    return (AppColors.statusCompletedBg, AppColors.statusCompletedText);
  }
  if (o.isEnProceso) {
    return (AppColors.statusInProgressBg, AppColors.statusInProgressText);
  }
  if (o.isRetrasada) {
    return (AppColors.statusDelayedBg, AppColors.statusDelayedText);
  }
  return (AppColors.statusPendingBg, AppColors.statusPendingText);
}