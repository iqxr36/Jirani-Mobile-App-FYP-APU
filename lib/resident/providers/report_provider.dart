// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : report_provider.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/services/report_service.dart';

// Report feature: submits resident reports to the admin reports inbox.
class ReportProvider extends ChangeNotifier {
  ReportProvider({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  bool _busy = false;
  bool get isSubmitting => _busy;

  // Report feature: creates a marketplace/report document with the involved users and item/request context.
  Future<void> createReport({
    required String type,
    required String relatedBorrowRequestId,
    required String itemId,
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required String title,
    required String description,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.createReport(
        type: type,
        relatedBorrowRequestId: relatedBorrowRequestId,
        itemId: itemId,
        reporterId: reporterId,
        reporterName: reporterName,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        title: title,
        description: description,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
