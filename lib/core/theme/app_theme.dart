import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);

  // Eisenhower Matrix Colors
  static const Color q1Red = Color(0xFFEF4444);
  static const Color q2Blue = Color(0xFF3B82F6);
  static const Color q3Yellow = Color(0xFFF59E0B);
  static const Color q4Gray = Color(0xFF64748B);

  // Source Badge Colors
  static const Color whatsAppGreen = Color(0xFF25D366);
  static const Color telegramBlue = Color(0xFF0088CC);
  static const Color gmailRed = Color(0xFFEA4335);
  static const Color voicePurple = Color(0xFF8B5CF6);
  static const Color manualIndigo = Color(0xFF6366F1);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.q2Blue,
      cardColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.q2Blue,
        unselectedItemColor: AppColors.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
