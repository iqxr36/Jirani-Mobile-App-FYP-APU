import 'package:cloud_firestore/cloud_firestore.dart';

/// Reviews DB model: represents reviews/{reviewId} and supports hidden-until-both-submit marketplace review publishing.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.borrowRequestId,
    this.serviceRequestId = '',
    this.serviceId = '',
    required this.itemId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.role,
    required this.createdAt,
    required this.visible,
    required this.status,
    required this.publishAfter,
    required this.publishedAt,
  });

  final String id;
  final String borrowRequestId;
  final String serviceRequestId;
  final String serviceId;
  final String itemId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String revieweeName;
  final int rating;
  final String comment;
  final String role;
  final DateTime createdAt;
  final bool visible;
  final String status;
  final DateTime? publishAfter;
  final DateTime? publishedAt;

  /// Reviews DB model: converts Firestore review data into the profile/reputation review model.
  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return ReviewModel(
      id: id,
      borrowRequestId: (data['borrowRequestId'] as String?) ?? '',
      serviceRequestId: (data['serviceRequestId'] as String?) ?? '',
      serviceId: (data['serviceId'] as String?) ?? '',
      itemId: (data['itemId'] as String?) ?? '',
      reviewerId: (data['reviewerId'] as String?) ?? '',
      reviewerName: (data['reviewerName'] as String?) ?? '',
      revieweeId: (data['revieweeId'] as String?) ?? '',
      revieweeName: (data['revieweeName'] as String?) ?? '',
      rating: _parseRating(data['rating']),
      comment: (data['comment'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
      visible: (data['visible'] as bool?) ?? true,
      status: (data['status'] as String?) ?? 'published',
      publishAfter: _parseNullableDate(data['publishAfter']),
      publishedAt: _parseNullableDate(data['publishedAt']),
    );
  }

  /// Reviews DB model: clamps stored rating values into the allowed 1-5 star range.
  static int _parseRating(dynamic v) {
    if (v is int) return v.clamp(1, 5);
    if (v is num) return v.toInt().clamp(1, 5);
    return 1;
  }

  /// Reviews DB model: converts stored createdAt values into DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Reviews DB model: converts optional publishAfter/publishedAt values into nullable DateTime.
  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
