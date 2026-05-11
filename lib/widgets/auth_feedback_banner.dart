import 'package:flutter/material.dart';

/// Success / error banners matching [ForgotPasswordView] styling.
class AuthFeedbackBanner {
  AuthFeedbackBanner._();

  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);

  static Widget success(String message) {
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: successGreen.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: successGreen,
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget failure(String message) {
    return Container(
      constraints: const BoxConstraints(minHeight: 57),
      decoration: BoxDecoration(
        color: errorRed.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(7),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: errorRed,
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.2,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
