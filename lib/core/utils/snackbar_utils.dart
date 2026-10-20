import 'package:flutter/material.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: const Color(0xFF388E3C));
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, backgroundColor: const Color(0xFFD32F2F));
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, backgroundColor: const Color(0xFFF57C00));
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, backgroundColor: const Color(0xFF1976D2));
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
