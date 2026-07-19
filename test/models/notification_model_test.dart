// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notification_model_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,29-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/notification_model.dart';

void main() {
  test('parses verification and report notification metadata', () {
    final notification = NotificationModel.fromMap('n1', {
      'userId': 'admin-1',
      'type': AppConstants.notificationTypeVerificationOcrMatched,
      'title': 'OCR matched resident details',
      'body': 'Admin approval is still required.',
      'read': false,
      'createdAt': DateTime(2026, 6, 28),
      'verificationRequestId': 'request-1',
      'residentId': 'resident-1',
      'reportId': 'report-1',
      'communityId': 'community-1',
      'ocrDecision': 'ocr_matched',
    });

    expect(notification.verificationRequestId, 'request-1');
    expect(notification.residentId, 'resident-1');
    expect(notification.reportId, 'report-1');
    expect(notification.communityId, 'community-1');
    expect(notification.ocrDecision, 'ocr_matched');
    expect(notification.displayCategory, 'Verification');
  });
}
