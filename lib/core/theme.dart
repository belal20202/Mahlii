import 'package:flutter/material.dart';

class AppColors {
  static const emerald = Color(0xFF176B5B);
  static const mint = Color(0xFFE5F2ED);
  static const ivory = Color(0xFFFAFBF9);
  static const lightGrey = Color(0xFFF1F4F2);
  static const ink = Color(0xFF26342F);
  static const gold = Color(0xFFC5A56A);
  static const danger = Color(0xFFD94A4A);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      error: AppColors.danger,
      surface: AppColors.ivory,
      onSurface: AppColors.ink,
    );
    return _base(scheme, AppColors.ivory);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(secondary: AppColors.gold, error: AppColors.danger);
    return _base(scheme, const Color(0xFF111A17));
  }

  static ThemeData _base(ColorScheme scheme, Color bg) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1B2723),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.light
            ? AppColors.lightGrey
            : const Color(0xFF1B2723),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.mint,
        backgroundColor: scheme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF16201D),
      ),
    );
  }
}
