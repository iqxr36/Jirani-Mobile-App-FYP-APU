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
