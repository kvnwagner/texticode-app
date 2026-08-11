import 'package:flutter/material.dart';

/// Paleta de colores oficial de Texticode.
/// Tomada 1:1 de los tokens `C` usados en el prototipo web (React),
/// para que la versión móvil se vea idéntica.
class AppColors {
  AppColors._();

  // Login background gradient
  static const loginGradient = [
    Color(0xFF0D1F2D),
    Color(0xFF1A3347),
    Color(0xFF0F2233),
    Color(0xFF0A1A27),
  ];

  static const loginBlob1 = Color(0x332D6A9F); // rgba(45,106,159,0.2)
  static const loginBlob2 = Color(0x401F3A52); // rgba(31,58,82,0.25)

  static const cardWhite = Color(0xFAFFFFFF); // rgba(255,255,255,0.98)
  static const headingDark = Color(0xFF0D1F2D);
  static const subtitle = Color(0xFF6B7280);
  static const forgotLink = Color(0xFF2D6A9F);

  static const inputBg = Color(0xFFF9FAFB);
  static const inputBorder = Color(0xFFE5E7EB);
  static const inputText = Color(0xFF111827);
  static const inputPlaceholder = Color(0xFFC4C9D4);
  static const iconDefault = Color(0xFF9CA3AF);
  static const labelColor = Color(0xFF374151);

  static const primaryGradient = [
    Color(0xFF1F3A52),
    Color(0xFF2D5478),
  ];

  static const googleBorder = Color(0xFFE5E7EB);
  static const googleText = Color(0xFF1F2937);

  static const errorText = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);

  static const pageBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE5E7EB);

  static const navy = Color(0xFF1F3A52);
  static const navyHover = Color(0xFF162B3C);

  static const footerText = Color(0xFFC4C9D4);

  static const iconActive = Color(0xFF16A34A);
  static const iconOp = Color(0xFF2563EB);
  static const iconClient = Color(0xFFD97706);

  static const badgeAdminBg = Color(0xFFE0E7FF);
  static const badgeAdminText = Color(0xFF3730A3);
  static const badgeOpGreenBg = Color(0xFFDCFCE7);
  static const badgeOpGreenText = Color(0xFF15803D);
  static const badgeClientBg = Color(0xFFFEF9C3);
  static const badgeClientText = Color(0xFF92400E);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF374151);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);

  // ⬅️ nuevo — usados en la pantalla de Gestión de Usuarios (admin_home_screen.dart)
  static const searchBg = Color(0xFFF9FAFB);
  static const iconTotal = navy;

  static const badgeOpBlueBg = Color(0xFFE0ECFF);
  static const badgeOpBlueText = Color(0xFF2563EB);

  /// Paleta rotativa para los avatares circulares de la lista de usuarios.
  static const List<Map<String, Color>> avatarPalette = [
    {'bg': Color(0xFFDBEAFE), 'text': Color(0xFF1D4ED8)},
    {'bg': Color(0xFFFCE7F3), 'text': Color(0xFFBE185D)},
    {'bg': Color(0xFFD1FAE5), 'text': Color(0xFF065F46)},
    {'bg': Color(0xFFFEF9C3), 'text': Color(0xFF92400E)},
    {'bg': Color(0xFFEDE9FE), 'text': Color(0xFF5B21B6)},
    {'bg': Color(0xFFFEE2E2), 'text': Color(0xFF991B1B)},
  ];
}