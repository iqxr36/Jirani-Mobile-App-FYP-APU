// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_settings_view_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/resident/screens/legal/legal_document_view.dart';
import 'package:jirani/resident/screens/profile/resident_settings_view.dart';

void main() {
  testWidgets('invokes help and support navigation callback', (tester) async {
    var helpTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ResidentSettingsView(
          darkTheme: false,
          onDarkThemeChanged: (_) {},
          onPushNotifications: () {},
          onPrivacy: () {},
          onPaymentMethods: () {},
          onHelp: () => helpTapped = true,
          onDeleteAccount: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Help & Support'), 300);
    await tester.tap(find.text('Help & Support'));
    expect(helpTapped, isTrue);
  });

  testWidgets('danger zone exposes delete account action', (tester) async {
    var deleteTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ResidentSettingsView(
          darkTheme: false,
          onDarkThemeChanged: (_) {},
          onPushNotifications: () {},
          onPrivacy: () {},
          onPaymentMethods: () {},
          onHelp: () {},
          onDeleteAccount: () => deleteTapped = true,
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Delete Account'), 300);
    expect(find.text('Danger Zone'), findsOneWidget);
    await tester.tap(find.text('Delete Account'));
    expect(deleteTapped, isTrue);
  });

  testWidgets('opens community guidelines and terms from settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResidentSettingsView(
          darkTheme: false,
          onDarkThemeChanged: (_) {},
          onPushNotifications: () {},
          onPrivacy: () {},
          onPaymentMethods: () {},
          onHelp: () {},
          onDeleteAccount: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Community Guidelines'), 250);
    await tester.tap(find.text('Community Guidelines'));
    await tester.pumpAndSettle();
    expect(find.byType(JiraniLegalDocumentView), findsOneWidget);
    expect(find.text('1. Be respectful'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Terms of Service'), 250);
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(find.text('1. Account eligibility and accuracy'), findsOneWidget);
  });
}
