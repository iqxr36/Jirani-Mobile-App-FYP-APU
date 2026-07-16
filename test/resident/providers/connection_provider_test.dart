import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/providers/connection_provider.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/public_profile_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/shared/services/connection_service.dart';

Future<void> _ensureTestFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
        storageBucket: 'test.appspot.com',
      ),
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(_ensureTestFirebase);

  group('ConnectionProvider.watchForUser', () {
    late FakeConnectionRepository repository;
    late ConnectionProvider provider;

    setUp(() {
      repository = FakeConnectionRepository();
      provider = ConnectionProvider(repository: repository);
    });

    tearDown(() {
      provider.dispose();
      repository.dispose();
    });

    test('does not subscribe for unverified resident', () {
      provider.watchForUser(_resident(verified: false));

      expect(repository.watchCommunityResidentsCalls, 0);
      expect(repository.watchMyConnectionsCalls, 0);
      expect(repository.watchIncomingRequestsCalls, 0);
      expect(repository.watchOutgoingRequestsCalls, 0);
      expect(provider.communityResidents, isEmpty);
      expect(provider.incomingRequestCount, 0);
      expect(provider.isLoading, isFalse);
    });

    test('subscribes for verified resident with full access', () async {
      provider.watchForUser(_resident(verified: true));

      expect(repository.watchCommunityResidentsCalls, 1);
      expect(repository.watchMyConnectionsCalls, 1);
      expect(repository.watchIncomingRequestsCalls, 1);
      expect(repository.watchOutgoingRequestsCalls, 1);

      repository.emitIncomingRequests([
        _incomingRequest(),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.incomingRequestCount, 1);
    });

    test('re-subscribes when verification status changes for same user', () {
      final pending = _resident(verified: false);
      final verified = _resident(verified: true);

      provider.watchForUser(pending);
      expect(repository.watchCommunityResidentsCalls, 0);

      provider.watchForUser(verified);
      expect(repository.watchCommunityResidentsCalls, 1);

      provider.watchForUser(pending);
      expect(repository.watchCommunityResidentsCalls, 1);
      expect(provider.incomingRequestCount, 0);
    });
  });
}

class FakeConnectionRepository extends ConnectionRepository {
  FakeConnectionRepository()
    : super(
        service: ConnectionService(
          firestore: FakeFirebaseFirestore(),
          publicProfileRepository: PublicProfileRepository(
            firestore: FakeFirebaseFirestore(),
          ),
        ),
      );

  int watchCommunityResidentsCalls = 0;
  int watchMyConnectionsCalls = 0;
  int watchIncomingRequestsCalls = 0;
  int watchOutgoingRequestsCalls = 0;

  final _residentsController =
      StreamController<List<AppUser>>.broadcast();
  final _connectionsController =
      StreamController<List<ConnectionModel>>.broadcast();
  final _incomingController =
      StreamController<List<ConnectionModel>>.broadcast();
  final _outgoingController =
      StreamController<List<ConnectionModel>>.broadcast();

  void emitIncomingRequests(List<ConnectionModel> requests) {
    _incomingController.add(requests);
  }

  void dispose() {
    _residentsController.close();
    _connectionsController.close();
    _incomingController.close();
    _outgoingController.close();
  }

  @override
  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    watchCommunityResidentsCalls++;
    return _residentsController.stream;
  }

  @override
  Stream<List<ConnectionModel>> watchMyConnections(AppUser currentUser) {
    watchMyConnectionsCalls++;
    return _connectionsController.stream;
  }

  @override
  Stream<List<ConnectionModel>> watchIncomingRequests(AppUser currentUser) {
    watchIncomingRequestsCalls++;
    return _incomingController.stream;
  }

  @override
  Stream<List<ConnectionModel>> watchOutgoingRequests(AppUser currentUser) {
    watchOutgoingRequestsCalls++;
    return _outgoingController.stream;
  }
}

AppUser _resident({required bool verified}) {
  final now = DateTime(2026, 7, 11);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'test@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: verified
        ? AppConstants.verificationVerified
        : AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'Community',
    unitNumber: 'A-1-1',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

ConnectionModel _incomingRequest() {
  final now = DateTime(2026, 7, 11);
  return ConnectionModel(
    id: 'connection-1',
    fromUserId: 'resident-2',
    toUserId: 'resident-1',
    participants: const ['resident-1', 'resident-2'],
    communityId: 'community-1',
    status: AppConstants.connectionPending,
    createdAt: now,
    updatedAt: now,
  );
}
