// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : reviews_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_reviews_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFF59E0B);
const double _kMaxContentWidth = 440;

final DateFormat _reviewDateFormat = DateFormat('MMM d, yyyy');

enum _ReviewTab { all, lending, borrowing, services }

double _averageRating(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String _metricValue(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return '-';
  return _averageRating(reviews).toStringAsFixed(1);
}
