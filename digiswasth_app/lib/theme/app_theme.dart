import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B1220);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF1F2937);
  static const primary = Color(0xFF38BDF8);
  static const primaryDark = Color(0xFF0EA5E9);
  static const accent = Color(0xFF34D399);
  static const text = Color(0xFFE5E7EB);
  static const muted = Color(0xFF94A3B8);
  static const danger = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const border = Color(0xFF334155);
}

class WidgetColors {
  static const records = Color(0xFF38BDF8);
  static const appointments = Color(0xFFA78BFA);
  static const connect = Color(0xFF34D399);
  static const settings = Color(0xFFFBBF24);
  static const pharmacy = Color(0xFF2DD4BF);
  static const test = Color(0xFFF472B6);
  static const doctor = Color(0xFF60A5FA);
  static const counter = Color(0xFFFB923C);
  static const medai = Color(0xFF818CF8);
}

class StatusColors {
  static Color of(String status) {
    switch (status) {
      case 'draft':
        return AppColors.muted;
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.accent;
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.accent;
      default:
        return AppColors.muted;
    }
  }
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Color(0xFF0B1220),
        onSecondary: Color(0xFF0B1220),
        onSurface: AppColors.text,
        onError: Color(0xFF0B1220),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF0B1220),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
      ),
    );
  }
}