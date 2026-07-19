// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_repository_registration_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/services/firebase_auth_service.dart';

void main() {
  group('AuthRepository resident registration', () {
    late MockFirebaseAuth firebaseAuth;
    late _RecordingAuthService authService;
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firebaseAuth = MockFirebaseAuth();
      authService = _RecordingAuthService(firebaseAuth);
      firestore = FakeFirebaseFirestore();
    });

    test(
      'creates the Firebase session before finalizing without a pre-auth phone check',
      () async {
        final events = <String>[];
        var phoneAvailabilityCalls = 0;
        final repository = AuthRepository(
          authService: authService,
          firestore: firestore,
          registrationEligibilityCheck: (email) async {
            events.add('eligibility');
          },
          phoneAvailabilityCheck: (phone, excludeUid) async {
            phoneAvailabilityCalls++;
            throw StateError(
              'Registration must not call the signed-in phone check.',
            );
          },
          residentRegistrationFinalizer: (payload) async {
            expect(authService.currentUser, isNotNull);
            events.add('finalize');
          },
        );

        final user = await repository.register(
          firstName: 'Test',
          lastName: 'Resident',
          email: 'new.resident@example.com',
          phoneNumber: '+60123456789',
          password: 'StrongPass1!',
          termsAccepted: true,
          communityId: 'community-1',
          communityName: 'One South',
        );

        expect(events, ['eligibility', 'finalize']);
        expect(phoneAvailabilityCalls, 0);
        expect(authService.createCalls, 1);
        expect(authService.verificationSendCalls, 1);
        expect(user.email, 'new.resident@example.com');
      },
    );

    test('removes the new Auth account when finalization rejects the phone', () async {
      final repository = AuthRepository(
        authService: authService,
        firestore: firestore,
        registrationEligibilityCheck: (_) async {},
        residentRegistrationFinalizer: (_) async {
          throw FirebaseFunctionsException(
            code: 'already-exists',
            message:
                'This phone number is already registered to another account.',
          );
        },
      );

      await expectLater(
        repository.register(
          firstName: 'Test',
          lastName: 'Resident',
          email: 'duplicate.phone@example.com',
          phoneNumber: '+60123456789',
          password: 'StrongPass1!',
          termsAccepted: true,
          communityId: 'community-1',
          communityName: 'One South',
        ),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'already-exists',
          ),
        ),
      );

      expect(authService.deleteCalls, 1);
      expect(authService.currentUser, isNull);
      expect(authService.verificationSendCalls, 0);
    });
  });
}

class _RecordingAuthService extends FirebaseAuthService {
  _RecordingAuthService(this.firebaseAuth) : super(firebaseAuth: firebaseAuth);

  final MockFirebaseAuth firebaseAuth;
  int createCalls = 0;
  int deleteCalls = 0;
  int verificationSendCalls = 0;

  @override
  User? get currentUser => firebaseAuth.currentUser;

  @override
  bool get isEmailVerified => firebaseAuth.currentUser?.emailVerified ?? false;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    createCalls++;
    return super.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> deleteCurrentUser() async {
    deleteCalls++;
    await firebaseAuth.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationSendCalls++;
  }
}
