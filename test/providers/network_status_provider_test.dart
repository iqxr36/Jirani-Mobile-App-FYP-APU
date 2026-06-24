import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jirani/resident/providers/network_status_provider.dart';

void main() {
  group('NetworkStatusProvider', () {
    final probeUris = <Uri>[
      Uri.https('primary.example.com', '/status'),
      Uri.https('fallback.example.com', '/status'),
    ];

    NetworkStatusProvider createProvider({
      required FutureOr<http.Response> Function(http.Request) handler,
      int offlineFailureThreshold = 2,
      Duration timeout = const Duration(milliseconds: 50),
    }) {
      return NetworkStatusProvider(
        client: MockClient((request) async => handler(request)),
        probeUris: probeUris,
        timeout: timeout,
        offlineFailureThreshold: offlineFailureThreshold,
        startMonitoring: false,
      );
    }

    test('reports online when the first probe succeeds', () async {
      final provider = createProvider(handler: (_) => http.Response('', 204));
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isTrue);
      expect(provider.status, NetworkStatus.online);
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
    });

    test('uses a fallback probe when the first probe fails', () async {
      final requestedHosts = <String>[];
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
      expect(requestedHosts, ['primary.example.com', 'fallback.example.com']);
    });

    test('keeps status unknown after one failed probe cycle', () async {
      final provider = createProvider(
        handler: (_) => throw http.ClientException('network down'),
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.unknown);
      expect(provider.isOffline, isFalse);
    });

    test('reports offline after repeated failed probe cycles', () async {
      final provider = createProvider(
        handler: (_) => throw http.ClientException('network down'),
      );
      addTearDown(provider.dispose);

      await provider.refresh();
      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.offline);
      expect(provider.isOffline, isTrue);
    });

    test(
      'does not switch from online to offline after one failed cycle',
      () async {
        var shouldFail = false;
        final provider = createProvider(
          handler: (_) {
            if (shouldFail) {
              throw http.ClientException('temporary outage');
            }

            return http.Response('', 204);
          },
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
        offlineFailureThreshold: 1,
        timeout: const Duration(milliseconds: 1),
      );
      addTearDown(provider.dispose);

      final isOnline = await provider.refresh();

      expect(isOnline, isFalse);
      expect(provider.status, NetworkStatus.offline);
    });
  });
}
