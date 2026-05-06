import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed residency verification request.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.documentType,
    required this.documentUrl,
    required this.communityName,
    required this.unitNumber,
    required this.notes,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedBy,
    this.cancelledAt,
    this.cancelledBy,
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String documentType;
  final String documentUrl;
  final String communityName;
  final String unitNumber;
  final String notes;
  final String status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? cancelledAt;
  final String? cancelledBy;

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? documentType,
    String? documentUrl,
    String? communityName,
    String? unitNumber,
    String? notes,
    String? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? cancelledAt,
    String? cancelledBy,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      communityName: communityName ?? this.communityName,
      unitNumber: unitNumber ?? this.unitNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'communityName': communityName,
      'unitNumber': unitNumber,
      'notes': notes,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
    };
  }

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    final rawUserId = map['userId'] ?? map['residentUid'] ?? map['uid'];
    final rawDocumentUrl = map['documentUrl'] ?? map['fileUrl'] ?? map['uploadedFileUrl'];
    final rawSubmittedAt = map['submittedAt'] ?? map['createdAt'];

    return VerificationRequest(
      id: (map['id'] as String?) ?? '',
      userId: (rawUserId as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? '',
      documentUrl: (rawDocumentUrl as String?) ?? '',
      communityName: (map['communityName'] as String?) ?? '',
      unitNumber: (map['unitNumber'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
      rejectionReason: map['rejectionReason'] as String?,
      submittedAt: _parseDate(rawSubmittedAt),
      reviewedAt: _parseOptionalDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      cancelledAt: _parseOptionalDate(map['cancelledAt']),
      cancelledBy: map['cancelledBy'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
