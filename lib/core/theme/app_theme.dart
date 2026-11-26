import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema de Material.
///
/// - [light] es el mismo tema que la app tenía antes (no cambia nada).
/// - [dark] usa solo los colores de la web (theme-dark.css).
///
/// Ojo: [AppColors] devuelve los colores del modo activo, así que cada
/// tema se debe construir cuando su modo está activo (lo hace main.dart).
class AppTheme {
  AppTheme._();

  static OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.pageBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.navy,
        error: AppColors.errorText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _borde(AppColors.inputBorder),
        enabledBorder: _borde(AppColors.inputBorder),
        focusedBorder: _borde(AppColors.navy),
        errorBorder: _borde(AppColors.errorText),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkFondo,
      canvasColor: AppColors.darkSuperficie,
      cardColor: AppColors.darkSuperficie,
      dividerColor: AppColors.darkBorde,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.darkTexto,
        displayColor: AppColors.darkTexto,
      ),
      iconTheme: base.iconTheme.copyWith(color: AppColors.darkTexto2),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.darkTiza,
        onPrimary: AppColors.onBrand,
        secondary: AppColors.darkAzul,
        error: AppColors.darkDanger,
        surface: AppColors.darkSuperficie,
        onSurface: AppColors.darkTexto,
        outline: AppColors.darkBorde,
        outlineVariant: AppColors.darkBorde,
        surfaceTint: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSuperficie,
        modalBackgroundColor: AppColors.darkSuperficie,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.darkSuperficie,
        surfaceTintColor: Colors.transparent,
      ),
      // Toast de la web: fondo #343A43 con borde #414A53.
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkSuperficieHover,
        contentTextStyle: TextStyle(color: AppColors.darkTexto),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorde),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.darkTiza),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.darkAzul,
        selectionColor: Color(0x73B83A2E), // ::selection rgba(184,58,46,.45)
        selectionHandleColor: AppColors.darkAzul,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCampos,
        hintStyle: const TextStyle(color: AppColors.darkPlaceholder),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _borde(AppColors.darkBorde),
        enabledBorder: _borde(AppColors.darkBorde),
        focusedBorder: _borde(AppColors.darkAzul),
        errorBorder: _borde(AppColors.darkDanger),
      ),
    );
  }
}
