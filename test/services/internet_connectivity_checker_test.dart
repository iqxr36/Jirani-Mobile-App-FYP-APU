import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jirani/shared/services/internet_connectivity_checker.dart';

void main() {
  group('InternetConnectivityChecker', () {
    final probeUris = <Uri>[
      Uri.https('primary.example.com', '/status'),
      Uri.https('fallback.example.com', '/status'),
    ];

    InternetConnectivityChecker createChecker({
      required FutureOr<http.Response> Function(http.Request) handler,
      Duration timeout = const Duration(milliseconds: 50),
      Future<List<ConnectivityResult>> Function()? checkConnectivity,
    }) {
      final checker = InternetConnectivityChecker(
        client: MockClient((request) async => handler(request)),
        probeUris: probeUris,
        timeout: timeout,
        checkConnectivity:
            checkConnectivity ??
            () async => [ConnectivityResult.wifi],
      );
      addTearDown(checker.dispose);
      return checker;
    }

    test('returns false when OS connectivity is none without probing', () async {
      var probeCalled = false;
      final checker = createChecker(
        handler: (_) {
          probeCalled = true;
          return http.Response('', 204);
        },
        checkConnectivity: () async => [ConnectivityResult.none],
      );

      final hasInternet = await checker.check();

      expect(hasInternet, isFalse);
      expect(probeCalled, isFalse);
    });

    test('returns true when OS has wifi and a probe succeeds', () async {
      final checker = createChecker(
        handler: (_) => http.Response('', 204),
      );

      final hasInternet = await checker.check();

      expect(hasInternet, isTrue);
    });

    test('returns false when OS has wifi but all probes fail', () async {
      final checker = createChecker(
        handler: (_) => throw http.ClientException('network down'),
      );

      final hasInternet = await checker.check();

      expect(hasInternet, isFalse);
    });

    test('hasNetworkInterface returns false only for none', () {
      expect(
        InternetConnectivityChecker.hasNetworkInterface(
          [ConnectivityResult.none],
        ),
        isFalse,
      );
      expect(
        InternetConnectivityChecker.hasNetworkInterface(
          [ConnectivityResult.wifi],
        ),
        isTrue,
      );
    });
  });
}
