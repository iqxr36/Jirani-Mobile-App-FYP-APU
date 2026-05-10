import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class BorrowStatusChip extends StatelessWidget {
  const BorrowStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color fg = Colors.grey.shade800;
    Color bg = Colors.grey.shade100;
    String label = status;
    switch (normalized) {
      case AppConstants.borrowStatusPending:
        fg = Colors.orange.shade800;
        bg = Colors.orange.shade50;
        label = 'Pending';
        break;
      case AppConstants.borrowStatusApproved:
        fg = Colors.teal.shade800;
        bg = Colors.teal.shade50;
        label = 'Approved';
        break;
      case AppConstants.borrowStatusRejected:
        fg = Colors.red.shade800;
        bg = Colors.red.shade50;
        label = 'Rejected';
        break;
      case AppConstants.borrowStatusCancelled:
        fg = Colors.grey.shade800;
        bg = Colors.grey.shade200;
        label = 'Cancelled';
        break;
      case AppConstants.borrowStatusPickupReady:
        fg = Colors.blue.shade800;
        bg = Colors.blue.shade50;
        label = 'Pickup ready';
        break;
      case AppConstants.borrowStatusHandedOver:
        fg = Colors.indigo.shade800;
        bg = Colors.indigo.shade50;
        label = 'Handed over';
        break;
      case AppConstants.borrowStatusActive:
        fg = Colors.green.shade800;
        bg = Colors.green.shade50;
        label = 'Active';
        break;
      case AppConstants.borrowStatusReturnSubmitted:
        fg = Colors.deepPurple.shade800;
        bg = Colors.deepPurple.shade50;
        label = 'Return submitted';
        break;
      case AppConstants.borrowStatusCompleted:
        fg = Colors.teal.shade900;
        bg = Colors.teal.shade100;
        label = 'Completed';
        break;
    }
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      backgroundColor: bg,
      side: BorderSide(color: fg.withOpacity(0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}
