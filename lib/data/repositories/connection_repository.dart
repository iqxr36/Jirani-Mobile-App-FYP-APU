import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/services/connection_service.dart';

class ConnectionRepository {
  ConnectionRepository({ConnectionService? service})
    : _service = service ?? ConnectionService();

  final ConnectionService _service;

  Future<void> sendRequest({
    required AppUser fromUser,
    required AppUser toUser,
  }) {
    return _service.sendRequest(fromUser: fromUser, toUser: toUser);
  }

  Future<void> acceptRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.acceptRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  Future<void> declineRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.declineRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  Future<void> withdrawRequest({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.withdrawRequest(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  Future<void> removeConnection({
    required String connectionId,
    required String currentUserId,
  }) {
    return _service.removeConnection(
      connectionId: connectionId,
      currentUserId: currentUserId,
    );
  }

  Future<void> removeConnectionsOutsideCommunity({
    required String uid,
    required String communityId,
  }) {
    return _service.removeConnectionsOutsideCommunity(
      uid: uid,
      communityId: communityId,
    );
  }

  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    return _service.watchCommunityResidents(currentUser);
  }

  Stream<List<ConnectionModel>> watchMyConnections(AppUser currentUser) {
    return _service.watchMyConnections(currentUser);
  }

  Stream<List<ConnectionModel>> watchIncomingRequests(AppUser currentUser) {
    return _service.watchIncomingRequests(currentUser);
  }

  Stream<List<ConnectionModel>> watchOutgoingRequests(AppUser currentUser) {
    return _service.watchOutgoingRequests(currentUser);
  }
}
