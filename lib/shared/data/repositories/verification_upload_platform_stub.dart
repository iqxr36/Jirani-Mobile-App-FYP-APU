// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_upload_platform_stub.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Web / IO-less: always use bytes (putData).
UploadTask putVerificationObject(
  Reference ref,
  Uint8List bytes,
  String? localPath,
  SettableMetadata metadata,
) {
  return ref.putData(bytes, metadata);
}
