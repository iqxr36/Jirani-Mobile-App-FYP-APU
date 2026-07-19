// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : connection_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/shared/services/connection_service.dart';

// Neighbor connection data layer: exposes connection use cases while ConnectionService owns Firestore writes.
class ConnectionRepository {
  ConnectionRepository({ConnectionService? service})
    : _service = service ?? ConnectionService();

  final ConnectionService _service;

  // Neighbor connection feature: sends a pending connection request between two residents.
  Future<void> sendRequest({
    required AppUser fromUser,
    required AppUser toUser,
  }) {
    return _service.sendRequest(fromUser: fromUser, toUser: toUser);
  }

  // Neighbor connection feature: accepts an incoming connection request.
  Future<void> acceptRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.acceptRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  // Neighbor connection feature: declines an incoming connection request.
  Future<void> declineRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.declineRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  // Neighbor connection feature: withdraws an outgoing pending request.
  Future<void> withdrawRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.withdrawRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  // Neighbor connection feature: removes an accepted neighbor connection.
  Future<void> removeConnection({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.removeConnection(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  // Geofence/community feature: cleans up connections outside the resident's selected community.
  Future<void> removeConnectionsOutsideCommunity({
    required String uid,
    required String communityId,
  }) {
    return _service.removeConnectionsOutsideCommunity(
      uid: uid,
      communityId: communityId,
    );
  }

  // Neighbor directory feature: streams verified residents in the same community.
  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    return _service.watchCommunityResidents(currentUser);
  }

  // Neighbor connection feature: streams accepted connections for the current resident.
  Stream<List<ConnectionModel>> watchMyConnections(AppUser currentUser) {
    return _service.watchMyConnections(currentUser);
  }

  // Neighbor connection feature: streams pending requests sent to the current resident.
  Stream<List<ConnectionModel>> watchIncomingRequests(AppUser currentUser) {
    return _service.watchIncomingRequests(currentUser);
  }

  // Neighbor connection feature: streams pending requests sent by the current resident.
  Stream<List<ConnectionModel>> watchOutgoingRequests(AppUser currentUser) {
    return _service.watchOutgoingRequests(currentUser);
  }
}
