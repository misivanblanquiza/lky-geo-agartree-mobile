import 'package:flutter/material.dart';

import '../../core/design_system/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.primary,
      onPrimary: AppPalette.background,
      secondary: AppPalette.secondary,
      onSecondary: AppPalette.tertiary,
      tertiary: AppPalette.tertiary,
      onTertiary: AppPalette.background,
      surface: AppPalette.background,
      onSurface: AppPalette.tertiary,
    );

    const minSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.tertiary,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minSize),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize),
      ),
    );
  }
}
