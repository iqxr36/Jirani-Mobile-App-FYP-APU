import 'package:cloud_firestore/cloud_firestore.dart';

/// Services DB model: represents services/{serviceId} created by residents offering help.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.priceType,
    required this.priceAmount,
    required this.availability,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String providerEmail;
  final String title;
  final String description;
  final String category;
  final String priceType;
  final double? priceAmount;
  final String availability;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Services DB model: converts Firestore service data into a ServiceModel for browse/manage screens.
  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      providerId: (data['providerId'] as String?) ?? '',
      providerName: (data['providerName'] as String?) ?? '',
      providerEmail: (data['providerEmail'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      priceType: (data['priceType'] as String?) ?? '',
      priceAmount: _toDouble(data['priceAmount']),
      availability: (data['availability'] as String?) ?? '',
      status: (data['status'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Services DB model: safely reads optional service price values.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Services DB model: converts Firestore timestamp-like fields into DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
