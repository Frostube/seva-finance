import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(color: AppTheme.darkGreen),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.darkGreen.withOpacity(0.5),
        ),
        prefixIcon: prefixIcon != null
          ? IconTheme(
              data: IconThemeData(
                color: enabled 
                  ? AppTheme.darkGreen
                  : AppTheme.darkGreen.withOpacity(0.5),
              ),
              child: prefixIcon!,
            )
          : null,
        filled: true,
        fillColor: enabled 
          ? Colors.white.withOpacity(0.9)
          : Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.darkGreen, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
} 