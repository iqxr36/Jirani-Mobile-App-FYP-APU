import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/utils/display_labels.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum ResidentExportFormat { xlsx, json, pdf }

/// Normalized resident row for admin directory exports.
class ResidentExportRow {
  const ResidentExportRow({
    required this.name,
    required this.email,
    required this.phone,
    required this.community,
    required this.unit,
    required this.verification,
    required this.accountStatus,
    required this.trustScore,
    required this.updated,
  });

  final String name;
  final String email;
  final String phone;
  final String community;
  final String unit;
  final String verification;
  final String accountStatus;
  final String trustScore;
  final String updated;

  static const headers = [
    'Name',
    'Email',
    'Phone',
    'Community',
    'Unit',
    'Verification',
    'Account Status',
    'Trust Score',
    'Updated',
  ];

  List<String> get values => [
    name,
    email,
    phone,
    community,
    unit,
    verification,
    accountStatus,
    trustScore,
    updated,
  ];

  Map<String, String> toJson() => {
    for (var i = 0; i < headers.length; i++) headers[i]: values[i],
  };

  static ResidentExportRow fromAppUser(AppUser resident) {
    return ResidentExportRow(
      name: resident.fullName,
      email: resident.email,
      phone: resident.phoneNumber,
      community: resident.communityName,
      unit: resident.unitNumber,
      verification: adminStatusLabel(resident.verificationStatus),
      accountStatus: accountStatusLabel(resident.accountStatus),
      trustScore: resident.communityTrustScore.toStringAsFixed(1),
      updated: resident.updatedAt.toIso8601String(),
    );
  }
}

/// Builds resident directory exports for the admin portal.
class ResidentDirectoryExporter {
  const ResidentDirectoryExporter({
    this.exportedAt,
    this.communityName,
    this.filterSummary,
  });

  final DateTime? exportedAt;
  final String? communityName;
  final String? filterSummary;

  DateTime get _exportedAt => exportedAt ?? DateTime.now();

  List<ResidentExportRow> mapRows(List<AppUser> residents) {
    return residents.map(ResidentExportRow.fromAppUser).toList(growable: false);
  }

  Future<Uint8List> exportBytes({
    required ResidentExportFormat format,
    required List<AppUser> residents,
  }) async {
    final rows = mapRows(residents);
    return switch (format) {
      ResidentExportFormat.json => _buildJson(rows, residents.length),
      ResidentExportFormat.xlsx => _buildXlsx(rows),
      ResidentExportFormat.pdf => await _buildPdf(rows, residents.length),
    };
  }

  String filenameFor(ResidentExportFormat format) {
    final stamp = DateFormat('yyyyMMdd-HHmm').format(_exportedAt);
    final ext = switch (format) {
      ResidentExportFormat.xlsx => 'xlsx',
      ResidentExportFormat.json => 'json',
      ResidentExportFormat.pdf => 'pdf',
    };
    return 'jirani-residents-$stamp.$ext';
  }

  String mimeTypeFor(ResidentExportFormat format) {
    return switch (format) {
      ResidentExportFormat.xlsx =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ResidentExportFormat.json => 'application/json',
      ResidentExportFormat.pdf => 'application/pdf',
    };
  }

  String formatLabel(ResidentExportFormat format) {
    return switch (format) {
      ResidentExportFormat.xlsx => 'Excel',
      ResidentExportFormat.json => 'JSON',
      ResidentExportFormat.pdf => 'PDF',
    };
  }

  Uint8List _buildJson(List<ResidentExportRow> rows, int recordCount) {
    final payload = <String, Object?>{
      'exportedAt': _exportedAt.toIso8601String(),
      'recordCount': recordCount,
      if (communityName != null && communityName!.trim().isNotEmpty)
        'communityName': communityName!.trim(),
      if (filterSummary != null && filterSummary!.trim().isNotEmpty)
        'filterSummary': filterSummary!.trim(),
      'residents': rows.map((row) => row.toJson()).toList(),
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  Uint8List _buildXlsx(List<ResidentExportRow> rows) {
    final workbook = Excel.createExcel();
    final defaultName = workbook.getDefaultSheet() ?? 'Sheet1';
    const sheetName = 'Residents';
    if (defaultName != sheetName) {
      workbook.rename(defaultName, sheetName);
    }
    final sheet = workbook[sheetName];

    sheet.appendRow(
      ResidentExportRow.headers
          .map((header) => TextCellValue(header))
          .toList(growable: false),
    );
    for (var col = 0; col < ResidentExportRow.headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: col))
          .cellStyle = CellStyle(bold: true);
    }

    for (final row in rows) {
      sheet.appendRow(
        row.values.map(TextCellValue.new).toList(growable: false),
      );
    }

    workbook.setDefaultSheet(sheetName);

    final encoded = workbook.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Failed to encode resident export workbook.');
    }
    return Uint8List.fromList(encoded);
  }

  Future<Uint8List> _buildPdf(List<ResidentExportRow> rows, int recordCount) async {
    final exportedLabel = DateFormat('yyyy-MM-dd HH:mm').format(_exportedAt);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Jirani Resident Directory Export',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Exported: $exportedLabel'),
          pw.Text('Records: $recordCount'),
          if (communityName != null && communityName!.trim().isNotEmpty)
            pw.Text('Community: ${communityName!.trim()}'),
          if (filterSummary != null && filterSummary!.trim().isNotEmpty)
            pw.Text('Filters: ${filterSummary!.trim()}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ResidentExportRow.headers,
            data: rows.map((row) => row.values).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
