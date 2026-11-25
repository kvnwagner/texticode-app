import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema de Material para modo claro y oscuro.
///
/// Los colores salen de [AppColors], que ya devuelve la paleta del modo
/// activo; por eso ambos temas se construyen igual y solo cambia la base.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    OutlineInputBorder borde(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.pageBg,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      dividerColor: AppColors.cardBorder,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: base.iconTheme.copyWith(color: AppColors.textSecondary),
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: AppColors.navy,
        onPrimary: AppColors.onBrand,
        secondary: AppColors.forgotLink,
        error: AppColors.errorText,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.cardBorder,
        outlineVariant: AppColors.cardBorder,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pageBg,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSuperficieHover : const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(color: AppColors.cardBorder),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: AppColors.navy),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.navy,
        selectionColor: AppColors.navy.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.navy,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: TextStyle(color: AppColors.inputPlaceholder),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: borde(AppColors.inputBorder),
        enabledBorder: borde(AppColors.inputBorder),
        focusedBorder: borde(isDark ? AppColors.darkAzul : AppColors.navy),
        errorBorder: borde(AppColors.errorText),
      ),
    );
  }
}
