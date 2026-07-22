import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/services/firebase_auth_service.dart';

void main() {
  group('AuthRepository Google sign-in', () {
    test('returns cancelled when the Google picker is closed', () async {
      final fixture = _GoogleFixture(cancelSignIn: true);

      final result = await fixture.repository.signInWithGoogle();

      expect(result.status, GoogleSignInStatus.cancelled);
      expect(result.user, isNull);
      expect(fixture.finalizerCalls, 0);
    });

    test('returns registrationRequired when users/{uid} is absent', () async {
      final fixture = _GoogleFixture();

      final result = await fixture.repository.signInWithGoogle();

      expect(result.status, GoogleSignInStatus.registrationRequired);
      expect(result.user, isNull);
      final userDoc = await fixture.firestore
          .collection('users')
          .doc(fixture.user.uid)
          .get();
      expect(userDoc.exists, isFalse);
    });

    test('returns the existing resident without finalizing again', () async {
      final fixture = _GoogleFixture();
      final resident = _resident(uid: fixture.user.uid);
      await fixture.firestore
          .collection(AppConstants.usersCollection)
          .doc(fixture.user.uid)
          .set(resident.toMap());

      final result = await fixture.repository.signInWithGoogle();

      expect(result.status, GoogleSignInStatus.existingResident);
      expect(result.user?.uid, fixture.user.uid);
      expect(fixture.finalizerCalls, 0);
    });

    test('completion writes one resident profile and is idempotent', () async {
      final fixture = _GoogleFixture();
      await fixture.repository.signInWithGoogle();

      final first = await fixture.repository.completeGoogleRegistration(
        firstName: 'Google',
        lastName: 'Resident',
        phoneNumber: '+60 12-345 6789',
        termsAccepted: true,
        communityId: 'community-1',
        communityName: 'One South',
      );
      final second = await fixture.repository.completeGoogleRegistration(
        firstName: 'Changed',
        lastName: 'Name',
        phoneNumber: '+60199999999',
        termsAccepted: true,
        communityId: 'community-2',
        communityName: 'Other Community',
      );

      expect(first.uid, fixture.user.uid);
      expect(second.firstName, 'Google');
      expect(fixture.finalizerCalls, 1);
      expect(fixture.lastPayload?['phoneNumber'], '+60123456789');
      expect(fixture.lastPayload?['termsAccepted'], isTrue);
    });

    test('completion rejects incomplete fields before finalizing', () async {
      final fixture = _GoogleFixture();

      Future<AppUser> complete({
        String firstName = 'Google',
        String phoneNumber = '+60123456789',
        bool termsAccepted = true,
        String communityId = 'community-1',
      }) {
        return fixture.repository.completeGoogleRegistration(
          firstName: firstName,
          lastName: 'Resident',
          phoneNumber: phoneNumber,
          termsAccepted: termsAccepted,
          communityId: communityId,
          communityName: 'One South',
        );
      }

      await expectLater(complete(firstName: ''), throwsA(isA<Exception>()));
      await expectLater(
        complete(phoneNumber: '0123456789'),
        throwsA(isA<Exception>()),
      );
      await expectLater(complete(communityId: ''), throwsA(isA<Exception>()));
      await expectLater(
        complete(termsAccepted: false),
        throwsA(isA<Exception>()),
      );
      expect(fixture.finalizerCalls, 0);
    });

    test(
      'rejects an administrator account without creating a resident',
      () async {
        final fixture = _GoogleFixture();
        await fixture.firestore
            .collection(AppConstants.adminsCollection)
            .doc(fixture.user.uid)
            .set({'uid': fixture.user.uid, 'role': 'communityAdmin'});

        await expectLater(
          fixture.repository.signInWithGoogle(),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('administrator'),
            ),
          ),
        );
        expect(fixture.finalizerCalls, 0);
      },
    );
  });
}

class _GoogleFixture {
  _GoogleFixture({bool cancelSignIn = false})
    : user = MockUser(
        uid: 'google-user',
        email: 'resident@example.com',
        displayName: 'Google Resident',
        photoURL: 'https://example.com/avatar.png',
      ),
      firestore = FakeFirebaseFirestore() {
    firebaseAuth = MockFirebaseAuth(signedIn: !cancelSignIn, mockUser: user);
    authService = _GoogleAuthService(
      firebaseAuth,
      user,
      cancelSignIn: cancelSignIn,
    );
    repository = AuthRepository(
      authService: authService,
      firestore: firestore,
      registrationEligibilityCheck: (_) async {},
      residentRegistrationFinalizer: (payload) async {
        finalizerCalls++;
        lastPayload = Map<String, dynamic>.from(payload);
        final resident = _resident(
          uid: user.uid,
          firstName: payload['firstName'] as String,
          lastName: payload['lastName'] as String,
          phoneNumber: payload['phoneNumber'] as String,
          communityId: payload['communityId'] as String,
          communityName: payload['communityName'] as String,
        );
        await firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(resident.toMap());
      },
    );
  }

  final MockUser user;
  final FakeFirebaseFirestore firestore;
  late final MockFirebaseAuth firebaseAuth;
  late final _GoogleAuthService authService;
  late final AuthRepository repository;
  int finalizerCalls = 0;
  Map<String, dynamic>? lastPayload;
}

class _GoogleAuthService extends FirebaseAuthService {
  _GoogleAuthService(
    this.firebaseAuth,
    this.googleUser, {
    this.cancelSignIn = false,
  }) : super(firebaseAuth: firebaseAuth);

  final MockFirebaseAuth firebaseAuth;
  final MockUser googleUser;
  final bool cancelSignIn;

  @override
  User? get currentUser => firebaseAuth.currentUser;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (cancelSignIn) return null;
    return _UserCredential(googleUser);
  }

  @override
  Future<void> reloadCurrentUser() async {}
}

class _UserCredential implements UserCredential {
  const _UserCredential(this.user);

  @override
  final User user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AppUser _resident({
  required String uid,
  String firstName = 'Existing',
  String lastName = 'Resident',
  String phoneNumber = '+60123456789',
  String communityId = 'community-1',
  String communityName = 'One South',
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
