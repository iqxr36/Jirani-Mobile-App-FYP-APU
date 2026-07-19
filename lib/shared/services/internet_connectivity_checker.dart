// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : internet_connectivity_checker.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

final defaultInternetProbeUris = <Uri>[
  Uri.https('www.gstatic.com', '/generate_204'),
  Uri.https('one.one.one.one', '/cdn-cgi/trace'),
  Uri.https('firestore.googleapis.com', '/'),
];

/// Returns true when the device has a network interface and can reach the internet.
Future<bool> hasInternetAccess({
  Connectivity? connectivity,
  http.Client? client,
  List<Uri>? probeUris,
  Duration timeout = const Duration(seconds: 2),
  Future<List<ConnectivityResult>> Function()? checkConnectivity,
}) {
  return InternetConnectivityChecker(
    connectivity: connectivity,
    client: client,
    probeUris: probeUris,
    timeout: timeout,
    checkConnectivity: checkConnectivity,
  ).check();
}

class InternetConnectivityChecker {
  InternetConnectivityChecker({
    Connectivity? connectivity,
    http.Client? client,
    List<Uri>? probeUris,
    Duration timeout = const Duration(seconds: 2),
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
  }) : _connectivity = connectivity ?? Connectivity(),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _probeUris = List<Uri>.unmodifiable(
         probeUris ?? defaultInternetProbeUris,
       ),
       _timeout = timeout {
    _checkConnectivity =
        checkConnectivity ?? () => _connectivity.checkConnectivity();
  }

  final Connectivity _connectivity;
  final http.Client _client;
  final bool _ownsClient;
  final List<Uri> _probeUris;
  final Duration _timeout;
  late final Future<List<ConnectivityResult>> Function() _checkConnectivity;

  static bool hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> check({List<ConnectivityResult>? connectivityResults}) async {
    final osResults = connectivityResults ?? await _checkConnectivity();
    if (!hasNetworkInterface(osResults)) {
      return false;
    }

    final probeResults = await Future.wait(_probeUris.map(_canReachProbe));
    return probeResults.contains(true);
  }

  Future<bool> _canReachProbe(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } on Object {
      return false;
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
