// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_help_support_view_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/screens/profile/resident_help_support_view.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_support_contact.dart';
import 'package:jirani/shared/services/community_support_contact_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows contact and launches email and call actions', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      _harness(
        reader: _FakeReader(
          contact: _contact,
        ),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amina Rahman'), findsOneWidget);
    expect(find.text('support@example.com'), findsOneWidget);
    expect(find.text('+60123456789'), findsOneWidget);

    await tester.tap(find.byKey(const Key('email-administrator')));
    await tester.pump();
    expect(launched.single.scheme, 'mailto');
    expect(launched.single.path, 'support@example.com');
    expect(
      launched.single.queryParameters['subject'],
      'Jirani Support Request - Palm Grove',
    );

    await tester.tap(find.byKey(const Key('call-administrator')));
    await tester.pump();
    expect(launched.last, Uri(scheme: 'tel', path: '+60123456789'));
  });

  testWidgets('shows not configured state when no contact exists', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(reader: _FakeReader()));
    await tester.pumpAndSettle();

    expect(find.text('Contact details not configured'), findsOneWidget);
    expect(find.byKey(const Key('email-administrator')), findsNothing);
  });

  testWidgets('shows retry state and recovers after a fetch error', (
    tester,
  ) async {
    final reader = _FakeReader(contact: _contact, failuresRemaining: 1);
    await tester.pumpWidget(_harness(reader: reader));
    await tester.pumpAndSettle();

    expect(find.text('Contact unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Amina Rahman'), findsOneWidget);
  });

  testWidgets('keeps contact visible and explains launcher failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(reader: _FakeReader(contact: _contact), launcher: (_) async => false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('call-administrator')));
    await tester.pump();
    expect(find.text('+60123456789'), findsOneWidget);
    expect(find.textContaining('Calling is not available'), findsOneWidget);
  });
}

Widget _harness({
  required CommunitySupportContactReader reader,
  SupportUriLauncher? launcher,
}) {
  final auth = AuthViewModel(
    repository: _FakeAuthRepository(),
    userRepository: _FakeUserRepository(),
    connectionRepository: _FakeConnectionRepository(),
    verificationRepository: _FakeVerificationRepository(),
    chatRepository: _FakeChatRepository(),
    listenToAuthChanges: false,
    initialCurrentUser: _user,
  );
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: auth,
    child: MaterialApp(
      home: ResidentHelpSupportView(
        contactReader: reader,
        uriLauncher: launcher,
      ),
    ),
  );
}

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

class _FakeReader implements CommunitySupportContactReader {
  _FakeReader({this.contact, this.failuresRemaining = 0});

  final CommunitySupportContact? contact;
  int failuresRemaining;

  @override
  Future<CommunitySupportContact?> fetchForCommunity(String communityId) async {
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw Exception('offline');
    }
    return contact;
  }
}

const _contact = CommunitySupportContact(
  communityId: 'community-1',
  contactName: 'Amina Rahman',
  email: 'support@example.com',
  phoneNumber: '+60123456789',
  updatedBy: 'admin-1',
);

final _user = AppUser(
  uid: 'resident-1',
  firstName: 'Faisal',
  lastName: 'Resident',
  email: 'resident@example.com',
  phoneNumber: '+60111111111',
  emailVerified: true,
  phoneVerified: true,
  role: AppConstants.roleResident,
  verificationStatus: AppConstants.verificationVerified,
  profileImageUrl: '',
  communityId: 'community-1',
  communityName: 'Palm Grove',
  unitNumber: 'A-1-1',
  reputationScore: 0,
  totalReviews: 0,
  completedBorrowings: 0,
  completedLendings: 0,
  completedServices: 0,
  termsAccepted: true,
  locationVerified: true,
  createdAt: DateTime(2026, 7, 18),
  updatedAt: DateTime(2026, 7, 18),
);
