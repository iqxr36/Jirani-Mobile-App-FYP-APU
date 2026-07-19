// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : public_profile_metrics_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/utils/firebase_storage_url.dart';
import 'package:jirani/shared/utils/public_profile_metrics.dart';

void main() {
  group('profile image reference helpers', () {
    test('isHttpProfileImageReference detects http and https URLs', () {
      expect(
        isHttpProfileImageReference(
          'https://firebasestorage.googleapis.com/v0/b/bucket/o/file.jpg',
        ),
        isTrue,
      );
      expect(isHttpProfileImageReference('http://example.com/a.jpg'), isTrue);
      expect(isHttpProfileImageReference('profile_images/residents/a.jpg'), isFalse);
      expect(isHttpProfileImageReference(''), isFalse);
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
      expect(isStorageResolvableProfileImageReference('https://example.com'), isFalse);
    });
  });

  group('publicProfileTrustScoreLabel', () {
    test('prefers live review average when reviews exist', () {
      expect(
        publicProfileTrustScoreLabel(
          reviewCount: 3,
          averageReviewRating: 4.5,
          communityTrustScore: 2,
          reputationScore: 2,
          profileTotalReviews: 0,
        ),
        '4.5',
      );
    });

    test('falls back to profile score when no live reviews', () {
      expect(
        publicProfileTrustScoreLabel(
          reviewCount: 0,
          averageReviewRating: 0,
          communityTrustScore: 4.2,
          reputationScore: 3.1,
          profileTotalReviews: 5,
        ),
        '4.2',
      );
    });

    test('returns dash when there are no reviews or profile totals', () {
      expect(
        publicProfileTrustScoreLabel(
          reviewCount: 0,
          averageReviewRating: 0,
          communityTrustScore: 0,
          reputationScore: 0,
          profileTotalReviews: 0,
        ),
        '-',
      );
    });
  });

  group('publicProfileReviewCount', () {
    test('prefers live review count when available', () {
      expect(
        publicProfileReviewCount(liveReviewCount: 4, profileTotalReviews: 1),
        4,
      );
    });

    test('falls back to profile total reviews', () {
      expect(
        publicProfileReviewCount(liveReviewCount: 0, profileTotalReviews: 2),
        2,
      );
    });
  });

  group('averageReviewRating', () {
    test('averages review ratings', () {
      expect(averageReviewRating(const [5, 3, 4]), closeTo(4, 0.001));
      expect(averageReviewRating(const []), 0);
    });
  });
}
