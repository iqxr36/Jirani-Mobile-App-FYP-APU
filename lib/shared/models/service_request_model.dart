// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : service_request_model.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,13-June-2026
// Last Edited on  : Saturday,18-July-2026

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
    this.paymentStatus = '',
    this.paymentId = '',
    this.paymentProvider = '',
    this.amount,
    this.durationHours,
    this.hourlyRate,
    this.currency = '',
    this.platformFeeAmount = 0,
    this.providerPayoutAmount = 0,
    this.arrivalCodeExpiresAt,
    this.arrivalVerifiedAt,
    this.startedAt,
    this.completionCodeExpiresAt,
    this.completionVerifiedAt,
    this.completedAt,
    this.payoutStatus = '',
    this.xenditPayoutId = '',
    this.payoutFailureReason = '',
    this.refundStatus = '',
    this.xenditRefundId = '',
    this.refundFailureReason = '',
    this.disputeType = '',
    this.disputeReason = '',
    this.disputedAt,
    this.disputeReportId = '',
    this.requesterDisputeEvidenceUrls = const <String>[],
    this.providerDisputeEvidenceUrls = const <String>[],
    this.providerDisputeStatement = '',
    this.adminResolvedAt,
    this.adminResolvedBy = '',
    this.adminResolution = '',
    this.settlementMode = '',
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
  final String paymentStatus;
  final String paymentId;
  final String paymentProvider;
  final double? amount;
  final int? durationHours;
  final double? hourlyRate;
  final String currency;
  final double platformFeeAmount;
  final double providerPayoutAmount;
  final DateTime? arrivalCodeExpiresAt;
  final DateTime? arrivalVerifiedAt;
  final DateTime? startedAt;
  final DateTime? completionCodeExpiresAt;
  final DateTime? completionVerifiedAt;
  final DateTime? completedAt;
  final String payoutStatus;
  final String xenditPayoutId;
  final String payoutFailureReason;
  final String refundStatus;
  final String xenditRefundId;
  final String refundFailureReason;
  final String disputeType;
  final String disputeReason;
  final DateTime? disputedAt;
  final String disputeReportId;
  final List<String> requesterDisputeEvidenceUrls;
  final List<String> providerDisputeEvidenceUrls;
  final String providerDisputeStatement;
  final DateTime? adminResolvedAt;
  final String adminResolvedBy;
  final String adminResolution;
  final String settlementMode;
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
      paymentStatus: (data['paymentStatus'] as String?) ?? '',
      paymentId: (data['paymentId'] as String?) ?? '',
      paymentProvider: (data['paymentProvider'] as String?) ?? '',
      amount: _toDouble(data['amount']),
      durationHours: _toInt(data['durationHours']),
      hourlyRate: _toDouble(data['hourlyRate']),
      currency: (data['currency'] as String?) ?? '',
      platformFeeAmount: _toDouble(data['platformFeeAmount']) ?? 0,
      providerPayoutAmount: _toDouble(data['providerPayoutAmount']) ?? 0,
      arrivalCodeExpiresAt: _parseOptionalDate(data['arrivalCodeExpiresAt']),
      arrivalVerifiedAt: _parseOptionalDate(data['arrivalVerifiedAt']),
      startedAt: _parseOptionalDate(data['startedAt']),
      completionCodeExpiresAt: _parseOptionalDate(
        data['completionCodeExpiresAt'],
      ),
      completionVerifiedAt: _parseOptionalDate(data['completionVerifiedAt']),
      completedAt: _parseOptionalDate(data['completedAt']),
      payoutStatus: (data['payoutStatus'] as String?) ?? '',
      xenditPayoutId: (data['xenditPayoutId'] as String?) ?? '',
      payoutFailureReason: (data['payoutFailureReason'] as String?) ?? '',
      refundStatus: (data['refundStatus'] as String?) ?? '',
      xenditRefundId: (data['xenditRefundId'] as String?) ?? '',
      refundFailureReason: (data['refundFailureReason'] as String?) ?? '',
      disputeType: (data['disputeType'] as String?) ?? '',
      disputeReason: (data['disputeReason'] as String?) ?? '',
      disputedAt: _parseOptionalDate(data['disputedAt']),
      disputeReportId: (data['disputeReportId'] as String?) ?? '',
      requesterDisputeEvidenceUrls: _toStringList(data['requesterDisputeEvidenceUrls']),
      providerDisputeEvidenceUrls: _toStringList(data['providerDisputeEvidenceUrls']),
      providerDisputeStatement: (data['providerDisputeStatement'] as String?) ?? '',
      adminResolvedAt: _parseOptionalDate(data['adminResolvedAt']),
      adminResolvedBy: (data['adminResolvedBy'] as String?) ?? '',
      adminResolution: (data['adminResolution'] as String?) ?? '',
      settlementMode: (data['settlementMode'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  bool get isPaidService => amount != null && amount! > 0;
  bool get isHourlyService =>
      durationHours != null && durationHours! > 0 && hourlyRate != null;

  static List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
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
