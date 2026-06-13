import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/data/repositories/connection_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';

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
  List<AppUser> _communityResidents = const <AppUser>[];
  List<ConnectionModel> _connections = const <ConnectionModel>[];
  List<ConnectionModel> _incomingRequests = const <ConnectionModel>[];
  List<ConnectionModel> _outgoingRequests = const <ConnectionModel>[];

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<AppUser> get communityResidents => _communityResidents;
  List<ConnectionModel> get connections => _connections;
  List<ConnectionModel> get incomingRequests => _incomingRequests;
  List<ConnectionModel> get outgoingRequests => _outgoingRequests;
  int get incomingRequestCount => _incomingRequests.length;

  List<AppUser> get acceptedNeighbors {
    final uid = _currentUser?.uid;
    if (uid == null) return const <AppUser>[];
    return _connections
        .map((connection) => userById(connection.otherUserId(uid)))
        .whereType<AppUser>()
        .toList(growable: false);
  }

  void watchForUser(AppUser? user) {
    if (user?.uid == _currentUser?.uid) return;
    _currentUser = user;
    _cancelSubscriptions();

    if (user == null) {
      _communityResidents = const <AppUser>[];
      _connections = const <ConnectionModel>[];
      _incomingRequests = const <ConnectionModel>[];
      _outgoingRequests = const <ConnectionModel>[];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _residentsSub = _repository.watchCommunityResidents(user).listen((
      residents,
    ) {
      _communityResidents = residents;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleStreamError);
    _connectionsSub = _repository.watchMyConnections(user.uid).listen((
      connections,
    ) {
      _connections = connections;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleStreamError);
    _incomingSub = _repository.watchIncomingRequests(user.uid).listen((
      requests,
    ) {
      _incomingRequests = requests;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleStreamError);
    _outgoingSub = _repository.watchOutgoingRequests(user.uid).listen((
      requests,
    ) {
      _outgoingRequests = requests;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleStreamError);
  }

  AppUser? userById(String uid) {
    for (final user in _communityResidents) {
      if (user.uid == uid) return user;
    }
    return null;
  }

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

  String? connectionStatus(String userId) {
    return connectionWith(userId)?.status;
  }

  bool isConnected(String userId) {
    return connectionStatus(userId) == AppConstants.connectionAccepted;
  }

  bool hasIncomingRequest(String userId) {
    final uid = _currentUser?.uid;
    final connection = connectionWith(userId);
    return uid != null &&
        connection?.status == AppConstants.connectionPending &&
        connection?.toUserId == uid;
  }

  bool hasOutgoingRequest(String userId) {
    final uid = _currentUser?.uid;
    final connection = connectionWith(userId);
    return uid != null &&
        connection?.status == AppConstants.connectionPending &&
        connection?.fromUserId == uid;
  }

  Future<void> sendRequest(AppUser targetUser) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.sendRequest(fromUser: current, toUser: targetUser),
    );
  }

  Future<void> acceptRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.acceptRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  Future<void> declineRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.declineRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  Future<void> withdrawRequest(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.withdrawRequest(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  Future<void> removeConnection(ConnectionModel connection) async {
    final current = _requireCurrentUser();
    await _runAction(
      () => _repository.removeConnection(
        connectionId: connection.id,
        currentUserId: current.uid,
      ),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  AppUser _requireCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('You must be signed in to manage connections.');
    }
    return user;
  }

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

  void _handleStreamError(Object error) {
    _errorMessage = error.toString();
    _isLoading = false;
    notifyListeners();
  }

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
