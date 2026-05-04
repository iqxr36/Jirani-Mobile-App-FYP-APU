import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors(status);
    return Chip(
      label: Text(_label(status)),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      backgroundColor: bg,
      side: BorderSide(color: fg.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
    );
  }

  static String _label(String value) {
    switch (value) {
      case AppConstants.itemStatusAvailable:
        return 'Available';
      case AppConstants.itemStatusUnavailable:
        return 'Unavailable';
      case AppConstants.itemStatusBorrowed:
        return 'Borrowed';
      case AppConstants.itemStatusArchived:
        return 'Archived';
      default:
        return value.isEmpty ? 'Unknown' : value;
    }
  }

  static (Color, Color) _colors(String value) {
    switch (value) {
      case AppConstants.itemStatusAvailable:
        return (Colors.green.shade800, Colors.green.shade50);
      case AppConstants.itemStatusUnavailable:
        return (Colors.orange.shade800, Colors.orange.shade50);
      case AppConstants.itemStatusBorrowed:
        return (Colors.blue.shade800, Colors.blue.shade50);
      case AppConstants.itemStatusArchived:
        return (Colors.grey.shade800, Colors.grey.shade200);
      default:
        return (Colors.grey.shade800, Colors.grey.shade100);
    }
  }
}
