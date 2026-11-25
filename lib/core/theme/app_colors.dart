import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Paleta oficial de Texticode, igual a la web.
///
/// - Modo claro: los mismos colores de siempre (tokens.css).
/// - Modo oscuro: paleta "Grafito Industrial" (theme-dark.css).
///
/// Los nombres no cambiaron, así que las pantallas siguen usando
/// `AppColors.navy`, `AppColors.textPrimary`, etc. La diferencia es que
/// ahora son *getters*: devuelven el color del tema activo. Por eso ya no
/// se pueden usar dentro de expresiones `const`.
class AppColors {
  AppColors._();

  static bool get _dark => ThemeController.instance.isDark;

  /// true si el modo oscuro está activo.
  static bool get isDark => _dark;
  static Color _c(Color light, Color dark) => _dark ? dark : light;

  // ============================================================
  // PALETA BASE (referencia)
  // ============================================================

  // Grafito Industrial
  static const darkGrafito = Color(0xFF23272E); // menú / dock
  static const darkTiza = Color(0xFFB83A2E); // botones principales
  static const darkTizaHover = Color(0xFFD14B3E);
  static const darkFondo = Color(0xFF15191E);
  static const darkSuperficie = Color(0xFF292F36);
  static const darkSuperficieHover = Color(0xFF343A43);
  static const darkTexto = Color(0xFFF2F4F1);
  static const darkTexto2 = Color(0xFFB6C0C8);
  static const darkTextoMuted = Color(0xFF8D98A2);
  static const darkTextoFaint = Color(0xFF6F7B85);
  static const darkTextoDisabled = Color(0xFF5F6B75);
  static const darkAzul = Color(0xFF78A9D4);
  static const darkBorde = Color(0xFF414A53);
  static const darkBordeFuerte = Color(0xFF4C5661);
  static const darkCampos = Color(0xFF22282E);
  static const darkSuccess = Color(0xFF7FCB97);
  static const darkDanger = Color(0xFFE8867C);
  static const darkWarning = Color(0xFFE3B672);
  static const darkPurple = Color(0xFFB7A4EE);
  static const darkPink = Color(0xFFEEA2C4);

  // ============================================================
  // SUPERFICIES (nuevas, para reemplazar Colors.white en tarjetas)
  // ============================================================

  /// Fondo de tarjetas, hojas inferiores, diálogos y dock.
  static Color get surface => _c(Colors.white, darkSuperficie);

  /// Elementos activos / hover sobre una superficie.
  static Color get surfaceHover =>
      _c(const Color(0xFFF3F4F6), darkSuperficieHover);

  /// Fondo del menú inferior (dock).
  static Color get dockBg => _c(Colors.white, darkGrafito);

  /// Velo detrás de modales.
  static Color get overlay =>
      _c(const Color(0x730F172A), const Color(0xA605070A));

  /// Texto e íconos sobre el color de marca.
  static const onBrand = Colors.white;

  /// Sombra base de tarjetas.
  static Color get shadow =>
      _c(const Color(0x0F0F172A), const Color(0x4D000000));

  // ============================================================
  // LOGIN
  // ============================================================

  static List<Color> get loginGradient => _dark
      ? const [
          Color(0xFF15191E),
          Color(0xFF1B2026),
          Color(0xFF23272E),
          Color(0xFF15191E),
        ]
      : const [
          Color(0xFF0D1F2D),
          Color(0xFF1A3347),
          Color(0xFF0F2233),
          Color(0xFF0A1A27),
        ];

  static Color get loginBlob1 =>
      _c(const Color(0x332D6A9F), const Color(0x26B83A2E));
  static Color get loginBlob2 =>
      _c(const Color(0x401F3A52), const Color(0x3378A9D4));

  static Color get cardWhite => _c(const Color(0xFAFFFFFF), darkSuperficie);

  static Color get headingDark => _c(const Color(0xFF0D1F2D), darkTexto);
  static Color get subtitle => _c(const Color(0xFF6B7280), darkTextoMuted);
  static Color get forgotLink => _c(const Color(0xFF2D6A9F), darkAzul);

  static Color get inputBg => _c(const Color(0xFFF9FAFB), darkCampos);
  static Color get inputBorder => _c(const Color(0xFFE5E7EB), darkBordeFuerte);
  static Color get inputText => _c(const Color(0xFF111827), darkTexto);
  static Color get inputPlaceholder =>
      _c(const Color(0xFFC4C9D4), darkTextoDisabled);

  static Color get iconDefault => _c(const Color(0xFF9CA3AF), darkTextoFaint);
  static Color get labelColor => _c(const Color(0xFF374151), darkTexto2);

  static List<Color> get primaryGradient => _dark
      ? const [darkTiza, darkTizaHover]
      : const [Color(0xFF1F3A52), Color(0xFF2D5478)];

  static Color get googleBorder => _c(const Color(0xFFE5E7EB), darkBorde);
  static Color get googleText => _c(const Color(0xFF1F2937), darkTexto);

  // ============================================================
  // ERRORES
  // ============================================================

  static Color get errorText => _c(const Color(0xFFDC2626), darkDanger);
  static Color get errorBg => _c(const Color(0xFFFEF2F2), const Color(0x2ED14B3E));
  static Color get errorBorder =>
      _c(const Color(0xFFFECACA), const Color(0x66D14B3E));

  // ============================================================
  // COLORES GENERALES
  // ============================================================

  static Color get pageBg => _c(Colors.white, darkFondo);
  static Color get cardBorder => _c(const Color(0xFFE5E7EB), darkBorde);

  /// Color de marca: azul petróleo en claro, tiza roja en oscuro.
  static Color get navy => _c(const Color(0xFF1F3A52), darkTiza);
  static Color get navyHover => _c(const Color(0xFF162B3C), darkTizaHover);

  /// Texto en color de marca (títulos/montos). En oscuro usa el texto
  /// principal, como `--th-heading` en la web.
  static Color get brandText => _c(const Color(0xFF1F3A52), darkTexto);

  static Color get footerText => _c(const Color(0xFFC4C9D4), darkTextoDisabled);

  static Color get iconActive => _c(const Color(0xFF16A34A), darkSuccess);
  static Color get iconOp => _c(const Color(0xFF2563EB), darkAzul);
  static Color get iconClient => _c(const Color(0xFFD97706), darkWarning);

  // ============================================================
  // BADGES DE ROLES
  // ============================================================

  static Color get badgeAdminBg =>
      _c(const Color(0xFFE0E7FF), const Color(0x26B7A4EE));
  static Color get badgeAdminText => _c(const Color(0xFF3730A3), darkPurple);

  static Color get badgeOpGreenBg =>
      _c(const Color(0xFFDCFCE7), const Color(0x247FCB97));
  static Color get badgeOpGreenText => _c(const Color(0xFF15803D), darkSuccess);

  static Color get badgeClientBg =>
      _c(const Color(0xFFFEF9C3), const Color(0x26E3B672));
  static Color get badgeClientText => _c(const Color(0xFF92400E), darkWarning);

  // ============================================================
  // TEXTOS
  // ============================================================

  static Color get textPrimary => _c(const Color(0xFF111827), darkTexto);
  static Color get textSecondary => _c(const Color(0xFF374151), darkTexto2);
  static Color get textMuted => _c(const Color(0xFF6B7280), darkTextoMuted);
  static Color get textFaint => _c(const Color(0xFF9CA3AF), darkTextoFaint);

  // ============================================================
  // GESTIÓN DE USUARIOS
  // ============================================================

  static Color get searchBg => _c(const Color(0xFFF9FAFB), darkCampos);

  static Color get iconTotal => navy;

  static Color get badgeOpBlueBg =>
      _c(const Color(0xFFE0ECFF), const Color(0x2678A9D4));
  static Color get badgeOpBlueText => _c(const Color(0xFF2563EB), darkAzul);

  /// Paleta rotativa para los avatares circulares
  /// de la lista de usuarios.
  static List<Map<String, Color>> get avatarPalette =>
      _dark ? _avatarPaletteDark : _avatarPaletteLight;

  static const List<Map<String, Color>> _avatarPaletteLight = [
    {'bg': Color(0xFFDBEAFE), 'text': Color(0xFF1D4ED8)},
    {'bg': Color(0xFFFCE7F3), 'text': Color(0xFFBE185D)},
    {'bg': Color(0xFFD1FAE5), 'text': Color(0xFF065F46)},
    {'bg': Color(0xFFFEF9C3), 'text': Color(0xFF92400E)},
    {'bg': Color(0xFFEDE9FE), 'text': Color(0xFF5B21B6)},
    {'bg': Color(0xFFFEE2E2), 'text': Color(0xFF991B1B)},
  ];

  static const List<Map<String, Color>> _avatarPaletteDark = [
    {'bg': Color(0x2678A9D4), 'text': darkAzul},
    {'bg': Color(0x26EEA2C4), 'text': darkPink},
    {'bg': Color(0x247FCB97), 'text': darkSuccess},
    {'bg': Color(0x26E3B672), 'text': darkWarning},
    {'bg': Color(0x26B7A4EE), 'text': darkPurple},
    {'bg': Color(0x2ED14B3E), 'text': darkDanger},
  ];

  // ============================================================
  // GESTIÓN DE PRODUCCIÓN
  // ============================================================

  static Color get purple => _c(const Color(0xFF7C3AED), darkPurple);
  static Color get purpleBg =>
      _c(const Color(0xFFEDE9FE), const Color(0x26B7A4EE));

  // ============================================================
  // PRIORIDADES DE ÓRDENES
  // ============================================================

  static Color get priorityHighBg =>
      _c(const Color(0xFFFEE2E2), const Color(0x2ED14B3E));
  static Color get priorityHighText => _c(const Color(0xFF991B1B), darkDanger);

  static Color get priorityMediumBg =>
      _c(const Color(0xFFFEF9C3), const Color(0x26E3B672));
  static Color get priorityMediumText =>
      _c(const Color(0xFF92400E), darkWarning);

  static Color get priorityLowBg =>
      _c(const Color(0xFFDCFCE7), const Color(0x247FCB97));
  static Color get priorityLowText => _c(const Color(0xFF15803D), darkSuccess);

  // ============================================================
  // ESTADOS DE ÓRDENES
  // ============================================================

  static Color get statusInProgressBg => purpleBg;
  static Color get statusInProgressText => purple;

  static Color get statusCompletedBg => badgeOpGreenBg;
  static Color get statusCompletedText => badgeOpGreenText;

  static Color get statusDelayedBg => errorBg;
  static Color get statusDelayedText => errorText;

  static Color get statusPendingBg => _c(const Color(0xFFF9FAFB), darkSuperficieHover);
  static Color get statusPendingText => textMuted;
}
