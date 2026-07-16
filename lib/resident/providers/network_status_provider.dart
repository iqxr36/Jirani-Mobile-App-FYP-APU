import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jirani/shared/services/internet_connectivity_checker.dart';

// Connectivity feature: describes whether the app should allow normal network-backed screens.
enum NetworkStatus { unknown, online, offline }

// Connectivity feature: combines OS connectivity and HTTP probes so the app can show the offline gate reliably.
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

  // Connectivity feature: starts OS listener and periodic internet probes.
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

  // Connectivity feature: treats no network interface as offline and otherwise confirms internet access with probes.
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

  // Connectivity feature: runs an explicit internet check and updates online/offline UI state.
  Future<bool> refresh({bool silent = false}) async {
    if (_isRefreshing) return isOnline;

    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    final previousStatus = _status;
    final osResults = await _checkConnectivity();
    final hasNetworkInterface = InternetConnectivityChecker.hasNetworkInterface(
      osResults,
    );
    final hasInternet =
        hasNetworkInterface &&
        await _connectivityChecker.check(connectivityResults: osResults);
    if (!hasNetworkInterface) {
      _consecutiveProbeFailures = 0;
      _status = NetworkStatus.offline;
    } else if (hasInternet) {
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

  // Connectivity feature: requires repeated failed probes before declaring the device fully offline.
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
