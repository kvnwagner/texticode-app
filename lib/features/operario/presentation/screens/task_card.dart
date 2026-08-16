import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/data/models/orden_model.dart';
import 'operario_shared_widgets.dart';

/// Card de una orden/tarea. Usada tanto en "Tareas Asignadas" (compact, sin
/// acciones) como en "Reportar Avances" (completa, con botón Reportar y
/// opcionalmente Pausar).
///
/// El slot [actions] reemplaza los antiguos flags booleanos: cada vista
/// decide qué acciones mostrar (o ninguna) sin que la card conozca los
/// "modos" de pantalla.
class TaskCard extends StatelessWidget {
  final Orden orden;
  final bool showDescription;
  final bool showMateriales;
  final bool showScale;

  /// Acción mostrada arriba a la derecha, junto a los badges (p. ej. Pausar).
  final Widget? topRightAction;

  /// Acción de ancho completo mostrada al final de la card (p. ej. Reportar).
  final Widget? bottomAction;

  const TaskCard({
    super.key,
    required this.orden,
    this.showDescription = false,
    this.showMateriales = false,
    this.showScale = true,
    this.topRightAction,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = statusColors(orden);
    final priority = priorityColors(orden);
    final progressColor =
        orden.isCompletada ? AppColors.iconActive : AppColors.purple;
    final stripeColor = status.$2;

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
              Container(width: 3, color: stripeColor),
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
                          StatusBadge(
                              label: orden.estadoLabel,
                              bg: status.$1,
                              text: status.$2),
                          const SizedBox(width: 6),
                          StatusBadge(
                              label: orden.prioridadLabel,
                              bg: priority.$1,
                              text: priority.$2),
                          if (topRightAction != null) ...[
                            const Spacer(),
                            topRightAction!,
                          ],
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
                      if (showDescription &&
                          (orden.descripcion ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          orden.descripcion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
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
                            'Vence: ${orden.fechaCorta}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.errorText,
                            ),
                          ),
                        ],
                      ),
                      if (showMateriales && orden.materiales.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: orden.materiales
                              .take(2)
                              .map(
                                (m) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.layers_outlined,
                                        size: 12, color: AppColors.textFaint),
                                    const SizedBox(width: 4),
                                    Text(
                                      m,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Progreso de fabricacion',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            '${orden.progresoPorcentaje}%',
                            style: TextStyle(
                              fontSize: 10,
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
                      if (showScale) ...[
                        const SizedBox(height: 7),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0', style: ScaleStyle()),
                            Text('25', style: ScaleStyle()),
                            Text('50', style: ScaleStyle()),
                            Text('75', style: ScaleStyle()),
                            Text('100', style: ScaleStyle()),
                          ],
                        ),
                      ],
                      if (bottomAction != null) ...[
                        const SizedBox(height: 12),
                        bottomAction!,
                      ],
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

/// Botón "+ Reportar Progreso" listo para pasar como `actions` a [TaskCard].
class ReportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.trending_up_rounded, size: 15),
        label: const Text(
          '+ Reportar Progreso',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Botón "Pausar" listo para pasar dentro de un `Row` de acciones.
class PauseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PauseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.iconClient),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause, size: 11, color: AppColors.iconClient),
            SizedBox(width: 4),
            Text(
              'Pausar',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.iconClient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}