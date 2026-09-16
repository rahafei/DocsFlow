import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.inter(),
        bodyMedium: GoogleFonts.inter(),
        bodySmall: GoogleFonts.inter(),
        titleLarge: GoogleFonts.instrumentSans(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.instrumentSans(
          fontWeight: FontWeight.w600,
        ),
      ),
      useMaterial3: true,
    );
  }
}