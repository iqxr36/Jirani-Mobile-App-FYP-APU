import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/widgets/community_change_warning_dialog.dart';

void main() {
  group('CommunityChangeWarningDialog', () {
    testWidgets('shows verification rows for verified residents', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityChangeWarningDialog(
              communityName: 'Community B',
              isVerifiedResident: true,
              onCancel: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );

      expect(find.text('Verification will reset'), findsOneWidget);
      expect(find.text('Documents must be submitted again'), findsOneWidget);
      expect(find.text('Neighbor connections will be removed'), findsOneWidget);
      expect(
        find.text('Previous chats will no longer be available'),
        findsOneWidget,
      );
    });

    testWidgets('hides verification rows for pending residents', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityChangeWarningDialog(
              communityName: 'Community B',
              isVerifiedResident: false,
              onCancel: () {},
              onConfirm: () {},
            ),
          ),
        ),
      );

      expect(find.text('Verification will reset'), findsNothing);
      expect(find.text('Documents must be submitted again'), findsNothing);
      expect(find.text('Neighbor connections will be removed'), findsOneWidget);
      expect(
        find.text('Previous chats will no longer be available'),
        findsOneWidget,
      );
    });

    testWidgets('invokes cancel and confirm callbacks', (tester) async {
      var cancelled = false;
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityChangeWarningDialog(
              communityName: 'Community B',
              isVerifiedResident: false,
              onCancel: () => cancelled = true,
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Keep Current'));
      await tester.pump();

      expect(cancelled, isTrue);
      expect(confirmed, isFalse);

      cancelled = false;
      await tester.tap(find.text('Change Community'));
      await tester.pump();

      expect(confirmed, isTrue);
      expect(cancelled, isFalse);
    });
  });
}
