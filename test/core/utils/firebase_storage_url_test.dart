import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/utils/firebase_storage_url.dart';

void main() {
  group('firebaseStorageObjectPathFromProfileImageReference', () {
    test('parses encoded Firebase Storage download URL', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/final-year-project-faisal.firebasestorage.app/o/profile_images%2Fadmins%2Fuid123%2Favatar_1.jpg?alt=media&token=abc';

      expect(
        firebaseStorageObjectPathFromProfileImageReference(url),
        'profile_images/admins/uid123/avatar_1.jpg',
      );
    });

    test('parses gs URL', () {
      const url =
          'gs://final-year-project-faisal.firebasestorage.app/profile_images/admins/uid123/avatar_1.jpg';

      expect(
        firebaseStorageObjectPathFromProfileImageReference(url),
        'profile_images/admins/uid123/avatar_1.jpg',
      );
    });

    test('accepts plain profile image object path', () {
      const path = 'profile_images/admins/uid123/avatar_1.jpg';

      expect(firebaseStorageObjectPathFromProfileImageReference(path), path);
    });

    test('returns null for malformed URLs', () {
      expect(firebaseStorageObjectPathFromProfileImageReference(''), isNull);
      expect(
        firebaseStorageObjectPathFromProfileImageReference(
          'https://example.com/file.jpg',
        ),
        isNull,
      );
      expect(
        firebaseStorageObjectPathFromProfileImageReference(
          'https://firebasestorage.googleapis.com/v0/b/bucket/o',
        ),
        isNull,
      );
      expect(
        firebaseStorageObjectPathFromProfileImageReference(
          'profile_images/admins/uid123/../avatar.jpg',
        ),
        isNull,
      );
    });
  });

  group('profile image reference helpers', () {
    test('isHttpProfileImageReference detects http and https URLs', () {
      expect(
        isHttpProfileImageReference(
          'https://firebasestorage.googleapis.com/v0/b/bucket/o/file.jpg',
        ),
        isTrue,
      );
      expect(isHttpProfileImageReference('http://example.com/a.jpg'), isTrue);
      expect(
        isHttpProfileImageReference('profile_images/residents/a.jpg'),
        isFalse,
      );
    });

    test('isStorageResolvableProfileImageReference detects storage paths', () {
      expect(
        isStorageResolvableProfileImageReference(
          'profile_images/residents/uid123/avatar.jpg',
        ),
        isTrue,
      );
      expect(
        isStorageResolvableProfileImageReference(
          'gs://bucket/profile_images/residents/uid123/avatar.jpg',
        ),
        isTrue,
      );
    });
  });
}
