// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_status_widgets_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,10-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';

void main() {
  group('Admin filters', () {
    testWidgets('dropdown shows its label and reports selected values', (
      tester,
    ) async {
      var selected = 'all';

      await tester.pumpWidget(
        _filterHost(
          StatefulBuilder(
            builder: (context, setState) {
              return AdminFilterDropdown<String>(
                label: 'Type',
                value: selected,
                values: const {
                  'all': 'All types',
                  'borrow': 'Borrow',
                  'service': 'Task Service',
                },
                onChanged: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      );

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('All types'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrow').last);
      await tester.pumpAndSettle();

      expect(selected, 'borrow');
      expect(find.text('Borrow'), findsOneWidget);
    });

    testWidgets('chip without a callback is genuinely disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _filterHost(const AdminFilterChipButton(label: 'Priority')),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('dropdown keeps a 48dp minimum interactive height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _filterHost(
          AdminFilterDropdown<String>(
            label: 'Status',
            value: 'all',
            values: const {'all': 'All statuses'},
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AdminFilterDropdown<String>)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('control bar filters wrap without overflow', (tester) async {
      for (final size in const [Size(375, 700), Size(1440, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdminControlBar(
                title: 'Transactions Monitoring',
                subtitle: 'Ledger filters',
                controls: [
                  AdminFilterDropdown<String>(
                    label: 'Date range',
                    value: 'all',
                    values: const {'all': 'All time'},
                    onChanged: (_) {},
                  ),
                  AdminFilterDropdown<String>(
                    label: 'Type',
                    value: 'all',
                    values: const {'all': 'All types'},
                    onChanged: (_) {},
                  ),
                  AdminFilterDropdown<String>(
                    label: 'Status',
                    value: 'all',
                    values: const {'all': 'All statuses'},
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

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

    testWidgets('keeps image preview inside a square oval clip after rebuild', (
      tester,
    ) async {
      final previewBytes = Uint8List.fromList(_transparentPngBytes);

      await tester.pumpWidget(
        _avatarHost(
          AdminAvatar(name: 'Admin User', previewBytes: previewBytes),
        ),
      );
      await tester.pumpWidget(
        _avatarHost(
          AdminAvatar(
            name: 'Admin User',
            imageUrl: 'https://example.com/avatar.jpg',
            previewBytes: previewBytes,
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      final clipFinder = find.ancestor(
        of: imageFinder,
        matching: find.byType(ClipOval),
      );
      final shellFinder = find.descendant(
        of: clipFinder,
        matching: find.byType(SizedBox),
      );

      expect(clipFinder, findsOneWidget);
      final shell = tester.widget<SizedBox>(shellFinder.first);
      expect(shell.width, 36);
      expect(shell.height, 36);
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

Widget _filterHost(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}
