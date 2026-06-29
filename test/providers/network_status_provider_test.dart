import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jirani/resident/providers/network_status_provider.dart';
import 'package:jirani/shared/services/internet_connectivity_checker.dart';

void main() {
  group('NetworkStatusProvider', () {
    final probeUris = <Uri>[
      Uri.https('primary.example.com', '/status'),
      Uri.https('fallback.example.com', '/status'),
    ];

    NetworkStatusProvider createProvider({
      required FutureOr<http.Response> Function(http.Request) handler,
      int offlineFailureThreshold = 3,
      Duration timeout = const Duration(milliseconds: 50),
      Future<List<ConnectivityResult>> Function()? checkConnectivity,
      Stream<List<ConnectivityResult>>? connectivityStream,
    }) {
      final checker = InternetConnectivityChecker(
        client: MockClient((request) async => handler(request)),
        probeUris: probeUris,
        timeout: timeout,
        checkConnectivity:
            checkConnectivity ??
            () async => [ConnectivityResult.wifi],
      );

      return NetworkStatusProvider(
        connectivityChecker: checker,
        offlineFailureThreshold: offlineFailureThreshold,
        startMonitoring: false,
        checkConnectivity:
            checkConnectivity ??
            () async => [ConnectivityResult.wifi],
        connectivityStream: connectivityStream ?? const Stream.empty(),
      );
    }

    test('starts unknown with connectivity gate hidden before any refresh', () {
      final provider = createProvider(
        handler: (_) => http.Response('', 204),
      );
      addTearDown(provider.dispose);

      expect(provider.status, NetworkStatus.unknown);
      expect(provider.shouldShowConnectivityGate, isFalse);
      expect(provider.isCheckingConnection, isFalse);
    });

    test('reports online when any probe succeeds in parallel', () async {
      final provider = createProvider(handler: (_) => http.Response('', 204));
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isTrue);
      expect(provider.status, NetworkStatus.online);
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
      expect(provider.shouldShowConnectivityGate, isFalse);
    });

    test('uses a fallback probe when the first probe fails', () async {
      final requestedHosts = <String>{};
      final provider = createProvider(
        handler: (request) {
          requestedHosts.add(request.url.host);
          if (request.url.host == 'primary.example.com') {
            throw http.ClientException('primary blocked');
          }

          return http.Response('', 204);
        },
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isTrue);
      expect(provider.status, NetworkStatus.online);
      expect(
        requestedHosts,
        containsAll(['primary.example.com', 'fallback.example.com']),
      );
    });

    test('keeps gate hidden after one failed probe with default threshold', () async {
      final provider = createProvider(
        handler: (_) => throw http.ClientException('network down'),
        offlineFailureThreshold: 3,
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.unknown);
      expect(provider.isOffline, isFalse);
      expect(provider.shouldShowConnectivityGate, isFalse);
    });

    test('reports offline immediately when OS connectivity is none', () async {
      final provider = createProvider(
        handler: (_) => http.Response('', 204),
        checkConnectivity: () async => [ConnectivityResult.none],
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.offline);
      expect(provider.shouldShowConnectivityGate, isTrue);
    });

    test('keeps gate hidden after one failed probe when threshold is 2', () async {
      final provider = createProvider(
        handler: (_) => throw http.ClientException('network down'),
        offlineFailureThreshold: 2,
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.unknown);
      expect(provider.isCheckingConnection, isFalse);
      expect(provider.shouldShowConnectivityGate, isFalse);
      expect(provider.isOffline, isFalse);
    });

    test('reports offline after repeated failed probe cycles', () async {
      final provider = createProvider(
        handler: (_) => throw http.ClientException('network down'),
        offlineFailureThreshold: 2,
      );
      addTearDown(provider.dispose);

      await provider.refresh();
      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.offline);
      expect(provider.isOffline, isTrue);
    });

    test(
      'does not switch from online to offline after one failed cycle when threshold is 2',
      () async {
        var shouldFail = false;
        final provider = createProvider(
          handler: (_) {
            if (shouldFail) {
              throw http.ClientException('temporary outage');
            }

            return http.Response('', 204);
          },
          offlineFailureThreshold: 2,
        );
        addTearDown(provider.dispose);

        await provider.refresh();
        shouldFail = true;
        final isOnline = await provider.refresh();

        expect(isOnline, isTrue);
        expect(provider.status, NetworkStatus.online);
        expect(provider.isOffline, isFalse);
      },
    );

    test('returns online again after a successful refresh', () async {
      var shouldFail = true;
      final provider = createProvider(
        handler: (_) {
          if (shouldFail) {
            throw http.ClientException('network down');
          }

          return http.Response('', 204);
        },
      );
      addTearDown(provider.dispose);

      await provider.refresh();
      await provider.refresh();
      await provider.refresh();
      expect(provider.status, NetworkStatus.offline);

      shouldFail = false;
      final isOnline = await provider.refresh();

      expect(isOnline, isTrue);
      expect(provider.status, NetworkStatus.online);
      expect(provider.isOffline, isFalse);
    });

    test('treats probe timeouts as failed probes', () async {
      final provider = createProvider(
        handler: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return http.Response('', 204);
        },
        timeout: const Duration(milliseconds: 1),
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.unknown);
      expect(provider.shouldShowConnectivityGate, isFalse);
    });
  });
}
