import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/public_profile_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';

/// Connections service: manages resident connection requests and same-community neighbor streams.
class ConnectionService {
  ConnectionService({
    FirebaseFirestore? firestore,
    PublicProfileRepository? publicProfileRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _publicProfiles = publicProfileRepository ?? PublicProfileRepository();

  final FirebaseFirestore _firestore;
  final PublicProfileRepository _publicProfiles;

  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection(AppConstants.connectionsCollection);

  /// Connections feature: creates a pending connection request between two verified residents in the same community.
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
      // Connection notifications are created server-side by Cloud Functions.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to send request. You may already be connected, or Firebase rules need to be deployed.',
        );
      }
      rethrow;
    }
  }

  /// Connections feature: recipient accepts a pending request and unlocks connection/chat surfaces.
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

  /// Connections feature: recipient declines a pending request.
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

  /// Connections feature: sender withdraws their own pending request.
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

  /// Connections feature: either connected resident can remove an accepted connection.
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

  /// Community change cleanup: removes connections that no longer belong to the resident's selected community.
  Future<void> removeConnectionsOutsideCommunity({
    required String uid,
    required String communityId,
  }) async {
    final targetCommunityId = communityId.trim();
    final snapshot = await _connections
        .where('participants', arrayContains: uid)
        .get();

    final batch = _firestore.batch();
    var hasDeletes = false;
    for (final doc in snapshot.docs) {
      final connection = ConnectionModel.fromMap(doc.id, doc.data());
      if (connection.communityId != targetCommunityId) {
        batch.delete(doc.reference);
        hasDeletes = true;
      }
    }

    if (hasDeletes) {
      await batch.commit();
    }
  }

  /// Connections feature: streams verified residents in the current user's community.
  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    return _publicProfiles.watchVerifiedCommunityResidents(currentUser);
  }

  /// Connections feature: streams accepted connections for the current resident.
  Stream<List<ConnectionModel>> watchMyConnections(AppUser currentUser) {
    return _watchConnections(
      _connections
          .where('participants', arrayContains: currentUser.uid)
          .where('status', isEqualTo: AppConstants.connectionAccepted),
      communityId: currentUser.communityId,
    );
  }

  /// Connections feature: streams pending requests sent to the current resident.
  Stream<List<ConnectionModel>> watchIncomingRequests(AppUser currentUser) {
    return _watchConnections(
      _connections
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: AppConstants.connectionPending),
      communityId: currentUser.communityId,
    );
  }

  /// Connections feature: streams pending requests sent by the current resident.
  Stream<List<ConnectionModel>> watchOutgoingRequests(AppUser currentUser) {
    return _watchConnections(
      _connections
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: AppConstants.connectionPending),
      communityId: currentUser.communityId,
    );
  }

  /// Connections feature: applies community filtering and sorting to connection query streams.
  Stream<List<ConnectionModel>> _watchConnections(
    Query<Map<String, dynamic>> query, {
    required String communityId,
  }) {
    final targetCommunityId = communityId.trim();
    return query.snapshots().map((snapshot) {
      final connections = snapshot.docs
          .map((doc) => ConnectionModel.fromMap(doc.id, doc.data()))
          .where((connection) => connection.communityId == targetCommunityId)
          .toList(growable: false);
      connections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return connections;
    });
  }

  /// Connections feature: validates recipient ownership before accepting or declining a pending request.
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
    // Acceptance notifications are created server-side by Cloud Functions.
  }

  /// Connections security: ensures residents are verified, distinct, and in the same community.
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
}
