import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/verification_access.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';

// Neighbor connection feature: manages resident directory, connection requests, and accepted neighbor state.
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider({ConnectionRepository? repository})
    : _repository = repository ?? ConnectionRepository();

  final ConnectionRepository _repository;

  StreamSubscription<List<AppUser>>? _residentsSub;
  StreamSubscription<List<ConnectionModel>>? _connectionsSub;
  StreamSubscription<List<ConnectionModel>>? _incomingSub;
  StreamSubscription<List<ConnectionModel>>? _outgoingSub;

  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  final Map<String, String> _streamErrors = <String, String>{};
  List<AppUser> _communityResidents = const <AppUser>[];
  List<ConnectionModel> _connections = const <ConnectionModel>[];
  List<ConnectionModel> _incomingRequests = const <ConnectionModel>[];
  List<ConnectionModel> _outgoingRequests = const <ConnectionModel>[];

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get communityResidentsError => _streamErrors['communityResidents'];
  String? get connectionsError => _streamErrors['myConnections'];
  String? get incomingRequestsError => _streamErrors['incomingRequests'];
  String? get outgoingRequestsError => _streamErrors['outgoingRequests'];
  List<AppUser> get communityResidents => _communityResidents;
  List<ConnectionModel> get connections => _connections;
  List<ConnectionModel> get incomingRequests => _incomingRequests;
  List<ConnectionModel> get outgoingRequests => _outgoingRequests;
  int get incomingRequestCount => _incomingRequests.length;

  // Neighbor connection feature: converts accepted connection records into the neighbor profiles shown in the UI.
  List<AppUser> get acceptedNeighbors {
    final uid = _currentUser?.uid;
    if (uid == null) return const <AppUser>[];
    return _connections
        .map((connection) => userById(connection.otherUserId(uid)))
        .whereType<AppUser>()
        .toList(growable: false);
  }

  // Neighbor connection feature: starts all resident/connection streams for the signed-in resident's community.
  void watchForUser(AppUser? user, {bool force = false}) {
    final sameUser = user?.uid == _currentUser?.uid;
    final sameCommunity = user?.communityId == _currentUser?.communityId;
    final sameAccess =
        residentCanStartProtectedListeners(user) ==
        residentCanStartProtectedListeners(_currentUser);
    if (!force && sameUser && sameCommunity && sameAccess) return;
    _currentUser = user;
    _cancelSubscriptions();

    if (user == null) {
      _resetState();
      notifyListeners();
      return;
    }

    if (!residentCanStartProtectedListeners(user)) {
      _resetState();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _residentsSub = _repository.watchCommunityResidents(user).listen((
      residents,
    ) {
      _clearStreamError('communityResidents');
      _communityResidents = residents;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) => _handleStreamError('communityResidents', error));
    _connectionsSub = _repository.watchMyConnections(user).listen((
      connections,
    ) {
      _clearStreamError('myConnections');
      _connections = connections;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) => _handleStreamError('myConnections', error));
    _incomingSub = _repository.watchIncomingRequests(user).listen((requests) {
      _clearStreamError('incomingRequests');
      _incomingRequests = requests;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) => _handleStreamError('incomingRequests', error));
    _outgoingSub = _repository.watchOutgoingRequests(user).listen((requests) {
      _clearStreamError('outgoingRequests');
      _outgoingRequests = requests;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) => _handleStreamError('outgoingRequests', error));
  }

  // Neighbor connection feature: finds a community resident profile already loaded from the directory stream.
  AppUser? userById(String uid) {
    for (final user in _communityResidents) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  // Neighbor connection feature: finds the request/connection record between the current resident and another user.
  ConnectionModel? connectionWith(String userId) {
    final uid = _currentUser?.uid;
    if (uid == null) return null;
    final id = ConnectionModel.connectionId(uid, userId);
    for (final connection in [
      ..._connections,
      ..._incomingRequests,
      ..._outgoingRequests,
    ]) {
      if (connection.id == id) return connection;
    }
    return null;
  }

  // Neighbor connection feature: returns pending/accepted status for the profile action buttons.
  String? connectionStatus(String userId) {
    return connectionWith(userId)?.status;
  }

  // Neighbor connection feature: tells screens whether messaging/profile actions should be enabled.
  bool isConnected(String userId) {
    return connectionStatus(userId) == AppConstants.connectionAccepted;
  }

  // Neighbor connection feature: detects whether the other resident is waiting for the current user to accept.
  bool hasIncomingRequest(String userId) {
    final uid = _currentUser?.uid;
    final connection = connectionWith(userId);
    return uid != null &&
        connection?.status == AppConstants.connectionPending &&
        connection?.toUserId == uid;
  }

  // Neighbor connection feature: detects whether the current user already sent a pending request.
  bool hasOutgoingRequest(String userId) {
    final uid = _currentUser?.uid;
    final connection = connectionWith(userId);
    return uid != null &&
        connection?.status == AppConstants.connectionPending &&
        connection?.fromUserId == uid;
  }

  // Neighbor connection feature: sends a connection request to another verified resident.
  Future<void> sendRequest(AppUser targetUser) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.sendRequest(fromUser: current, toUser: targetUser),
    );
  }

  // Neighbor connection feature: accepts an incoming connection request.
  Future<void> acceptRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.acceptRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  // Neighbor connection feature: declines an incoming connection request.
  Future<void> declineRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.declineRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  // Neighbor connection feature: cancels an outgoing pending connection request.
  Future<void> withdrawRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.withdrawRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  // Neighbor connection feature: removes an accepted neighbor connection.
  Future<void> removeConnection(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.removeConnection(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  // Neighbor connection UI state: clears stream/action errors shown on resident screens.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Neighbor connection feature: prevents connection writes when no resident is signed in.
  AppUser _requireCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('You must be signed in to manage connections.');
    }
    return user;
  }

  // Neighbor connection UI state: wraps request actions with submitting and error flags.
  Future<void> _runAction(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Neighbor connection UI state: stores which realtime stream failed so the page can show a useful error.
  void _handleStreamError(String streamName, Object error) {
    final message = error.toString();
    _streamErrors[streamName] = message;
    _refreshErrorMessage();
    _isLoading = false;
    notifyListeners();
  }

  // Neighbor connection UI state: removes a stream error after that stream successfully emits again.
  void _clearStreamError(String streamName) {
    if (!_streamErrors.containsKey(streamName)) return;
    _streamErrors.remove(streamName);
    _refreshErrorMessage();
  }

  // Neighbor connection UI state: exposes the first active stream error through the shared error getter.
  void _refreshErrorMessage() {
    _errorMessage = _streamErrors.isEmpty ? null : _streamErrors.values.first;
  }

  // Neighbor connection feature: clears resident/connection state when the user signs out or lacks access.
  void _resetState() {
    _communityResidents = const <AppUser>[];
    _connections = const <ConnectionModel>[];
    _incomingRequests = const <ConnectionModel>[];
    _outgoingRequests = const <ConnectionModel>[];
    _streamErrors.clear();
    _isLoading = false;
    _errorMessage = null;
  }

  // Neighbor connection feature: stops resident/connection listeners when the signed-in user changes.
  void _cancelSubscriptions() {
    _residentsSub?.cancel();
    _connectionsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _residentsSub = null;
    _connectionsSub = null;
    _incomingSub = null;
    _outgoingSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
