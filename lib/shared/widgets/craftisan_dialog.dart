import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared presentation for confirmations, notices and popup forms.
/// Callers retain ownership of navigation, validation and action callbacks.
class CraftisanDialog extends StatelessWidget {
  const CraftisanDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.icon = Icons.info_outline_rounded,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.muted,
          minimumSize: const Size(80, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    child: AlertDialog(
      scrollable: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x2429231F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFEDE7DF)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      icon: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.promoTint,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: AppColors.terracotta, size: 25),
        ),
      ),
      title: title == null
          ? null
          : Align(alignment: Alignment.centerLeft, child: title),
      titlePadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      titleTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      content: content,
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      contentTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        height: 1.55,
        color: AppColors.muted,
      ),
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      actionsOverflowButtonSpacing: 8,
    ),
  );
}
