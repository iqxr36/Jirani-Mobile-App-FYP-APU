import 'package:flutter/foundation.dart';
import 'package:jirani/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  bool _busy = false;
  bool get isSubmitting => _busy;

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
