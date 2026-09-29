import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      surface: AppColors.background,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14),
      bodyLarge: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.6),
      headlineLarge: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontFamilyFallback: ['Georgia', 'Times New Roman'],
        color: AppColors.ink,
        fontSize: 32,
        height: 1.15,
        letterSpacing: -1,
      ),
    ),
  );
}
