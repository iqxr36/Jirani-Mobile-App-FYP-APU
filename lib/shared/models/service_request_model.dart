import 'package:cloud_firestore/cloud_firestore.dart';

/// Services DB model: represents serviceRequests/{requestId} from a resident to a service provider.
class ServiceRequestModel {
  const ServiceRequestModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerId,
    required this.providerName,
    required this.requesterId,
    required this.requesterName,
    required this.message,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceId;
  final String serviceTitle;
  final String providerId;
  final String providerName;
  final String requesterId;
  final String requesterName;
  final String message;
  final DateTime preferredDate;
  final String preferredTime;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Services DB model: converts Firestore request data into a ServiceRequestModel for requester/provider screens.
  factory ServiceRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceRequestModel(
      id: id,
      serviceId: (data['serviceId'] as String?) ?? '',
      serviceTitle: (data['serviceTitle'] as String?) ?? '',
      providerId: (data['providerId'] as String?) ?? '',
      providerName: (data['providerName'] as String?) ?? '',
      requesterId: (data['requesterId'] as String?) ?? '',
      requesterName: (data['requesterName'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      preferredDate: _parseDate(data['preferredDate']),
      preferredTime: (data['preferredTime'] as String?) ?? '',
      status: (data['status'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Services DB model: converts stored date fields into DateTime for scheduling display.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
