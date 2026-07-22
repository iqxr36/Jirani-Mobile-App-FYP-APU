import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/screens/auth/google_registration_completion_view.dart';
import 'package:jirani/resident/screens/auth/resident_registration_ui.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/logic/auth_wrapper.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AuthWrapper routes an incomplete Google user to registration', (
    tester,
  ) async {
    final repository = _GoogleRegistrationRepository();
    final viewModel = AuthViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp(
          home: AuthWrapper(
            isWebOverride: false,
            googleRegistrationBuilder: (_) =>
                const Scaffold(body: Text('google-registration-route')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(viewModel.needsGoogleRegistration, isTrue);
    expect(find.text('google-registration-route'), findsOneWidget);
    expect(find.textContaining('profile not found'), findsNothing);
  });

  testWidgets(
    'completion form prefills Google data and submits resident fields',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _GoogleRegistrationRepository();
      final viewModel = AuthViewModel.forTesting(repository: repository);
      await viewModel.signInWithGoogle();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: MaterialApp(
            home: GoogleRegistrationCompletionView(
              communityReader: _CommunityReader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstName = tester.widget<TextFormField>(
        find.byKey(const Key('google-registration-first-name')),
      );
      final lastName = tester.widget<TextFormField>(
        find.byKey(const Key('google-registration-last-name')),
      );
      expect(firstName.controller?.text, 'Google');
      expect(lastName.controller?.text, 'Resident');
      expect(find.text('resident@example.com'), findsOneWidget);
      expect(find.byType(ResidentRegistrationFormCard), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('google-registration-phone')),
        '+60 12-345 6789',
      );
      await tester.tap(find.byKey(const Key('google-registration-community')));
      await tester.pumpAndSettle();
      expect(find.text('Select Your Community'), findsOneWidget);
      expect(find.text('Available partner communities'), findsOneWidget);
      expect(find.text('One South'), findsOneWidget);
      expect(find.text('Kuala Lumpur'), findsOneWidget);
      await tester.tap(find.text('One South'));
      await tester.pumpAndSettle();
      expect(find.text('One South'), findsOneWidget);
      final termsFinder = find.descendant(
        of: find.byKey(const Key('google-registration-terms')),
        matching: find.byType(CheckboxListTile),
      );
      final terms = tester.widget<CheckboxListTile>(termsFinder);
      terms.onChanged?.call(true);
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(termsFinder).value, isTrue);
      await tester.tap(find.byKey(const Key('google-registration-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Select your community to continue.'), findsNothing);
      expect(find.text('Phone number is required.'), findsNothing);
      expect(repository.completionCalls, 1);
      expect(repository.submittedPhone, '+60 12-345 6789');
      expect(repository.submittedCommunityId, 'community-1');
      expect(viewModel.needsGoogleRegistration, isFalse);
      expect(viewModel.showAccountCreatedScreen, isTrue);
      expect(viewModel.currentUser?.uid, repository.firebaseUser.uid);
    },
  );
}

class _GoogleRegistrationRepository implements AuthRepository {
  _GoogleRegistrationRepository()
    : firebaseUser = MockUser(
        uid: 'google-user',
        email: 'resident@example.com',
        displayName: 'Google Resident',
        providerData: const [_GoogleProviderInfo()],
      );

  final MockUser firebaseUser;
  int completionCalls = 0;
  String? submittedPhone;
  String? submittedCommunityId;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(firebaseUser);

  @override
  User? get currentFirebaseUser => firebaseUser;

  @override
  Future<GoogleSignInResult> signInWithGoogle() async {
    return const GoogleSignInResult.registrationRequired();
  }

  @override
  Future<AppUser?> getCurrentAppUser() async => null;

  @override
  Future<AppUser> completeGoogleRegistration({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required bool termsAccepted,
    required String communityId,
    required String communityName,
  }) async {
    completionCalls++;
    submittedPhone = phoneNumber;
    submittedCommunityId = communityId;
    return _resident(
      uid: firebaseUser.uid,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      communityId: communityId,
      communityName: communityName,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class _GoogleProviderInfo implements UserInfo {
  const _GoogleProviderInfo();

  @override
  String get providerId => 'google.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CommunityReader implements CommunityReader {
  @override
  Future<List<CommunityModel>> fetchActiveCommunities() async {
    return const [_testCommunity];
  }
}

const _testCommunity = CommunityModel(
  communityId: 'community-1',
  name: 'One South',
  centerLocation: GeoPoint(3.0, 101.0),
  radiusInMeters: 500,
  isActive: true,
  city: 'Kuala Lumpur',
);

AppUser _resident({
  required String uid,
  required String firstName,
  required String lastName,
  required String phoneNumber,
  required String communityId,
  required String communityName,
}) {
  final now = DateTime(2026, 7, 21);
  return AppUser(
    uid: uid,
    firstName: firstName,
    lastName: lastName,
    email: 'resident@example.com',
    phoneNumber: phoneNumber,
    emailVerified: true,
    phoneVerified: false,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: communityId,
    communityName: communityName,
    unitNumber: '',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: false,
    createdAt: now,
    updatedAt: now,
  );
}
