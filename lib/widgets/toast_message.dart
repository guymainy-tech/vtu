// lib/widgets/toast_message.dart
import 'package:flutter/material.dart';

class ToastMessage {
  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
                ? Colors.red
                : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}