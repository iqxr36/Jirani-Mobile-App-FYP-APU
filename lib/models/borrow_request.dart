import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerEmail,
    required this.borrowerPhoneNumber,
    required this.borrowerVerified,
    required this.borrowerReputationScore,
    required this.requestedStartDate,
    required this.expectedReturnDate,
    required this.pickupTime,
    required this.message,
    required this.status,
    required this.hasUsageFee,
    required this.usageFeeAmount,
    required this.hasDeposit,
    required this.depositAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedAt,
    required this.rejectedAt,
    required this.rejectionReason,
    required this.pickupConfirmedAt,
    required this.handoverConfirmedAt,
    required this.returnSubmittedAt,
    required this.returnConfirmedAt,
    required this.completedAt,
    required this.pickupProofImageUrl,
    required this.handoverProofImageUrl,
    required this.returnProofImageUrl,
    required this.itemConditionBefore,
    required this.itemConditionAfter,
    required this.returnNotes,
    required this.ownerReturnNotes,
    required this.depositDecision,
    required this.depositDecisionReason,
    required this.depositDecidedAt,
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String borrowerId;
  final String borrowerName;
  final String borrowerEmail;
  final String borrowerPhoneNumber;
  final bool borrowerVerified;
  final double borrowerReputationScore;
  final DateTime requestedStartDate;
  final DateTime expectedReturnDate;
  final String pickupTime;
  final String message;
  final String status;
  final bool hasUsageFee;
  final double? usageFeeAmount;
  final bool hasDeposit;
  final double? depositAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String rejectionReason;
  final DateTime? pickupConfirmedAt;
  final DateTime? handoverConfirmedAt;
  final DateTime? returnSubmittedAt;
  final DateTime? returnConfirmedAt;
  final DateTime? completedAt;
  final String pickupProofImageUrl;
  final String handoverProofImageUrl;
  final String returnProofImageUrl;
  final String itemConditionBefore;
  final String itemConditionAfter;
  final String returnNotes;
  final String ownerReturnNotes;
  final String depositDecision;
  final String depositDecisionReason;
  final DateTime? depositDecidedAt;

  BorrowRequest copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemImageUrl,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? borrowerId,
    String? borrowerName,
    String? borrowerEmail,
    String? borrowerPhoneNumber,
    bool? borrowerVerified,
    double? borrowerReputationScore,
    DateTime? requestedStartDate,
    DateTime? expectedReturnDate,
    String? pickupTime,
    String? message,
    String? status,
    bool? hasUsageFee,
    double? usageFeeAmount,
    bool? hasDeposit,
    double? depositAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? pickupConfirmedAt,
    DateTime? handoverConfirmedAt,
    DateTime? returnSubmittedAt,
    DateTime? returnConfirmedAt,
    DateTime? completedAt,
    String? pickupProofImageUrl,
    String? handoverProofImageUrl,
    String? returnProofImageUrl,
    String? itemConditionBefore,
    String? itemConditionAfter,
    String? returnNotes,
    String? ownerReturnNotes,
    String? depositDecision,
    String? depositDecisionReason,
    DateTime? depositDecidedAt,
  }) {
    return BorrowRequest(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerEmail: borrowerEmail ?? this.borrowerEmail,
      borrowerPhoneNumber: borrowerPhoneNumber ?? this.borrowerPhoneNumber,
      borrowerVerified: borrowerVerified ?? this.borrowerVerified,
      borrowerReputationScore: borrowerReputationScore ?? this.borrowerReputationScore,
      requestedStartDate: requestedStartDate ?? this.requestedStartDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      pickupTime: pickupTime ?? this.pickupTime,
      message: message ?? this.message,
      status: status ?? this.status,
      hasUsageFee: hasUsageFee ?? this.hasUsageFee,
      usageFeeAmount: usageFeeAmount ?? this.usageFeeAmount,
      hasDeposit: hasDeposit ?? this.hasDeposit,
      depositAmount: depositAmount ?? this.depositAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      pickupConfirmedAt: pickupConfirmedAt ?? this.pickupConfirmedAt,
      handoverConfirmedAt: handoverConfirmedAt ?? this.handoverConfirmedAt,
      returnSubmittedAt: returnSubmittedAt ?? this.returnSubmittedAt,
      returnConfirmedAt: returnConfirmedAt ?? this.returnConfirmedAt,
      completedAt: completedAt ?? this.completedAt,
      pickupProofImageUrl: pickupProofImageUrl ?? this.pickupProofImageUrl,
      handoverProofImageUrl: handoverProofImageUrl ?? this.handoverProofImageUrl,
      returnProofImageUrl: returnProofImageUrl ?? this.returnProofImageUrl,
      itemConditionBefore: itemConditionBefore ?? this.itemConditionBefore,
      itemConditionAfter: itemConditionAfter ?? this.itemConditionAfter,
      returnNotes: returnNotes ?? this.returnNotes,
      ownerReturnNotes: ownerReturnNotes ?? this.ownerReturnNotes,
      depositDecision: depositDecision ?? this.depositDecision,
      depositDecisionReason: depositDecisionReason ?? this.depositDecisionReason,
      depositDecidedAt: depositDecidedAt ?? this.depositDecidedAt,
    );
  }

  factory BorrowRequest.fromMap(String id, Map<String, dynamic> data) {
    return BorrowRequest(
      id: id,
      itemId: (data['itemId'] as String?) ?? '',
      itemTitle: (data['itemTitle'] as String?) ?? '',
      itemImageUrl: (data['itemImageUrl'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      ownerEmail: (data['ownerEmail'] as String?) ?? '',
      borrowerId: (data['borrowerId'] as String?) ?? '',
      borrowerName: (data['borrowerName'] as String?) ?? '',
      borrowerEmail: (data['borrowerEmail'] as String?) ?? '',
      borrowerPhoneNumber: (data['borrowerPhoneNumber'] as String?) ?? '',
      borrowerVerified: data['borrowerVerified'] as bool? ?? false,
      borrowerReputationScore: _toDouble(data['borrowerReputationScore']) ?? 0,
      requestedStartDate: _toDate(data['requestedStartDate']),
      expectedReturnDate: _toDate(data['expectedReturnDate']),
      pickupTime: (data['pickupTime'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      status: (data['status'] as String?) ?? AppConstants.borrowStatusPending,
      hasUsageFee: data['hasUsageFee'] as bool? ?? ((_toDouble(data['usageFeeAmount']) ?? 0) > 0),
      usageFeeAmount: _toDouble(data['usageFeeAmount']),
      hasDeposit: data['hasDeposit'] as bool? ?? ((_toDouble(data['depositAmount']) ?? 0) > 0),
      depositAmount: _toDouble(data['depositAmount']),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      approvedAt: _toNullableDate(data['approvedAt']),
      rejectedAt: _toNullableDate(data['rejectedAt']),
      rejectionReason: (data['rejectionReason'] as String?) ?? '',
      pickupConfirmedAt: _toNullableDate(data['pickupConfirmedAt']),
      handoverConfirmedAt: _toNullableDate(data['handoverConfirmedAt']),
      returnSubmittedAt: _toNullableDate(data['returnSubmittedAt']),
      returnConfirmedAt: _toNullableDate(data['returnConfirmedAt']),
      completedAt: _toNullableDate(data['completedAt']),
      pickupProofImageUrl: (data['pickupProofImageUrl'] as String?) ?? '',
      handoverProofImageUrl: (data['handoverProofImageUrl'] as String?) ?? '',
      returnProofImageUrl: (data['returnProofImageUrl'] as String?) ?? '',
      itemConditionBefore: (data['itemConditionBefore'] as String?) ?? '',
      itemConditionAfter: (data['itemConditionAfter'] as String?) ?? '',
      returnNotes: (data['returnNotes'] as String?) ?? '',
      ownerReturnNotes: (data['ownerReturnNotes'] as String?) ?? '',
      depositDecision: _parseDepositDecision(data),
      depositDecisionReason: (data['depositDecisionReason'] as String?) ?? '',
      depositDecidedAt: _toNullableDate(data['depositDecidedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemImageUrl': itemImageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'borrowerEmail': borrowerEmail,
      'borrowerPhoneNumber': borrowerPhoneNumber,
      'borrowerVerified': borrowerVerified,
      'borrowerReputationScore': borrowerReputationScore,
      'requestedStartDate': Timestamp.fromDate(requestedStartDate),
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'pickupTime': pickupTime,
      'message': message,
      'status': status,
      'hasUsageFee': hasUsageFee,
      'usageFeeAmount': hasUsageFee ? usageFeeAmount : null,
      'hasDeposit': hasDeposit,
      'depositAmount': hasDeposit ? depositAmount : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectedAt': rejectedAt == null ? null : Timestamp.fromDate(rejectedAt!),
      'rejectionReason': rejectionReason,
      'pickupConfirmedAt': pickupConfirmedAt == null ? null : Timestamp.fromDate(pickupConfirmedAt!),
      'handoverConfirmedAt': handoverConfirmedAt == null ? null : Timestamp.fromDate(handoverConfirmedAt!),
      'returnSubmittedAt': returnSubmittedAt == null ? null : Timestamp.fromDate(returnSubmittedAt!),
      'returnConfirmedAt': returnConfirmedAt == null ? null : Timestamp.fromDate(returnConfirmedAt!),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'pickupProofImageUrl': pickupProofImageUrl.isEmpty ? null : pickupProofImageUrl,
      'handoverProofImageUrl': handoverProofImageUrl.isEmpty ? null : handoverProofImageUrl,
      'returnProofImageUrl': returnProofImageUrl.isEmpty ? null : returnProofImageUrl,
      'itemConditionBefore': itemConditionBefore.isEmpty ? null : itemConditionBefore,
      'itemConditionAfter': itemConditionAfter.isEmpty ? null : itemConditionAfter,
      'returnNotes': returnNotes,
      'ownerReturnNotes': ownerReturnNotes,
      'depositDecision': depositDecision,
      'depositDecisionReason': depositDecisionReason.isEmpty ? null : depositDecisionReason,
      'depositDecidedAt': depositDecidedAt == null ? null : Timestamp.fromDate(depositDecidedAt!),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _toNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _parseDepositDecision(Map<String, dynamic> data) {
    final raw = (data['depositDecision'] as String?)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    final hd = data['hasDeposit'] as bool? ?? ((_toDouble(data['depositAmount']) ?? 0) > 0);
    return hd ? AppConstants.depositDecisionPending : AppConstants.depositDecisionNotRequired;
  }
}
