import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.borrowRequestId,
    required this.itemId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String borrowRequestId;
  final String itemId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String revieweeName;
  final int rating;
  final String comment;
  final String role;
  final DateTime createdAt;

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return ReviewModel(
      id: id,
      borrowRequestId: (data['borrowRequestId'] as String?) ?? '',
      itemId: (data['itemId'] as String?) ?? '',
      reviewerId: (data['reviewerId'] as String?) ?? '',
      reviewerName: (data['reviewerName'] as String?) ?? '',
      revieweeId: (data['revieweeId'] as String?) ?? '',
      revieweeName: (data['revieweeName'] as String?) ?? '',
      rating: _parseRating(data['rating']),
      comment: (data['comment'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static int _parseRating(dynamic v) {
    if (v is int) return v.clamp(1, 5);
    if (v is num) return v.toInt().clamp(1, 5);
    return 1;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
