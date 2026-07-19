// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : file_download.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// Saves generated export bytes using the platform file picker / download flow.
Future<void> saveExportedFile({
  required String filename,
  required Uint8List bytes,
}) async {
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == filename.length - 1) {
    throw ArgumentError('filename must include a file extension.');
  }

  final name = filename.substring(0, dotIndex);
  final ext = filename.substring(dotIndex + 1);

  await FileSaver.instance.saveFile(
    name: name,
    bytes: bytes,
    fileExtension: ext,
    mimeType: _mimeTypeForExtension(ext),
  );
}

MimeType _mimeTypeForExtension(String ext) {
  return switch (ext.toLowerCase()) {
    'xlsx' => MimeType.microsoftExcel,
    'json' => MimeType.json,
    'pdf' => MimeType.pdf,
    'csv' => MimeType.csv,
    _ => MimeType.custom,
  };
}
