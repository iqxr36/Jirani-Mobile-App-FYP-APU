part of '../resident_reviews_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFF59E0B);
const double _kMaxContentWidth = 440;

final DateFormat _reviewDateFormat = DateFormat('MMM d, yyyy');

enum _ReviewTab { all, lending, borrowing }

double _averageRating(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String _metricValue(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return '-';
  return _averageRating(reviews).toStringAsFixed(1);
}
