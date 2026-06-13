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
    required this.communityId,
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
    this.ocrStatus = '',
    this.ocrText = '',
    this.ocrFields = const {},
    this.ocrError,
    this.ocrProcessedAt,
    this.storagePath = '',
    this.adminStatus = '',
    this.extractedFields = const {},
    this.processedAt,
    this.errorMessage,
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String documentType;
  final String documentUrl;
  final String communityId;
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
  final String ocrStatus;
  final String ocrText;
  final Map<String, String> ocrFields;
  final String? ocrError;
  final DateTime? ocrProcessedAt;
  final String storagePath;
  final String adminStatus;
  final Map<String, ExtractedVerificationField> extractedFields;
  final DateTime? processedAt;
  final String? errorMessage;

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? documentType,
    String? documentUrl,
    String? communityId,
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
    String? ocrStatus,
    String? ocrText,
    Map<String, String>? ocrFields,
    String? ocrError,
    DateTime? ocrProcessedAt,
    String? storagePath,
    String? adminStatus,
    Map<String, ExtractedVerificationField>? extractedFields,
    DateTime? processedAt,
    String? errorMessage,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      communityId: communityId ?? this.communityId,
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
      ocrStatus: ocrStatus ?? this.ocrStatus,
      ocrText: ocrText ?? this.ocrText,
      ocrFields: ocrFields ?? this.ocrFields,
      ocrError: ocrError ?? this.ocrError,
      ocrProcessedAt: ocrProcessedAt ?? this.ocrProcessedAt,
      storagePath: storagePath ?? this.storagePath,
      adminStatus: adminStatus ?? this.adminStatus,
      extractedFields: extractedFields ?? this.extractedFields,
      processedAt: processedAt ?? this.processedAt,
      errorMessage: errorMessage ?? this.errorMessage,
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
      'communityId': communityId,
      'communityName': communityName,
      'unitNumber': unitNumber,
      'notes': notes,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'cancelledBy': cancelledBy,
      'ocrStatus': ocrStatus,
      'ocrText': ocrText,
      'ocrFields': ocrFields,
      'ocrError': ocrError,
      'ocrProcessedAt': ocrProcessedAt != null
          ? Timestamp.fromDate(ocrProcessedAt!)
          : null,
      'storagePath': storagePath,
      'adminStatus': adminStatus,
      'extractedFields': extractedFields.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'errorMessage': errorMessage,
    };
  }

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    final rawUserId = map['userId'] ?? map['residentUid'] ?? map['uid'];
    final rawDocumentUrl =
        map['documentUrl'] ?? map['fileUrl'] ?? map['uploadedFileUrl'];
    final rawSubmittedAt = map['submittedAt'] ?? map['createdAt'];

    return VerificationRequest(
      id: (map['id'] as String?) ?? '',
      userId: (rawUserId as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? '',
      documentUrl: (rawDocumentUrl as String?) ?? '',
      communityId: (map['communityId'] as String?) ?? '',
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
      ocrStatus: (map['ocrStatus'] as String?) ?? '',
      ocrText: (map['ocrText'] as String?) ?? '',
      ocrFields: _parseStringMap(map['ocrFields']),
      ocrError: map['ocrError'] as String?,
      ocrProcessedAt: _parseOptionalDate(map['ocrProcessedAt']),
      storagePath: (map['storagePath'] as String?) ?? '',
      adminStatus: (map['adminStatus'] as String?) ?? '',
      extractedFields: _parseExtractedFields(map['extractedFields']),
      processedAt: _parseOptionalDate(map['processedAt']),
      errorMessage: map['errorMessage'] as String?,
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

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, fieldValue) =>
          MapEntry(key.toString(), fieldValue?.toString() ?? ''),
    );
  }

  static Map<String, ExtractedVerificationField> _parseExtractedFields(
    dynamic value,
  ) {
    if (value is! Map) return const {};
    return value.map((key, fieldValue) {
      return MapEntry(
        key.toString(),
        ExtractedVerificationField.fromValue(fieldValue),
      );
    });
  }
}

class ExtractedVerificationField {
  const ExtractedVerificationField({
    required this.value,
    required this.confidence,
    this.source = '',
  });

  final String value;
  final double confidence;
  final String source;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
      'confidence': confidence,
      if (source.isNotEmpty) 'source': source,
    };
  }

  factory ExtractedVerificationField.fromValue(dynamic value) {
    if (value is Map) {
      final rawConfidence = value['confidence'];
      return ExtractedVerificationField(
        value: value['value']?.toString() ?? '',
        confidence: rawConfidence is num ? rawConfidence.toDouble() : 0,
        source: value['source']?.toString() ?? '',
      );
    }
    return ExtractedVerificationField(
      value: value?.toString() ?? '',
      confidence: 0,
    );
  }
}
