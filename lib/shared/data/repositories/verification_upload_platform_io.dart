import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Mobile/desktop IO: upload the picker bytes directly.
///
/// The UI already reads the file before submit. Keeping a single `putData` path
/// avoids platform-specific stalls from content/file URI resolution.
UploadTask putVerificationObject(
  Reference ref,
  Uint8List bytes,
  String? localPath,
  SettableMetadata metadata,
) {
  return ref.putData(bytes, metadata);
}
