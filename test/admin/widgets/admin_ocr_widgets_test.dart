import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_ocr_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/verification_request.dart';

void main() {
  group('AdminOcrResultView', () {
    testWidgets('shows confidence for backend utility bill fields', (
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
        ocrText: 'Utility Provider: TNB',
        extractedFields: const {
          'utility_issuer_or_provider': ExtractedVerificationField(
            value: 'TNB',
            confidence: 0.91,
            source: 'gemini',
          ),
          'total_amount': ExtractedVerificationField(
            value: 'RM 128.40',
            confidence: 0.7,
            source: 'gemini',
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminOcrResultView(request: request)),
        ),
      );

      expect(find.textContaining('Utility Provider'), findsOneWidget);
      expect(find.text('Confidence 91%'), findsOneWidget);
      expect(find.text('Confidence 70%'), findsOneWidget);
    });

    testWidgets('shows access card fields and full extracted text', (
      tester,
    ) async {
      final request = VerificationRequest(
        id: 'request-2',
        userId: 'user-1',
        fullName: 'Om Khalil',
        email: 'omkhalil@gmail.com',
        phoneNumber: '+60197888597',
        documentType: AppConstants.documentTypeAccessCard,
        documentUrl: 'https://example.com/card.png',
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
        ocrText: 'Lift access card C-5-6',
        extractedFields: const {
          'resident_name': ExtractedVerificationField(
            value: 'Om Khalil',
            confidence: 0.88,
            source: 'gemini',
          ),
          'card_number': ExtractedVerificationField(
            value: '2452718904',
            confidence: 0.82,
            source: 'gemini',
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminOcrResultView(request: request)),
        ),
      );

      expect(find.textContaining('Resident Name'), findsOneWidget);
      expect(find.textContaining('Card Number'), findsOneWidget);
      expect(find.text('FULL EXTRACTED TEXT'), findsOneWidget);
      expect(find.text('Lift access card C-5-6'), findsOneWidget);
    });

    testWidgets('shows manual-review mismatch checks from backend', (
      tester,
    ) async {
      final request = VerificationRequest(
        id: 'request-3',
        userId: 'user-1',
        fullName: 'Faisal Ahmed',
        email: 'faisalahmed@gmail.com',
        phoneNumber: '+60197888597',
        documentType: AppConstants.documentTypeTenancyAgreement,
        documentUrl: 'https://example.com/tenancy.pdf',
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
        ocrText: 'Tenant: Nur Aisyah. Unit A-18-07.',
        extractedFields: const {
          'tenant_name': ExtractedVerificationField(
            value: 'Nur Aisyah binti Hassan',
            confidence: 1,
            source: 'gemini',
          ),
          'unit_number': ExtractedVerificationField(
            value: 'A-18-07',
            confidence: 1,
            source: 'gemini',
          ),
        },
        autoVerification: const AutoVerificationResult(
          eligible: false,
          decision: 'manual_review',
          reasons: [
            'Extracted document name does not contain the resident first name.',
            'Extracted document unit/address does not match the resident unit.',
          ],
          checks: {
            'firstNameMatch': AutoVerificationCheck(
              passed: false,
              expected: 'Faisal',
              actual: 'Nur Aisyah binti Hassan',
              source: 'tenant_name',
            ),
            'lastNameMatch': AutoVerificationCheck(
              passed: false,
              expected: 'Ahmed',
              actual: 'Nur Aisyah binti Hassan',
              source: 'tenant_name',
            ),
            'unitMatch': AutoVerificationCheck(
              passed: false,
              expected: 'C-5-6',
              actual: 'A-18-07',
              source: 'unit_number',
            ),
            'communityObserved': AutoVerificationCheck(
              passed: false,
              expected: 'One South Residence',
              actual: 'Vista Harmoni',
              source: 'property_address',
            ),
            'emailObserved': AutoVerificationCheck(
              passed: true,
              expected: 'faisalahmed@gmail.com',
              skipped: true,
            ),
            'phoneObserved': AutoVerificationCheck(
              passed: true,
              expected: '60197888597',
              skipped: true,
            ),
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminOcrResultView(request: request)),
        ),
      );

      expect(find.text('Manual review required'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.textContaining('Faisal', findRichText: true), findsOneWidget);
      expect(find.textContaining('A-18-07'), findsWidgets);
      expect(
        find.textContaining('One South Residence', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
