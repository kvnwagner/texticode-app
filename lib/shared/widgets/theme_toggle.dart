import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Botón sol/luna, igual al del menú lateral y el login de la web.
/// Muestra el sol cuando está en oscuro (para pasar a claro) y la luna
/// cuando está en claro.
class ThemeToggleButton extends StatelessWidget {
  /// Usa colores claros fijos (para fondos oscuros como el login).
  final bool sobreFondoOscuro;
  final double size;

  const ThemeToggleButton({
    super.key,
    this.sobreFondoOscuro = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final tema = ThemeController.instance;
    return ListenableBuilder(
      listenable: tema,
      builder: (context, _) {
        final oscuro = tema.isDark;
        // Colores del .theme-btn de la web (login y menú lateral).
        final fg = sobreFondoOscuro
            ? const Color(0xD9FFFFFF) // rgba(255,255,255,.85)
            : AppColors.textSecondary;
        final bg = sobreFondoOscuro
            ? const Color(0x14FFFFFF) // rgba(255,255,255,.08)
            : AppColors.surface;
        final borde = sobreFondoOscuro
            ? const Color(0x2EFFFFFF) // rgba(255,255,255,.18)
            : (oscuro ? AppColors.darkSuperficieHover : AppColors.cardBorder);
        return Tooltip(
          message: oscuro ? 'Modo claro' : 'Modo oscuro',
          child: Semantics(
            button: true,
            label: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            child: Material(
              color: bg,
              shape: CircleBorder(side: BorderSide(color: borde)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  tema.alternar();
                },
                child: SizedBox(
                  width: size,
                  height: size,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      oscuro
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      key: ValueKey(oscuro),
                      size: size * 0.45,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fila para pantallas de perfil: "Apariencia" con las tres opciones
/// de la web (Claro / Oscuro / Automático).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = ThemeController.instance;
    return ListenableBuilder(
      listenable: tema,
      builder: (context, _) {
        Widget opcion(ModoTema modo, IconData icono, String texto) {
          final activo = tema.modo == modo;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                tema.setModo(modo);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activo ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono,
                        size: 18,
                        color: activo ? AppColors.onBrand : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      texto,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activo ? AppColors.onBrand : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Elige cómo quieres ver Texticode',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.searchBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    opcion(ModoTema.claro, Icons.light_mode_outlined, 'Claro'),
                    opcion(ModoTema.oscuro, Icons.dark_mode_outlined, 'Oscuro'),
                    opcion(ModoTema.auto, Icons.brightness_auto_outlined,
                        'Automático'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
