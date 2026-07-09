import 'package:cloud_firestore/cloud_firestore.dart';

/// Services DB model: represents services/{serviceId} created by residents offering help.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    this.communityId = '',
    this.communityName = '',
    this.providerPhotoUrl = '',
    required this.title,
    required this.description,
    required this.category,
    required this.priceType,
    required this.priceAmount,
    this.imageUrls = const <String>[],
    this.certificateUrls = const <String>[],
    this.certificateNames = const <String>[],
    this.pricingMode = '',
    this.hourlyRate,
    this.fixedJobPrice,
    required this.availability,
    this.availableWeekdays = const <int>[],
    this.availabilityStartMinutes = 0,
    this.availabilityEndMinutes = 0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String providerEmail;
  final String communityId;
  final String communityName;
  final String providerPhotoUrl;
  final String title;
  final String description;
  final String category;
  final String priceType;
  final double? priceAmount;
  final List<String> imageUrls;
  final List<String> certificateUrls;
  final List<String> certificateNames;
  final String pricingMode;
  final double? hourlyRate;
  final double? fixedJobPrice;
  final String availability;
  final List<int> availableWeekdays;
  final int availabilityStartMinutes;
  final int availabilityEndMinutes;
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
      communityId: (data['communityId'] as String?) ?? '',
      communityName: (data['communityName'] as String?) ?? '',
      providerPhotoUrl: (data['providerPhotoUrl'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      priceType: (data['priceType'] as String?) ?? '',
      priceAmount: _toDouble(data['priceAmount']),
      imageUrls: _toStringList(data['imageUrls']),
      certificateUrls: _toStringList(data['certificateUrls']),
      certificateNames: _toStringList(data['certificateNames']),
      pricingMode: (data['pricingMode'] as String?) ?? '',
      hourlyRate: _toDouble(data['hourlyRate']),
      fixedJobPrice: _toDouble(data['fixedJobPrice']),
      availability: (data['availability'] as String?) ?? '',
      availableWeekdays: _toIntList(data['availableWeekdays']),
      availabilityStartMinutes: _toInt(data['availabilityStartMinutes']),
      availabilityEndMinutes: _toInt(data['availabilityEndMinutes']),
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

  static List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  static List<int> _toIntList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((entry) {
            if (entry is int) return entry;
            if (entry is num) return entry.toInt();
            if (entry is String) return int.tryParse(entry);
            return null;
          })
          .whereType<int>()
          .toList(growable: false);
    }
    return const <int>[];
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
