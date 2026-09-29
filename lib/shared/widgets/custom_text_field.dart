import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: widget.isPassword && _hidden,
    autocorrect:
        !widget.isPassword && widget.keyboardType != TextInputType.emailAddress,
    enableSuggestions: !widget.isPassword,
    keyboardType: widget.keyboardType,
    textCapitalization: widget.keyboardType == TextInputType.name
        ? TextCapitalization.words
        : TextCapitalization.none,
    textInputAction: widget.textInputAction,
    autofillHints: widget.autofillHints,
    validator: widget.validator,
    onFieldSubmitted: widget.onFieldSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: Icon(widget.icon, size: 20, color: AppColors.muted),
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip:
                  '${_hidden ? 'Show' : 'Hide'} ${widget.label.toLowerCase()}',
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.muted,
              ),
            )
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5DCD4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
      ),
    ),
  );
}
