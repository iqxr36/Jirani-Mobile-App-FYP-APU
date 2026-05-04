import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Mobile/desktop IO: prefer putFile when a readable local path exists; otherwise putData.
UploadTask putVerificationObject(
  Reference ref,
  Uint8List bytes,
  String? localPath,
  SettableMetadata metadata,
) {
  if (localPath != null && localPath.isNotEmpty) {
    try {
      final file = File(localPath);
      if (file.existsSync()) {
        return ref.putFile(file, metadata);
      }
    } catch (_) {
      // Fall through to putData.
    }
  }
  return ref.putData(bytes, metadata);
}
