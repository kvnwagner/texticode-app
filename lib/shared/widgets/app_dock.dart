import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Dock de navegación inferior reutilizable, con la misma animación e
/// interacción que originalmente solo tenía el panel admin: la píldora
/// de fondo sigue el dedo de forma continua mientras arrastras (y se
/// ensancha, "modo burbuja"), con feedback háptico al cruzar de ícono,
/// y solo confirma la navegación real al soltar el dedo.
///
/// Uso (idéntico en admin, operario y cliente):
/// ```dart
/// AppDock(
///   icons: _bottomIcons,
///   selectedIndex: _bottomIndex,
///   onSelected: (i) => setState(() => _bottomIndex = i),
/// )
/// ```
class AppDock extends StatefulWidget {
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppDock({
    super.key,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<AppDock> createState() => _AppDockState();
}

class _AppDockState extends State<AppDock> {
  // Mientras arrastras el dedo por el dock:
  // - _dragX es la posición X real del dedo (para que la píldora lo
  //   siga de forma continua, no a saltos de ícono en ícono).
  // - _dragIndex es a qué ícono corresponde esa posición (para saber
  //   cuál pintar de blanco/resaltado).
  // Ambos son null cuando no hay un arrastre en curso. La navegación
  // real (widget.onSelected) solo se dispara al soltar el dedo.
  double? _dragX;
  int? _dragIndex;

  @override
  Widget build(BuildContext context) {
    const dockHeight = 62.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: dockHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // El LayoutBuilder va DENTRO del Container (después del borde),
        // no afuera: un Border dentro de una BoxDecoration le agrega un
        // padding implícito al Container igual a su grosor. Si el
        // LayoutBuilder midiera el ancho ANTES de esa reducción, el
        // cálculo de iconWidth quedaría más grande de lo real y el Row
        // terminaría desbordado por esos mismos pixeles del borde.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final iconWidth = width / widget.icons.length;

            // Tamaño de la píldora en reposo vs. mientras arrastras
            // ("modo burbuja" — se ensancha un poco al mover el dedo).
            const pillWidthIdle = 44.0;
            const pillWidthDragging = 60.0;
            const pillHeight = 42.0;

            int indexForX(double x) =>
                (x / iconWidth).floor().clamp(0, widget.icons.length - 1);

            void updateDrag(Offset localPosition) {
              final x = localPosition.dx.clamp(0.0, width - 0.01);
              final index = indexForX(x);
              if (index != _dragIndex) HapticFeedback.selectionClick();
              setState(() {
                _dragX = x;
                _dragIndex = index;
              });
            }

            // Al soltar: la píldora "cae" en el ícono elegido y ahí sí
            // se confirma la navegación real.
            void commitSelection() {
              if (_dragIndex == null) {
                setState(() => _dragX = null);
                return;
              }
              final chosen = _dragIndex!;
              setState(() {
                _dragIndex = null;
                _dragX = null;
              });
              widget.onSelected(chosen);
            }

            final dragging = _dragX != null;
            final displayIndex = _dragIndex ?? widget.selectedIndex;
            final pillWidth = dragging ? pillWidthDragging : pillWidthIdle;

            // Mientras arrastras, la píldora sigue el dedo de forma
            // continua (no salta de ícono en ícono). En reposo (o justo
            // después de soltar), queda centrada bajo el ícono activo.
            final pillLeft = dragging
                ? (_dragX! - pillWidth / 2).clamp(0.0, width - pillWidth)
                : (displayIndex * iconWidth + (iconWidth - pillWidth) / 2)
                    .clamp(0.0, width - pillWidth);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) => updateDrag(details.localPosition),
              onPanUpdate: (details) => updateDrag(details.localPosition),
              onPanEnd: (_) => commitSelection(),
              onPanCancel: () => setState(() {
                _dragIndex = null;
                _dragX = null;
              }),
              child: Stack(
                children: [
                  // Píldora ovalada de fondo — se mueve suave y continua
                  // (AnimatedPositioned) y se ensancha al arrastrar
                  // (AnimatedContainer con curva rápida tipo burbuja).
                  AnimatedPositioned(
                    duration: Duration(milliseconds: dragging ? 60 : 220),
                    curve: Curves.easeOut,
                    left: pillLeft,
                    top: (dockHeight - 2 - pillHeight) / 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      width: pillWidth,
                      height: pillHeight,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(widget.icons.length, (i) {
                      final selected = i == displayIndex;
                      return IgnorePointer(
                        // El toque ya lo maneja el GestureDetector de
                        // arriba (para que el arrastre funcione en todo
                        // el dock, no solo dentro de cada ícono).
                        child: SizedBox(
                          width: iconWidth,
                          height: double.infinity,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 120),
                              child: Icon(
                                widget.icons[i],
                                key: ValueKey(selected),
                                size: 20,
                                color: selected ? Colors.white : AppColors.textFaint,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}