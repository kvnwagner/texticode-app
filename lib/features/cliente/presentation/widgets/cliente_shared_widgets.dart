import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../admin/data/models/orden_model.dart';
import '../../../operario/presentation/screens/operario_shared_widgets.dart'
    show statusColors, priorityColors, StatusBadge, ErrorState;

/// Header con logo — mismo patrón que OperarioHeader / header de Admin.
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

/// Card de pedido — recibe un [Orden] REAL del backend (mismo modelo
/// que usa Admin/Operario). Reutiliza statusColors()/priorityColors().
///
/// Soporta un modo "expandido" tipo acordeón: al tocarla, [onTap] avisa
/// al padre (quien decide cuál card queda expandida — solo una a la
/// vez). Cuando [expanded] es true se muestra información adicional
/// más organizada (materiales completos, descripción completa, fechas
/// detalladas) y aparece el botón "Descargar PDF" ([onDownloadPdf]),
/// que solo se muestra en este estado.
class ClienteOrderCard extends StatelessWidget {
  final Orden orden;
  final bool expanded;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadPdf;
  final bool downloading;

  const ClienteOrderCard({
    super.key,
    required this.orden,
    this.expanded = false,
    this.onTap,
    this.onDownloadPdf,
    this.downloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = statusColors(orden);
    final priority = priorityColors(orden);
    final progressColor = orden.isCompletada ? AppColors.iconActive : AppColors.purple;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expanded ? AppColors.navy.withValues(alpha: 0.35) : AppColors.cardBorder,
            width: expanded ? 1.4 : 1,
          ),
          boxShadow: expanded
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: status.$2),
                Expanded(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(expanded ? 18 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                orden.codigoOrden,
                                style: TextStyle(
                                  fontSize: expanded ? 11 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textFaint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(label: orden.estadoLabel, bg: status.$1, text: status.$2),
                              const SizedBox(width: 6),
                              StatusBadge(
                                  label: orden.prioridadLabel, bg: priority.$1, text: priority.$2),
                              const Spacer(),
                              AnimatedRotation(
                                turns: expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: expanded ? AppColors.navy : AppColors.textFaint),
                              ),
                            ],
                          ),
                          SizedBox(height: expanded ? 12 : 8),
                          Text(
                            orden.producto,
                            maxLines: expanded ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: expanded ? 17 : 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // ── Vista compacta (colapsada) ──
                          if (!expanded && orden.materiales.isNotEmpty) ...[
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

                          // ── Vista expandida: descripción completa ──
                          if (expanded && (orden.descripcion ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              orden.descripcion!,
                              style: const TextStyle(
                                  fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                            ),
                          ],

                          SizedBox(height: expanded ? 16 : 9),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Progreso de fabricación',
                                  style: TextStyle(
                                    fontSize: expanded ? 12 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '${orden.progresoPorcentaje}%',
                                style: TextStyle(
                                  fontSize: expanded ? 13 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: expanded ? 8 : 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: orden.progreso,
                              minHeight: expanded ? 8 : 6,
                              backgroundColor: AppColors.cardBorder,
                              valueColor: AlwaysStoppedAnimation(progressColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [0, 25, 50, 75, 100]
                                .map((m) => Text('$m',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: orden.progresoPorcentaje >= m
                                            ? FontWeight.w800
                                            : FontWeight.w400,
                                        color: orden.progresoPorcentaje >= m
                                            ? progressColor
                                            : AppColors.textFaint)))
                                .toList(),
                          ),

                          // ── Vista expandida: detalle organizado ──
                          if (expanded) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.searchBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailRow(
                                    icon: Icons.numbers_rounded,
                                    label: 'Prendas',
                                    value: '${orden.cantidadActual} / ${orden.cantidadTotal}',
                                  ),
                                  const SizedBox(height: 8),
                                  _DetailRow(
                                    icon: Icons.event_available_outlined,
                                    label: 'Fecha límite',
                                    value: orden.fechaCorta.isEmpty
                                        ? 'Sin fecha'
                                        : orden.fechaCorta,
                                  ),
                                  const SizedBox(height: 8),
                                  _DetailRow(
                                    icon: Icons.layers_outlined,
                                    label: 'Materiales',
                                    value: orden.materiales.isEmpty
                                        ? 'Sin materiales asignados'
                                        : orden.materiales.join(', '),
                                    multiline: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: downloading ? null : onDownloadPdf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: downloading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                label: Text(
                                  downloading ? 'Generando PDF...' : 'Descargar PDF',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ] else ...[
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
                                      orden.materiales.isNotEmpty
                                          ? 'Material: ${orden.materiales.first}'
                                          : 'Material: —',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.navy),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: multiline ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}