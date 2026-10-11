import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    dialogTheme: popupDialogTheme,
    snackBarTheme: popupSnackBarTheme,
    bottomSheetTheme: popupBottomSheetTheme,
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

  static const popupDialogTheme = DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      side: BorderSide(color: Color(0xFFEDE7DF)),
    ),
  );

  static const popupSnackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF203E37),
    contentTextStyle: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
    actionTextColor: Color(0xFFF2D3AA),
    elevation: 4,
    insetPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    showCloseIcon: true,
    closeIconColor: Colors.white,
  );

  static const popupBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    modalBarrierColor: Color(0x660F211D),
    showDragHandle: true,
    dragHandleColor: Color(0xFFD8D0C5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
  );
}
