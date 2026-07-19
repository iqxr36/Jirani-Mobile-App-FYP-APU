// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_directory_exporter_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/export/resident_directory_exporter.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  group('ResidentDirectoryExporter', () {
    late ResidentDirectoryExporter exporter;
    late List<AppUser> residents;

    setUp(() {
      exporter = ResidentDirectoryExporter(
        exportedAt: DateTime(2026, 7, 11, 13, 30),
        communityName: 'Palm Grove',
        filterSummary: 'verification=Verified',
      );
      residents = [_resident()];
    });

    test('maps resident rows with display labels', () {
      final rows = exporter.mapRows(residents);
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Jane Resident');
      expect(rows.first.email, 'jane@example.com');
      expect(rows.first.verification, isNotEmpty);
      expect(rows.first.accountStatus, isNotEmpty);
    });

    test('json export includes metadata and residents array', () async {
      final bytes = await exporter.exportBytes(
        format: ResidentExportFormat.json,
        residents: residents,
      );
      final decoded =
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(decoded['recordCount'], 1);
      expect(decoded['communityName'], 'Palm Grove');
      expect(decoded['filterSummary'], 'verification=Verified');
      expect(decoded['residents'], isA<List<dynamic>>());
      expect((decoded['residents'] as List).first, containsPair('Name', 'Jane Resident'));
    });

    test('json export supports empty resident list', () async {
      final bytes = await exporter.exportBytes(
        format: ResidentExportFormat.json,
        residents: const [],
      );
      final decoded =
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(decoded['recordCount'], 0);
      expect(decoded['residents'], isEmpty);
    });

    test('xlsx export produces zip workbook bytes', () async {
      final bytes = await exporter.exportBytes(
        format: ResidentExportFormat.xlsx,
        residents: residents,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(2)), 'PK');

      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Residents'];
      expect(sheet, isNotNull);
      expect(sheet!.rows.length, greaterThan(1));
      expect(sheet.rows[0][0]?.value, TextCellValue('Name'));
      expect(sheet.rows[1][0]?.value, TextCellValue('Jane Resident'));
    });

    test('xlsx export supports empty resident list', () async {
      final bytes = await exporter.exportBytes(
        format: ResidentExportFormat.xlsx,
        residents: const [],
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(2)), 'PK');

      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Residents'];
      expect(sheet, isNotNull);
      expect(sheet!.rows, hasLength(1));
      expect(sheet.rows[0][0]?.value, TextCellValue('Name'));
    });

    test('pdf export produces pdf bytes', () async {
      final bytes = await exporter.exportBytes(
        format: ResidentExportFormat.pdf,
        residents: residents,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('filename and mime type helpers match format', () {
      expect(
        exporter.filenameFor(ResidentExportFormat.xlsx),
        'jirani-residents-20260711-1330.xlsx',
      );
      expect(
        exporter.mimeTypeFor(ResidentExportFormat.pdf),
        'application/pdf',
      );
      expect(exporter.formatLabel(ResidentExportFormat.json), 'JSON');
    });
  });
}

AppUser _resident() {
  final now = DateTime(2026, 7, 11, 13, 30);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Jane',
    lastName: 'Resident',
    email: 'jane@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationVerified,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'Palm Grove',
    unitNumber: 'B-12-03',
    reputationScore: 4.5,
    totalReviews: 3,
    communityTrustScore: 82.5,
    completedBorrowings: 1,
    completedLendings: 2,
    completedServices: 1,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}
