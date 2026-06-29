import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jirani/shared/services/internet_connectivity_checker.dart';

enum NetworkStatus { unknown, online, offline }

class NetworkStatusProvider extends ChangeNotifier {
  NetworkStatusProvider({
    http.Client? client,
    List<Uri>? probeUris,
    Duration checkInterval = _defaultCheckInterval,
    Duration timeout = _defaultTimeout,
    int offlineFailureThreshold = _defaultOfflineFailureThreshold,
    bool startMonitoring = true,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? connectivityStream,
    InternetConnectivityChecker? connectivityChecker,
  }) : assert(offlineFailureThreshold > 0),
       _offlineFailureThreshold = offlineFailureThreshold,
       _checkInterval = checkInterval,
       _checkConnectivity =
           checkConnectivity ?? Connectivity().checkConnectivity,
       _connectivityStream =
           connectivityStream ?? Connectivity().onConnectivityChanged,
       _connectivityChecker =
           connectivityChecker ??
           InternetConnectivityChecker(
             client: client,
             probeUris: probeUris,
             timeout: timeout,
             checkConnectivity: checkConnectivity,
           ) {
    if (startMonitoring) {
      unawaited(_startMonitoring());
    }
  }

  static const _defaultCheckInterval = Duration(seconds: 60);
  static const _defaultTimeout = Duration(seconds: 5);
  static const _defaultOfflineFailureThreshold = 3;

  final int _offlineFailureThreshold;
  final Duration _checkInterval;
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _connectivityStream;
  final InternetConnectivityChecker _connectivityChecker;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  NetworkStatus _status = NetworkStatus.unknown;
  bool _isRefreshing = false;
  int _consecutiveProbeFailures = 0;

  NetworkStatus get status => _status;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get isOnline => _status == NetworkStatus.online;
  bool get isCheckingConnection => _isRefreshing;
  bool get shouldShowConnectivityGate => _status == NetworkStatus.offline;
  bool get isRefreshing => _isRefreshing;

  Future<void> _startMonitoring() async {
    await _applyOsConnectivity(await _checkConnectivity());
    _connectivitySubscription = _connectivityStream.listen(
      _applyOsConnectivity,
    );
    await refresh(silent: true);
    _timer = Timer.periodic(
      _checkInterval,
      (_) => unawaited(refresh(silent: true)),
    );
  }

  Future<void> _applyOsConnectivity(List<ConnectivityResult> results) async {
    if (!InternetConnectivityChecker.hasNetworkInterface(results)) {
      _consecutiveProbeFailures = 0;
      if (_status != NetworkStatus.offline) {
        _status = NetworkStatus.offline;
        notifyListeners();
      }
      return;
    }

    await refresh(silent: true);
  }

  Future<bool> refresh({bool silent = false}) async {
    if (_isRefreshing) return isOnline;

    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    final previousStatus = _status;
    final hasInternet = await _connectivityChecker.check();
    if (hasInternet) {
      _consecutiveProbeFailures = 0;
      _status = NetworkStatus.online;
    } else {
      _status = await _resolveOfflineStatus();
    }

    if (!silent) {
      _isRefreshing = false;
    }

    if (!silent || previousStatus != _status) {
      notifyListeners();
    }

    return isOnline;
  }

  Future<NetworkStatus> _resolveOfflineStatus() async {
    _consecutiveProbeFailures += 1;
    if (_consecutiveProbeFailures < _offlineFailureThreshold) {
      if (_status == NetworkStatus.online) {
        return NetworkStatus.online;
      }
      return NetworkStatus.unknown;
    }

    return NetworkStatus.offline;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityChecker.dispose();
    super.dispose();
  }
}
