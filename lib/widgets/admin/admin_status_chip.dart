import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    Color fg = const Color(0xFF3E494A);
    Color bg = const Color(0xFFF1F4F4);
    String label = status;
    if (s == AppConstants.verificationSubmitted) {
      fg = const Color(0xFF00535B);
      bg = const Color(0xFFACEFE7);
      label = 'Submitted';
    } else if (s == AppConstants.verificationVerified) {
      fg = const Color(0xFF006D77);
      bg = const Color(0xFFD6F4F1);
      label = 'Verified';
    } else if (s == AppConstants.verificationRejected) {
      fg = const Color(0xFFBA1A1A);
      bg = const Color(0xFFFFDAD6);
      label = 'Rejected';
    } else if (s == AppConstants.verificationPending) {
      fg = const Color(0xFF7A4A00);
      bg = const Color(0xFFFFE4B8);
      label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
