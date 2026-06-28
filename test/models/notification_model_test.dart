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
