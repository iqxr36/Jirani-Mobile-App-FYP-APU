import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum NetworkStatus { unknown, online, offline }

class NetworkStatusProvider extends ChangeNotifier {
  NetworkStatusProvider({http.Client? client})
    : _client = client ?? http.Client() {
    unawaited(refresh(silent: true));
    _timer = Timer.periodic(
      _checkInterval,
      (_) => unawaited(refresh(silent: true)),
    );
  }

  static const _checkInterval = Duration(seconds: 20);
  static const _timeout = Duration(seconds: 5);
  static final _probeUri = Uri.https('www.gstatic.com', '/generate_204');

  final http.Client _client;
  Timer? _timer;

  NetworkStatus _status = NetworkStatus.unknown;
  bool _isRefreshing = false;

  NetworkStatus get status => _status;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get isOnline => _status == NetworkStatus.online;
  bool get isRefreshing => _isRefreshing;

  Future<bool> refresh({bool silent = false}) async {
    if (_isRefreshing) return isOnline;

    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    final nextStatus = await _probeNetwork();
    final statusChanged = nextStatus != _status;
    _status = nextStatus;

    if (!silent) {
      _isRefreshing = false;
    }

    if (statusChanged || !silent) {
      notifyListeners();
    }

    return isOnline;
  }

  Future<NetworkStatus> _probeNetwork() async {
    try {
      final response = await _client.get(_probeUri).timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 500
          ? NetworkStatus.online
          : NetworkStatus.offline;
    } on Object {
      return NetworkStatus.offline;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
