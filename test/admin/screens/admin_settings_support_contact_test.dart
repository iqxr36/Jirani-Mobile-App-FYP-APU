// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_settings_support_contact_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/providers/admin_theme_provider.dart';
import 'package:jirani/admin/screens/settings/admin_settings_screen.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/admin_notification_preferences.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/services/community_support_contact_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('loads defaults and saves the public support contact', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final service = CommunitySupportContactService(firestore: firestore);
    await tester.pumpWidget(_harness(admin: _communityAdmin, service: service));
    await tester.pumpAndSettle();

    final name = tester.widget<TextFormField>(
      find.byKey(const Key('support-contact-name')),
    );
    final email = tester.widget<TextFormField>(
      find.byKey(const Key('support-contact-email')),
    );
    final phone = tester.widget<TextFormField>(
      find.byKey(const Key('support-contact-phone')),
    );
    expect(name.controller?.text, _communityAdmin.fullName);
    expect(email.controller?.text, _communityAdmin.email);
    expect(phone.controller?.text, _communityAdmin.phoneNumber);

    await tester.enterText(find.byKey(const Key('support-contact-email')), '');
    tester
        .widget<FilledButton>(find.byKey(const Key('save-support-contact')))
        .onPressed!();
    await tester.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(
      (await firestore
              .collection(AppConstants.communitySupportContactsCollection)
              .doc('community-1')
              .get())
          .exists,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('support-contact-name')),
      'Resident Support',
    );
    await tester.enterText(
      find.byKey(const Key('support-contact-email')),
      'help@palmgrove.example',
    );
    await tester.enterText(
      find.byKey(const Key('support-contact-phone')),
      '+60 12-345 6789',
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('save-support-contact')),
    );
    saveButton.onPressed!();
    await tester.pumpAndSettle();

    final saved = await firestore
        .collection(AppConstants.communitySupportContactsCollection)
        .doc('community-1')
        .get();
    expect(saved.data()?['contactName'], 'Resident Support');
    expect(saved.data()?['email'], 'help@palmgrove.example');
    expect(saved.data()?['phoneNumber'], '+60123456789');
    expect(find.text('Resident support contact saved.'), findsOneWidget);
  });

  testWidgets('does not show a single-community editor to system admins', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        admin: _communityAdmin.copyWith().letSystemAdmin(),
        service: CommunitySupportContactService(
          firestore: FakeFirebaseFirestore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resident Support Contact'), findsNothing);
  });
}

Widget _harness({
  required AdminUser admin,
  required CommunitySupportContactService service,
}) {
  final auth = AuthViewModel(
    repository: _FakeAuthRepository(),
    userRepository: _FakeUserRepository(),
    connectionRepository: _FakeConnectionRepository(),
    verificationRepository: _FakeVerificationRepository(),
    chatRepository: _FakeChatRepository(),
    listenToAuthChanges: false,
    initialCurrentAdmin: admin,
  );
  final theme = AdminThemeProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: auth),
      ChangeNotifierProvider<AdminThemeProvider>.value(value: theme),
    ],
    child: MaterialApp(
      home: Scaffold(body: AdminSettingsScreen(supportContactService: service)),
    ),
  );
}

extension on AdminUser {
  AdminUser letSystemAdmin() {
    return AdminUser(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: AppConstants.roleSystemAdmin,
      communityId: '',
      communityName: '',
      profileImageUrl: profileImageUrl,
      themePresetId: themePresetId,
      permissions: permissions,
      notificationPreferences: notificationPreferences,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final _communityAdmin = AdminUser(
  uid: 'admin-1',
  fullName: 'Amina Rahman',
  email: 'admin@example.com',
  phoneNumber: '+60123456789',
  role: AppConstants.roleCommunityAdmin,
  communityId: 'community-1',
  communityName: 'Palm Grove',
  profileImageUrl: '',
  themePresetId: 'teal',
  permissions: const <String>[],
  notificationPreferences: AdminNotificationPreferences.defaults,
  isActive: true,
  createdAt: DateTime(2026, 7, 18),
  updatedAt: DateTime(2026, 7, 18),
);

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeConnectionRepository implements ConnectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeVerificationRepository implements VerificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChatRepository implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
