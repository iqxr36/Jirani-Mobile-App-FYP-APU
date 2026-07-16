import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/screens/auth/suspended_account_view.dart';
import 'package:jirani/resident/screens/legal/legal_document_view.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  testWidgets('shows suspension return time, reason, and account actions', (
    tester,
  ) async {
    var statusChecks = 0;
    var signOuts = 0;
    final user = _user(
      endsAt: DateTime(2030, 7, 23, 14, 30),
      reason: 'Repeated disrespectful messages.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SuspendedAccountView(
          user: user,
          onCheckStatus: () async => statusChecks++,
          onSignOut: () async => signOuts++,
        ),
      ),
    );

    expect(find.text('Account temporarily suspended'), findsOneWidget);
    expect(find.textContaining('23 July 2030'), findsOneWidget);
    expect(find.text('Repeated disrespectful messages.'), findsOneWidget);

    await tester.tap(find.text('Check account status'));
    await tester.pump();
    expect(statusChecks, 1);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(signOuts, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });

  testWidgets('opens Terms of Service from the suspension screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SuspendedAccountView(
          user: _user(reason: 'Policy review required.'),
          onCheckStatus: () async {},
          onSignOut: () async {},
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Terms of Service'), 250);
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();

    expect(find.byType(JiraniLegalDocumentView), findsOneWidget);
    expect(find.text('1. Account eligibility and accuracy'), findsOneWidget);
  });
}

AppUser _user({DateTime? endsAt, required String reason}) {
  final createdAt = Timestamp.fromDate(DateTime(2026, 1, 1));
  return AppUser.fromMap({
    'uid': 'resident-1',
    'firstName': 'Test',
    'lastName': 'Resident',
    'email': 'resident@example.com',
    'phoneNumber': '+60123456789',
    'role': AppConstants.roleResident,
    'verificationStatus': AppConstants.verificationVerified,
    'communityId': 'community-1',
    'communityName': 'One South',
    'accountStatus': AppConstants.accountStatusSuspended,
    'suspendedReason': reason,
    if (endsAt != null) 'suspensionEndsAt': Timestamp.fromDate(endsAt),
    'termsAccepted': true,
    'locationVerified': true,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  });
}
