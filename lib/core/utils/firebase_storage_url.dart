// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : firebase_storage_url.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,10-July-2026
// Last Edited on  : Saturday,18-July-2026

/// Parses Firebase Storage profile image references into bucket object paths.
String? firebaseStorageObjectPathFromProfileImageReference(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (_isProfileImageObjectPath(trimmed)) {
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  if (uri.scheme == 'gs' && uri.host.isNotEmpty && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.join('/');
  }

  final host = uri.host.toLowerCase();
  if (!host.contains('firebasestorage.googleapis.com')) {
    return null;
  }

  final segments = uri.pathSegments;
  final objectIndex = segments.indexOf('o');
  if (objectIndex < 0 || objectIndex + 1 >= segments.length) {
    return null;
  }

  final encodedPath = segments[objectIndex + 1];
  if (encodedPath.isEmpty) return null;

  return Uri.decodeComponent(encodedPath);
}

/// Parses Firebase Storage download URLs into bucket object paths.
String? firebaseStorageObjectPathFromDownloadUrl(String downloadUrl) {
  return firebaseStorageObjectPathFromProfileImageReference(downloadUrl);
}

bool _isProfileImageObjectPath(String value) {
  if (value.contains('://')) return false;
  return value.startsWith('profile_images/') && !value.contains('..');
}

/// Returns true when the reference is already an HTTP(S) image URL.
bool isHttpProfileImageReference(String value) {
  final trimmed = value.trim().toLowerCase();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

/// Returns true when the reference can be resolved through Firebase Storage.
bool isStorageResolvableProfileImageReference(String value) {
  return firebaseStorageObjectPathFromProfileImageReference(value) != null;
}
