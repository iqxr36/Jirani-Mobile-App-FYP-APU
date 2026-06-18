import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum NetworkStatus { unknown, online, offline }

class NetworkStatusProvider extends ChangeNotifier {
  NetworkStatusProvider({
    http.Client? client,
    List<Uri>? probeUris,
    Duration checkInterval = _defaultCheckInterval,
    Duration timeout = _defaultTimeout,
    int offlineFailureThreshold = _defaultOfflineFailureThreshold,
    bool startMonitoring = true,
  }) : assert(offlineFailureThreshold > 0),
       _client = client ?? http.Client(),
       _probeUris = List<Uri>.unmodifiable(probeUris ?? _defaultProbeUris),
       _timeout = timeout,
       _offlineFailureThreshold = offlineFailureThreshold {
    if (startMonitoring) {
      unawaited(refresh(silent: true));
      _timer = Timer.periodic(
        checkInterval,
        (_) => unawaited(refresh(silent: true)),
      );
    }
  }

  static const _defaultCheckInterval = Duration(seconds: 20);
  static const _defaultTimeout = Duration(seconds: 5);
  static const _defaultOfflineFailureThreshold = 2;
  static final _defaultProbeUris = <Uri>[
    Uri.https('www.gstatic.com', '/generate_204'),
    Uri.https('one.one.one.one', '/cdn-cgi/trace'),
    Uri.https('firestore.googleapis.com', '/'),
  ];

  final http.Client _client;
  final List<Uri> _probeUris;
  final Duration _timeout;
  final int _offlineFailureThreshold;
  Timer? _timer;

  NetworkStatus _status = NetworkStatus.unknown;
  bool _isRefreshing = false;
  int _consecutiveProbeFailures = 0;

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
    if (await _canReachAnyProbe()) {
      _consecutiveProbeFailures = 0;
      return NetworkStatus.online;
    }

    _consecutiveProbeFailures += 1;
    if (_consecutiveProbeFailures < _offlineFailureThreshold) {
      return _status;
    }

    return NetworkStatus.offline;
  }

  Future<bool> _canReachAnyProbe() async {
    for (final uri in _probeUris) {
      if (await _canReachProbe(uri)) return true;
    }

    return false;
  }

  Future<bool> _canReachProbe(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } on Object {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
