import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryDark = Color(0xFF1B5E20);
  static const light = Color(0xFFA5D6A7);
  static const accent = Color(0xFF8BC34A);
  static const background = Color(0xFFF1F8E9);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFF9A825);
  static const warningText = Color(0xFFB57A00);
  static const line = Color(0xFFE5EBDD);
  static const land = Color(0xFFE9F4DF);
  static const sea = Color(0xFFCDE7EF);
  static const field = Color(0xFFD5EAC4);
  static const shore = Color(0xFF9CCBD9);
  static const seaText = Color(0xFF5B8FA3);
  static const shadow = Color(0x2E1B5E20);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary, primary: AppColors.primary);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.light,
    ),
  );
}
