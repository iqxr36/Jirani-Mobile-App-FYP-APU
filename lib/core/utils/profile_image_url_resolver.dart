import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/utils/firebase_storage_url.dart';

/// Profile image feature: resolves storage object paths and gs URLs into displayable download URLs.
Future<String?> resolveProfileImageDisplayUrl(String reference) async {
  final trimmed = reference.trim();
  if (trimmed.isEmpty) return null;

  try {
    if (trimmed.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(trimmed).getDownloadURL();
    }

    if (isHttpProfileImageReference(trimmed)) {
      if (trimmed.contains('firebasestorage.googleapis.com')) {
        try {
          return await FirebaseStorage.instance
              .refFromURL(trimmed)
              .getDownloadURL();
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }

    final objectPath = firebaseStorageObjectPathFromProfileImageReference(trimmed);
    if (objectPath != null) {
      return FirebaseStorage.instance.ref().child(objectPath).getDownloadURL();
    }
  } catch (_) {
    return null;
  }

  return null;
}
