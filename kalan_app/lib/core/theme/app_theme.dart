import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() => _buildTheme(Brightness.light);
  static ThemeData darkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    const bg = AppColors.background; // Fond global blanc
    const surf = AppColors.surface; // Toujours blanc
    const onBg = AppColors.onBackground; // Toujours sombre pour la lisibilité

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        surface: surf,
        onSurface: onBg,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      textTheme: GoogleFonts.fredokaTextTheme(
        TextTheme(
          displayLarge: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.bold, color: onBg),
          titleLarge: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: onBg),
          titleMedium: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: onBg),
          bodyLarge: GoogleFonts.fredoka(fontSize: 16, color: onBg),
          bodyMedium: GoogleFonts.fredoka(fontSize: 14, color: onBg),
        ),
      ),
    );
  }
}
