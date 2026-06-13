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

  Stream<List<AppUser>> watchCommunityResidents(AppUser currentUser) {
    return _service.watchCommunityResidents(currentUser);
  }

  Stream<List<ConnectionModel>> watchMyConnections(String uid) {
    return _service.watchMyConnections(uid);
  }

  Stream<List<ConnectionModel>> watchIncomingRequests(String uid) {
    return _service.watchIncomingRequests(uid);
  }

  Stream<List<ConnectionModel>> watchOutgoingRequests(String uid) {
    return _service.watchOutgoingRequests(uid);
  }
}
