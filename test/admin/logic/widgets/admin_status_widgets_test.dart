import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';

void main() {
  group('AdminAvatar', () {
    testWidgets('renders memory preview before remote image', (tester) async {
      await tester.pumpWidget(
        _avatarHost(
          AdminAvatar(
            name: 'Admin User',
            imageUrl: 'https://example.com/avatar.jpg',
            previewBytes: Uint8List.fromList(_transparentPngBytes),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('renders remote image when URL is present', (tester) async {
      await tester.pumpWidget(
        _avatarHost(
          const AdminAvatar(
            name: 'Admin User',
            imageUrl: 'https://example.com/avatar.jpg',
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('calls error callback when remote image builder fails', (
      tester,
    ) async {
      Object? reportedError;
      await tester.pumpWidget(
        _avatarHost(
          AdminAvatar(
            name: 'Admin User',
            imageUrl: 'https://example.com/avatar.jpg',
            onImageError: (error) => reportedError = error,
          ),
        ),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final fallback = image.errorWidget!(
        tester.element(find.byType(CachedNetworkImage)),
        'https://example.com/avatar.jpg',
        Exception('network failed'),
      );
      await tester.pump();

      expect(reportedError, isA<Exception>());
      expect(fallback, isA<CircleAvatar>());
    });
  });
}

const _transparentPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

Widget _avatarHost(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
