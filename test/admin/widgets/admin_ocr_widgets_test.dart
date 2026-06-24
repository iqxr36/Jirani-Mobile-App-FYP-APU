import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_ocr_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/verification_request.dart';

void main() {
  group('AdminOcrResultView', () {
    testWidgets('shows confidence for parsed utility bill fields', (
      tester,
    ) async {
      final request = VerificationRequest(
        id: 'request-1',
        userId: 'user-1',
        fullName: 'Om Khalil',
        email: 'omkhalil@gmail.com',
        phoneNumber: '+60197888597',
        documentType: AppConstants.documentTypeUtilityBill,
        documentUrl: 'https://example.com/bill.pdf',
        communityId: 'community-1',
        communityName: 'One South Residence',
        unitNumber: 'C-5-6',
        notes: '',
        status: AppConstants.verificationSubmitted,
        rejectionReason: null,
        submittedAt: DateTime(2026, 6, 18),
        reviewedAt: null,
        reviewedBy: null,
        ocrStatus: AppConstants.ocrStatusCompleted,
        ocrText: '''
Utility Provider: TNB
Utility Type: Electricity
Account Number: 1234567890
Bill Holder Name: Om Khalil
Service Address: C-5-6 One South Residence
Bill Date: 2026-06-09
Due Date: 2026-06-30
Total Amount: RM 128.40
''',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminOcrResultView(request: request)),
        ),
      );

      expect(find.textContaining('Utility Provider'), findsOneWidget);
      expect(find.text('Confidence 100%'), findsWidgets);
    });
  });
}
