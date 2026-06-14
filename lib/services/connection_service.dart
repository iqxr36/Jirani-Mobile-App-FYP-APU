import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';

class ConnectionService {
  ConnectionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection(AppConstants.connectionsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<void> sendRequest({
    required AppUser fromUser,
    required AppUser toUser,
  }) async {
    _validateParticipants(fromUser: fromUser, toUser: toUser);

    final id = ConnectionModel.connectionId(fromUser.uid, toUser.uid);
    final doc = _connections.doc(id);
    final now = FieldValue.serverTimestamp();

    try {
      await doc.set({
        'fromUserId': fromUser.uid,
        'toUserId': toUser.uid,
        'participants': <String>[fromUser.uid, toUser.uid],
        'communityId': fromUser.communityId,
        'status': AppConstants.connectionPending,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to send request. You may already be connected, or Firebase rules need to be deployed.',
        );
      }
      rethrow;
    }
  }

  Future<void> acceptRequest({
    required String connectionId,
    required String currentUserId,
  }) async {
    await _updatePendingRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
      targetStatus: AppConstants.connectionAccepted,
      mustBeRecipient: true,
    );
  }

  Future<void> declineRequest({
    required String connectionId,
    required String currentUserId,
  }) async {
    await _updatePendingRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
      targetStatus: AppConstants.connectionDeclined,
      mustBeRecipient: true,
    );
  }

  Future<void> withdrawRequest({
    required String connectionId,
    required String currentUserId,
  }) async {
    final doc = _connections.doc(connectionId);
    final snap = await doc.get();
    final data = snap.data();
    if (!snap.exists || data == null) return;

    final connection = ConnectionModel.fromMap(snap.id, data);
    if (connection.fromUserId != currentUserId || !connection.isPending) {
      throw Exception('Only the sender can withdraw a pending request.');
    }

    await doc.delete();
  }

  Future<void> removeConnection({
    required String connectionId,
    required String currentUserId,
  }) async {
    final doc = _connections.doc(connectionId);
    final snap = await doc.get();
    final data = snap.data();
    if (!snap.exists || data == null) return;

    final connection = ConnectionModel.fromMap(snap.id, data);
    if (!connection.participants.contains(currentUserId) ||
        !connection.isAccepted) {
      throw Exception('Only connected residents can remove this connection.');
    }

    await doc.delete();
  }

  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    return _users
        .where('communityId', isEqualTo: currentUser.communityId)
        .where('role', isEqualTo: AppConstants.roleResident)
        .where(
          'verificationStatus',
          isEqualTo: AppConstants.verificationVerified,
        )
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => _userFromDoc(doc))
              .where(
                (user) =>
                    user.uid != currentUser.uid &&
                    user.isResident &&
                    user.isVerifiedResident,
              )
              .toList(growable: false);
          users.sort((a, b) => a.fullName.compareTo(b.fullName));
          return users;
        });
  }

  Stream<List<ConnectionModel>> watchMyConnections(String uid) {
    return _watchConnections(
      _connections
          .where('participants', arrayContains: uid)
          .where('status', isEqualTo: AppConstants.connectionAccepted),
    );
  }

  Stream<List<ConnectionModel>> watchIncomingRequests(String uid) {
    return _watchConnections(
      _connections
          .where('toUserId', isEqualTo: uid)
          .where('status', isEqualTo: AppConstants.connectionPending),
    );
  }

  Stream<List<ConnectionModel>> watchOutgoingRequests(String uid) {
    return _watchConnections(
      _connections
          .where('fromUserId', isEqualTo: uid)
          .where('status', isEqualTo: AppConstants.connectionPending),
    );
  }

  Stream<List<ConnectionModel>> _watchConnections(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map((snapshot) {
      final connections = snapshot.docs
          .map((doc) => ConnectionModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
      connections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return connections;
    });
  }

  Future<void> _updatePendingRequest({
    required String connectionId,
    required String currentUserId,
    required String targetStatus,
    required bool mustBeRecipient,
  }) async {
    final doc = _connections.doc(connectionId);
    final snap = await doc.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw Exception('Connection request no longer exists.');
    }

    final connection = ConnectionModel.fromMap(snap.id, data);
    if (!connection.isPending) {
      throw Exception('Only pending connection requests can be updated.');
    }
    if (mustBeRecipient && connection.toUserId != currentUserId) {
      throw Exception('Only the recipient can respond to this request.');
    }

    await doc.update({
      'status': targetStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateParticipants({
    required AppUser fromUser,
    required AppUser toUser,
  }) {
    if (fromUser.uid == toUser.uid) {
      throw Exception('You cannot connect with yourself.');
    }
    if (!fromUser.isVerifiedResident || !toUser.isVerifiedResident) {
      throw Exception('Only verified residents can connect.');
    }
    if (fromUser.communityId.isEmpty ||
        fromUser.communityId != toUser.communityId) {
      throw Exception('Connections are only available within your community.');
    }
  }

  AppUser _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppUser.fromMap({...data, 'uid': data['uid'] ?? doc.id});
  }
}
