/// Public profile feature: formats the trust score label from live reviews or profile stats.
String publicProfileTrustScoreLabel({
  required int reviewCount,
  required double averageReviewRating,
  required double communityTrustScore,
  required double reputationScore,
  required int profileTotalReviews,
}) {
  if (reviewCount > 0) {
    return averageReviewRating.toStringAsFixed(1);
  }
  if (profileTotalReviews == 0) return '-';
  final score = communityTrustScore > 0 ? communityTrustScore : reputationScore;
  return score.toStringAsFixed(1);
}

/// Public profile feature: prefers live review count over denormalized profile totals.
int publicProfileReviewCount({
  required int liveReviewCount,
  required int profileTotalReviews,
}) {
  return liveReviewCount > 0 ? liveReviewCount : profileTotalReviews;
}

/// Public profile feature: averages review star ratings for display.
double averageReviewRating(Iterable<int> ratings) {
  final values = ratings.toList();
  if (values.isEmpty) return 0;
  final total = values.fold<int>(0, (sum, rating) => sum + rating);
  return total / values.length;
}
