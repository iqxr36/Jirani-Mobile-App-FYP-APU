import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/suspension_duration.dart';
import 'package:jirani/admin/screens/users/admin_residents_screen.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  testWidgets('admin chooses suspension duration and enters a reason', (
    tester,
  ) async {
    AdminSuspensionResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<AdminSuspensionResult>(
                  context: context,
                  builder: (_) => AdminSuspensionDialog(resident: _resident()),
                );
              },
              child: const Text('Open suspension'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open suspension'));
    await tester.pumpAndSettle();
    expect(find.text('Suspension duration'), findsOneWidget);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 days').last);
    await tester.enterText(
      find.byType(TextField),
      'Repeated violation of the community guidelines.',
    );
    await tester.tap(find.text('Suspend account'));
    await tester.pumpAndSettle();

    expect(result?.duration, SuspensionDuration.thirtyDays);
    expect(result?.reason, 'Repeated violation of the community guidelines.');
  });
}

AppUser _resident() {
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
    'termsAccepted': true,
    'locationVerified': true,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  });
}
