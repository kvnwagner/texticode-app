import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Paleta oficial de Texticode.
///
/// - Modo claro: los mismos colores de siempre de la app.
/// - Modo oscuro: exactamente la paleta "Grafito Industrial" de la web
///   (FRONTEND/src/assets/theme-dark.css). No se usa ningún color que no
///   esté definido allá.
///
/// Los nombres no cambiaron (`AppColors.navy`, `AppColors.textPrimary`...).
/// Ahora son *getters* que devuelven el color del tema activo, por eso
/// ya no pueden ir dentro de expresiones `const`.
class AppColors {
  AppColors._();

  static bool get _dark => ThemeController.instance.isDark;

  /// true si el modo oscuro está activo.
  static bool get isDark => _dark;

  static Color _c(Color light, Color dark) => _dark ? dark : light;

  // ============================================================
  // PALETA DE LA WEB EN MODO OSCURO (theme-dark.css)
  // ============================================================

  static const darkGrafito = Color(0xFF23272E); //         --pal-grafito (menú)
  static const darkTiza = Color(0xFFB83A2E); //            --pal-tiza (botones)
  static const darkTizaHover = Color(0xFFD14B3E); //       --pal-tiza-hover
  static const darkFondo = Color(0xFF15191E); //           --pal-fondo
  static const darkSuperficie = Color(0xFF292F36); //      --pal-superficie
  static const darkSuperficieHover = Color(0xFF343A43); // --pal-superficie-hov
  static const darkTexto = Color(0xFFF2F4F1); //           --pal-texto
  static const darkTexto2 = Color(0xFFB6C0C8); //          --pal-texto-2
  static const darkTextoMuted = Color(0xFF8D98A2); //      --color-text-muted
  static const darkPlaceholder = Color(0xFF7E8993); //     input::placeholder
  static const darkAzul = Color(0xFF78A9D4); //            --pal-azul
  static const darkBorde = Color(0xFF414A53); //           --pal-borde
  static const darkCuadricula = Color(0xFF343E43); //      --pal-cuadricula
  static const darkCampos = Color(0xFF22282E); //          --pal-campos

  static const darkSuccess = Color(0xFF7FCB97); //         --th-success
  static const darkSuccessSolid = Color(0xFF6CC08A); //    --th-success-solid
  static const darkDanger = Color(0xFFE8867C); //          --th-danger
  static const darkDangerSolid = Color(0xFFC9473B); //     --color-danger-solid
  static const darkWarning = Color(0xFFE3B672); //         --th-warning
  static const darkWarningSolid = Color(0xFFD9A24E); //    --th-warning-solid
  static const darkPurple = Color(0xFFB7A4EE); //          --th-purple
  static const darkPink = Color(0xFFEEA2C4); //            --th-pink

  // Fondos suaves (los rgba de la web pasados a ARGB)
  static const darkSuccessSoft = Color(0x247FCB97); //  rgba(127,203,151,.14)
  static const darkDangerSoft = Color(0x2ED14B3E); //   rgba(209,75,62,.18)
  static const darkWarningSoft = Color(0x26E3B672); //  rgba(227,182,114,.15)
  static const darkInfoSoft = Color(0x2678A9D4); //     rgba(120,169,212,.15)
  static const darkPurpleSoft = Color(0x26B7A4EE); //   rgba(183,164,238,.15)
  static const darkPinkSoft = Color(0x26EEA2C4); //     rgba(238,162,196,.15)
  static const darkDangerBorder = Color(0x66E8867C); // rgba(232,134,124,.40)

  // ============================================================
  // SUPERFICIES Y NAVEGACIÓN
  // ============================================================

  /// Tarjetas, hojas inferiores, menús y diálogos (--th-surface).
  static Color get surface => _c(Colors.white, darkSuperficie);

  /// Elementos activos sobre una superficie (--th-surface-3).
  static Color get surfaceHover =>
      _c(const Color(0xFFF3F4F6), darkSuperficieHover);

  /// Fondo del dock inferior (en la web: menú lateral grafito).
  static Color get dockBg => _c(Colors.white, darkGrafito);

  /// Píldora del ítem activo del dock (.menu-item.active de la web).
  static Color get navPillActive =>
      _c(const Color(0xFF1F3A52), darkSuperficieHover);

  /// Ícono del ítem activo del dock.
  static Color get navIconActive => _c(Colors.white, darkTexto);

  /// Tinte del logo: en oscuro blanco (#F2F2F2 = invert(0.95) de la web,
  /// `.logo-full img { filter: brightness(0) invert(0.95) }`); en claro
  /// null para dejar el logo con sus colores originales.
  static Color? get logoTint => _dark ? const Color(0xFFF2F2F2) : null;

  // ── Vista "Mi perfil" ──
  // En oscuro las tarjetas y botones van en grises de la paleta (como los
  // botones .user-info / .theme-btn del menú de la web), no en tiza roja.

  /// Fondo de la tarjeta de perfil.
  static List<Color> get perfilCardGradient => _dark
      ? const [darkSuperficieHover, darkSuperficie]
      : const [Color(0xFF1F3A52), Color(0xFF2D5478)];

  /// Borde de la tarjeta de perfil (solo en oscuro).
  static Color get perfilCardBorder => _c(Colors.transparent, darkBorde);

  /// Sombra de la tarjeta de perfil (--shadow-md en oscuro).
  static Color get perfilCardShadow =>
      _c(const Color(0x401F3A52), const Color(0x61000000));

  /// Círculo de iniciales del perfil (.perfil-avatar de la web):
  /// linear-gradient(135deg, --color-brand, --color-accent).
  static List<Color> get perfilAvatarGradient => _dark
      ? const [darkTiza, darkAzul]
      : const [Color(0xFF1F3A52), Color(0xFF2D6A9F)];

  /// Botones de acción del perfil (vincular Google, sincronizar...).
  static Color get perfilBotonBg => _c(const Color(0xFF1F3A52), darkSuperficieHover);
  static Color get perfilBotonFg => _c(Colors.white, darkTexto);
  static Color get perfilBotonBorde => _c(Colors.transparent, darkBorde);

  /// Botón de peligro del perfil (como .logout de la web en oscuro).
  static Color get perfilPeligroBg =>
      _c(const Color(0xFFDC2626), const Color(0x24D14B3E)); // rgba(209,75,62,.14)
  static Color get perfilPeligroFg => _c(Colors.white, darkDanger);
  static Color get perfilPeligroBorde =>
      _c(Colors.transparent, const Color(0x59E8867C)); // rgba(232,134,124,.35)

  /// Texto e íconos sobre el color de marca.
  static const onBrand = Colors.white;

  // ============================================================
  // LOGIN
  // ============================================================

  /// En oscuro el fondo del login es el fondo profundo (#15191E).
  static List<Color> get loginGradient => _dark
      ? const [darkFondo, darkFondo, darkFondo, darkFondo]
      : const [
          Color(0xFF0D1F2D),
          Color(0xFF1A3347),
          Color(0xFF0F2233),
          Color(0xFF0A1A27),
        ];

  /// Brillos del fondo del login (.bg-gradient de LoginView.vue).
  static Color get loginBlob1 => _c(
      const Color(0x332D6A9F), const Color(0x24B83A2E)); // rgba(184,58,46,.14)
  static Color get loginBlob2 => _c(
      const Color(0x401F3A52), const Color(0x59343E43)); // rgba(52,62,67,.35)

  static Color get cardWhite => _c(const Color(0xFAFFFFFF), darkSuperficie);

  static Color get headingDark => _c(const Color(0xFF0D1F2D), darkTexto);
  static Color get subtitle => _c(const Color(0xFF6B7280), darkTexto2);
  static Color get forgotLink => _c(const Color(0xFF2D6A9F), darkAzul);

  static Color get inputBg => _c(const Color(0xFFF9FAFB), darkCampos);
  static Color get inputBorder => _c(const Color(0xFFE5E7EB), darkBorde);

  /// Borde de un campo con foco (en oscuro, azul suave como la web).
  static Color get inputFocusBorder => _c(const Color(0xFF1F3A52), darkAzul);
  static Color get inputText => _c(const Color(0xFF111827), darkTexto);
  static Color get inputPlaceholder =>
      _c(const Color(0xFFC4C9D4), darkPlaceholder);

  static Color get iconDefault => _c(const Color(0xFF9CA3AF), darkTextoMuted);
  static Color get labelColor => _c(const Color(0xFF374151), darkTexto2);

  /// Degradado de botones principales. En oscuro la web usa tiza sólida
  /// (.btn-login { background: #B83A2E }).
  static List<Color> get primaryGradient => _dark
      ? const [darkTiza, darkTiza]
      : const [Color(0xFF1F3A52), Color(0xFF2D5478)];

  /// Fondo del botón "Continuar con Google" (.btn-google).
  static Color get googleBg => _c(Colors.white, darkCampos);
  static Color get googleBorder => _c(const Color(0xFFE5E7EB), darkBorde);
  static Color get googleText => _c(const Color(0xFF1F2937), darkTexto);

  // ============================================================
  // ERRORES
  // ============================================================

  static Color get errorText => _c(const Color(0xFFDC2626), darkDanger);
  static Color get errorBg => _c(const Color(0xFFFEF2F2), darkDangerSoft);
  /// Botones de peligro (cerrar sesión, eliminar): --color-danger-solid.
  static Color get dangerSolid => _c(const Color(0xFFDC2626), darkDangerSolid);

  static Color get errorBorder =>
      _c(const Color(0xFFFECACA), darkDangerBorder);

  // ============================================================
  // COLORES GENERALES
  // ============================================================

  static Color get pageBg => _c(const Color(0xFFFFFFFF), darkFondo);
  static Color get cardBorder => _c(const Color(0xFFE5E7EB), darkBorde);

  /// Marca para RELLENOS (botones, chips activos): azul petróleo en
  /// claro, tiza roja en oscuro (--th-brand).
  static Color get navy => _c(const Color(0xFF1F3A52), darkTiza);
  static Color get navyHover => _c(const Color(0xFF162B3C), darkTizaHover);

  /// Marca para TEXTO (títulos, montos): en oscuro es el texto
  /// principal (--th-heading).
  static Color get brandText => _c(const Color(0xFF1F3A52), darkTexto);

  /// Marca para ÍCONOS: en oscuro va neutro, como los íconos de las KPI
  /// de la web (.kpi-card__icon → texto secundario).
  static Color get brandIcon => _c(const Color(0xFF1F3A52), darkTexto2);

  /// Tintes de marca con transparencia: en la web --th-brand-rgb pasa a
  /// azul suave en oscuro.
  static Color get brandTint => _c(const Color(0xFF1F3A52), darkAzul);

  static Color get footerText => _c(const Color(0xFFC4C9D4), darkTextoMuted);

  static Color get iconActive => _c(const Color(0xFF16A34A), darkSuccessSolid);
  static Color get iconOp => _c(const Color(0xFF2563EB), darkAzul);
  static Color get iconClient => _c(const Color(0xFFD97706), darkWarningSolid);

  // ============================================================
  // BADGES DE ROLES
  // ============================================================

  static Color get badgeAdminBg => _c(const Color(0xFFE0E7FF), darkInfoSoft);
  static Color get badgeAdminText => _c(const Color(0xFF3730A3), darkAzul);

  static Color get badgeOpGreenBg =>
      _c(const Color(0xFFDCFCE7), darkSuccessSoft);
  static Color get badgeOpGreenText => _c(const Color(0xFF15803D), darkSuccess);

  /// Texto del badge "Activa" del superadmin (en claro era #166534).
  static Color get superadminVerdeText =>
      _c(const Color(0xFF166534), darkSuccess);

  static Color get badgeClientBg =>
      _c(const Color(0xFFFEF9C3), darkWarningSoft);
  static Color get badgeClientText => _c(const Color(0xFF92400E), darkWarning);

  // ============================================================
  // TEXTOS
  // ============================================================

  static Color get textPrimary => _c(const Color(0xFF111827), darkTexto);
  static Color get textSecondary => _c(const Color(0xFF374151), darkTexto2);
  static Color get textMuted => _c(const Color(0xFF6B7280), darkTextoMuted);
  static Color get textFaint => _c(const Color(0xFF9CA3AF), darkTextoMuted);

  // ============================================================
  // GESTIÓN DE USUARIOS
  // ============================================================

  static Color get searchBg => _c(const Color(0xFFF9FAFB), darkCampos);

  /// Ícono/número de la KPI "Total": neutro en oscuro.
  static Color get iconTotal => _c(const Color(0xFF1F3A52), darkTexto);

  static Color get badgeOpBlueBg => _c(const Color(0xFFE0ECFF), darkInfoSoft);
  static Color get badgeOpBlueText => _c(const Color(0xFF2563EB), darkAzul);

  /// Paleta rotativa para los avatares circulares.
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
    {'bg': darkInfoSoft, 'text': darkAzul},
    {'bg': darkPinkSoft, 'text': darkPink},
    {'bg': darkSuccessSoft, 'text': darkSuccess},
    {'bg': darkWarningSoft, 'text': darkWarning},
    {'bg': darkPurpleSoft, 'text': darkPurple},
    {'bg': darkDangerSoft, 'text': darkDanger},
  ];

  // ============================================================
  // GESTIÓN DE PRODUCCIÓN
  // ============================================================

  static Color get purple => _c(const Color(0xFF7C3AED), darkPurple);
  static Color get purpleBg => _c(const Color(0xFFEDE9FE), darkPurpleSoft);

  // ============================================================
  // PRIORIDADES DE ÓRDENES
  // ============================================================

  static Color get priorityHighBg =>
      _c(const Color(0xFFFEE2E2), darkDangerSoft);
  static Color get priorityHighText => _c(const Color(0xFF991B1B), darkDanger);

  static Color get priorityMediumBg =>
      _c(const Color(0xFFFEF9C3), darkWarningSoft);
  static Color get priorityMediumText =>
      _c(const Color(0xFF92400E), darkWarning);

  static Color get priorityLowBg =>
      _c(const Color(0xFFDCFCE7), darkSuccessSoft);
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

  static Color get statusPendingBg => _c(const Color(0xFFF9FAFB), darkCampos);
  static Color get statusPendingText => textMuted;
}
