// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,13-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Marketplace DB model: represents one borrow transaction, including approval, payment, handover, return, dispute, and payout fields.
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
    required this.paymentStatus,
    required this.paymentCompletedAt,
    required this.paymentProvider,
    required this.chatId,
    required this.handoverCode,
    required this.returnCode,
    required this.hasUsageFee,
    required this.usageFeeAmount,
    this.rentalMode = '',
    this.rentalUnitCount = 1,
    this.dailyRateSnapshot,
    this.hourlyRateSnapshot,
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
    this.minorDeductionAmount,
    this.minorIssueReason = '',
    this.minorIssuePhotoUrl = '',
    this.minorIssueReportedAt,
    this.minorIssueBorrowerDecision = AppConstants.minorIssueDecisionPending,
    this.minorIssueBorrowerRespondedAt,
    this.disputeReportId = '',
    this.disputeReason = '',
    this.disputeEvidenceImageUrl = '',
    this.disputeReportedAt,
    this.adminResolution = AppConstants.adminResolutionPending,
    this.adminResolutionReason = '',
    this.adminResolvedAt,
    this.adminResolvedBy = '',
    this.depositStatus = '',
    this.depositHeldAmount = 0,
    this.depositRefundAmount = 0,
    this.depositRefundedAt,
    this.damageDeductionAmount = 0,
    this.damageDecision = AppConstants.damageDecisionNone,
    this.damageDecisionReason = '',
    this.damageDecidedAt,
    this.xenditRefundId = '',
    this.xenditPaymentRequestId = '',
    this.xenditPaymentId = '',
    this.xenditInvoiceId = '',
    this.xenditReferenceId = '',
    this.xenditChannelCode = '',
    this.xenditFailureReason = '',
    this.refundStatus = '',
    this.refundFailureReason = '',
    this.lenderBaseEarning = 0,
    this.lenderDamageEarning = 0,
    this.lenderTotalEarning = 0,
    this.manualPayoutStatus = '',
    this.manualPayoutMarkedAt,
    this.manualPayoutMarkedBy = '',
    this.manualPayoutReference = '',
    this.manualPayoutNote = '',
    this.settlementMode = '',
    this.borrowerReviewSubmitted = false,
    this.borrowerReviewSubmittedAt,
    this.ownerReviewSubmitted = false,
    this.ownerReviewSubmittedAt,
    this.reviewGraceEndsAt,
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
  /// Marketplace lifecycle: current borrow state such as pending, approved, active, returnSubmitted, disputed, or completed.
  final String status;

  /// Marketplace payment: provider-confirmed status used before chat/handover is unlocked.
  final String paymentStatus;
  final DateTime? paymentCompletedAt;
  final String paymentProvider;
  final String chatId;
  final String handoverCode;
  final String returnCode;
  final bool hasUsageFee;
  final double? usageFeeAmount;
  final String rentalMode;
  final int rentalUnitCount;
  final double? dailyRateSnapshot;
  final double? hourlyRateSnapshot;
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
  /// Marketplace deposit: owner/admin decision that decides refund, partial deduction, or withholding outcome.
  final String depositDecision;
  final String depositDecisionReason;
  final DateTime? depositDecidedAt;
  /// Marketplace dispute: lender-requested minor deduction that borrower can accept or decline.
  final double? minorDeductionAmount;
  final String minorIssueReason;
  final String minorIssuePhotoUrl;
  final DateTime? minorIssueReportedAt;
  final String minorIssueBorrowerDecision;
  final DateTime? minorIssueBorrowerRespondedAt;
  final String disputeReportId;
  final String disputeReason;
  final String disputeEvidenceImageUrl;
  final DateTime? disputeReportedAt;
  /// Marketplace admin dispute: admin's final decision when minor/major damage needs moderation.
  final String adminResolution;
  final String adminResolutionReason;
  final DateTime? adminResolvedAt;
  final String adminResolvedBy;
  /// Marketplace deposit: backend status for held/refunded/deducted/refund_failed deposit money.
  final String depositStatus;
  final double depositHeldAmount;
  final double depositRefundAmount;
  final DateTime? depositRefundedAt;
  final double damageDeductionAmount;
  final String damageDecision;
  final String damageDecisionReason;
  final DateTime? damageDecidedAt;
  final String xenditRefundId;
  final String xenditPaymentRequestId;
  final String xenditPaymentId;
  final String xenditInvoiceId;
  final String xenditReferenceId;
  final String xenditChannelCode;
  final String xenditFailureReason;
  final String refundStatus;
  final String refundFailureReason;
  /// Marketplace payout: usage fee plus any approved damage deduction owed to the lender.
  final double lenderBaseEarning;
  final double lenderDamageEarning;
  final double lenderTotalEarning;
  /// Marketplace payout: manual collection status used for lender earnings.
  final String manualPayoutStatus;
  final DateTime? manualPayoutMarkedAt;
  final String manualPayoutMarkedBy;
  final String manualPayoutReference;
  final String manualPayoutNote;
  final String settlementMode;
  /// Marketplace reviews: prevents borrower and lender from submitting duplicate post-transaction reviews.
  final bool borrowerReviewSubmitted;
  final DateTime? borrowerReviewSubmittedAt;
  final bool ownerReviewSubmitted;
  final DateTime? ownerReviewSubmittedAt;
  final DateTime? reviewGraceEndsAt;

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
    String? paymentStatus,
    DateTime? paymentCompletedAt,
    String? paymentProvider,
    String? chatId,
    String? handoverCode,
    String? returnCode,
    bool? hasUsageFee,
    double? usageFeeAmount,
    String? rentalMode,
    int? rentalUnitCount,
    double? dailyRateSnapshot,
    double? hourlyRateSnapshot,
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
    double? minorDeductionAmount,
    String? minorIssueReason,
    String? minorIssuePhotoUrl,
    DateTime? minorIssueReportedAt,
    String? minorIssueBorrowerDecision,
    DateTime? minorIssueBorrowerRespondedAt,
    String? disputeReportId,
    String? disputeReason,
    String? disputeEvidenceImageUrl,
    DateTime? disputeReportedAt,
    String? adminResolution,
    String? adminResolutionReason,
    DateTime? adminResolvedAt,
    String? adminResolvedBy,
    String? depositStatus,
    double? depositHeldAmount,
    double? depositRefundAmount,
    DateTime? depositRefundedAt,
    double? damageDeductionAmount,
    String? damageDecision,
    String? damageDecisionReason,
    DateTime? damageDecidedAt,
    String? xenditRefundId,
    String? xenditPaymentRequestId,
    String? xenditPaymentId,
    String? xenditInvoiceId,
    String? xenditReferenceId,
    String? xenditChannelCode,
    String? xenditFailureReason,
    String? refundStatus,
    String? refundFailureReason,
    double? lenderBaseEarning,
    double? lenderDamageEarning,
    double? lenderTotalEarning,
    String? manualPayoutStatus,
    DateTime? manualPayoutMarkedAt,
    String? manualPayoutMarkedBy,
    String? manualPayoutReference,
    String? manualPayoutNote,
    String? settlementMode,
    bool? borrowerReviewSubmitted,
    DateTime? borrowerReviewSubmittedAt,
    bool? ownerReviewSubmitted,
    DateTime? ownerReviewSubmittedAt,
    DateTime? reviewGraceEndsAt,
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
      borrowerReputationScore:
          borrowerReputationScore ?? this.borrowerReputationScore,
      requestedStartDate: requestedStartDate ?? this.requestedStartDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      pickupTime: pickupTime ?? this.pickupTime,
      message: message ?? this.message,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentCompletedAt: paymentCompletedAt ?? this.paymentCompletedAt,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      chatId: chatId ?? this.chatId,
      handoverCode: handoverCode ?? this.handoverCode,
      returnCode: returnCode ?? this.returnCode,
      hasUsageFee: hasUsageFee ?? this.hasUsageFee,
      usageFeeAmount: usageFeeAmount ?? this.usageFeeAmount,
      rentalMode: rentalMode ?? this.rentalMode,
      rentalUnitCount: rentalUnitCount ?? this.rentalUnitCount,
      dailyRateSnapshot: dailyRateSnapshot ?? this.dailyRateSnapshot,
      hourlyRateSnapshot: hourlyRateSnapshot ?? this.hourlyRateSnapshot,
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
      handoverProofImageUrl:
          handoverProofImageUrl ?? this.handoverProofImageUrl,
      returnProofImageUrl: returnProofImageUrl ?? this.returnProofImageUrl,
      itemConditionBefore: itemConditionBefore ?? this.itemConditionBefore,
      itemConditionAfter: itemConditionAfter ?? this.itemConditionAfter,
      returnNotes: returnNotes ?? this.returnNotes,
      ownerReturnNotes: ownerReturnNotes ?? this.ownerReturnNotes,
      depositDecision: depositDecision ?? this.depositDecision,
      depositDecisionReason:
          depositDecisionReason ?? this.depositDecisionReason,
      depositDecidedAt: depositDecidedAt ?? this.depositDecidedAt,
      minorDeductionAmount:
          minorDeductionAmount ?? this.minorDeductionAmount,
      minorIssueReason: minorIssueReason ?? this.minorIssueReason,
      minorIssuePhotoUrl: minorIssuePhotoUrl ?? this.minorIssuePhotoUrl,
      minorIssueReportedAt:
          minorIssueReportedAt ?? this.minorIssueReportedAt,
      minorIssueBorrowerDecision:
          minorIssueBorrowerDecision ?? this.minorIssueBorrowerDecision,
      minorIssueBorrowerRespondedAt:
          minorIssueBorrowerRespondedAt ??
          this.minorIssueBorrowerRespondedAt,
      disputeReportId: disputeReportId ?? this.disputeReportId,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeEvidenceImageUrl:
          disputeEvidenceImageUrl ?? this.disputeEvidenceImageUrl,
      disputeReportedAt: disputeReportedAt ?? this.disputeReportedAt,
      adminResolution: adminResolution ?? this.adminResolution,
      adminResolutionReason:
          adminResolutionReason ?? this.adminResolutionReason,
      adminResolvedAt: adminResolvedAt ?? this.adminResolvedAt,
      adminResolvedBy: adminResolvedBy ?? this.adminResolvedBy,
      depositStatus: depositStatus ?? this.depositStatus,
      depositHeldAmount: depositHeldAmount ?? this.depositHeldAmount,
      depositRefundAmount: depositRefundAmount ?? this.depositRefundAmount,
      depositRefundedAt: depositRefundedAt ?? this.depositRefundedAt,
      damageDeductionAmount:
          damageDeductionAmount ?? this.damageDeductionAmount,
      damageDecision: damageDecision ?? this.damageDecision,
      damageDecisionReason:
          damageDecisionReason ?? this.damageDecisionReason,
      damageDecidedAt: damageDecidedAt ?? this.damageDecidedAt,
      xenditRefundId: xenditRefundId ?? this.xenditRefundId,
      xenditPaymentRequestId:
          xenditPaymentRequestId ?? this.xenditPaymentRequestId,
      xenditPaymentId: xenditPaymentId ?? this.xenditPaymentId,
      xenditInvoiceId: xenditInvoiceId ?? this.xenditInvoiceId,
      xenditReferenceId: xenditReferenceId ?? this.xenditReferenceId,
      xenditChannelCode: xenditChannelCode ?? this.xenditChannelCode,
      xenditFailureReason: xenditFailureReason ?? this.xenditFailureReason,
      refundStatus: refundStatus ?? this.refundStatus,
      refundFailureReason: refundFailureReason ?? this.refundFailureReason,
      lenderBaseEarning: lenderBaseEarning ?? this.lenderBaseEarning,
      lenderDamageEarning: lenderDamageEarning ?? this.lenderDamageEarning,
      lenderTotalEarning: lenderTotalEarning ?? this.lenderTotalEarning,
      manualPayoutStatus: manualPayoutStatus ?? this.manualPayoutStatus,
      manualPayoutMarkedAt:
          manualPayoutMarkedAt ?? this.manualPayoutMarkedAt,
      manualPayoutMarkedBy:
          manualPayoutMarkedBy ?? this.manualPayoutMarkedBy,
      manualPayoutReference:
          manualPayoutReference ?? this.manualPayoutReference,
      manualPayoutNote: manualPayoutNote ?? this.manualPayoutNote,
      settlementMode: settlementMode ?? this.settlementMode,
      borrowerReviewSubmitted:
          borrowerReviewSubmitted ?? this.borrowerReviewSubmitted,
      borrowerReviewSubmittedAt:
          borrowerReviewSubmittedAt ?? this.borrowerReviewSubmittedAt,
      ownerReviewSubmitted:
          ownerReviewSubmitted ?? this.ownerReviewSubmitted,
      ownerReviewSubmittedAt:
          ownerReviewSubmittedAt ?? this.ownerReviewSubmittedAt,
      reviewGraceEndsAt: reviewGraceEndsAt ?? this.reviewGraceEndsAt,
    );
  }

  /// Marketplace DB model: converts a Firestore borrowRequests/{id} document into the app transaction model.
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
      paymentStatus:
          (data['paymentStatus'] as String?) ??
          AppConstants.paymentStatusPending,
      paymentCompletedAt: _toNullableDate(data['paymentCompletedAt']),
      paymentProvider: (data['paymentProvider'] as String?) ?? '',
      chatId: (data['chatId'] as String?) ?? '',
      handoverCode: (data['handoverCode'] as String?) ?? '',
      returnCode: (data['returnCode'] as String?) ?? '',
      hasUsageFee:
          data['hasUsageFee'] as bool? ??
          ((_toDouble(data['usageFeeAmount']) ?? 0) > 0),
      usageFeeAmount: _toDouble(data['usageFeeAmount']),
      rentalMode: (data['rentalMode'] as String?) ?? '',
      rentalUnitCount: _toInt(data['rentalUnitCount'], fallback: 1),
      dailyRateSnapshot: _toDouble(data['dailyRateSnapshot']),
      hourlyRateSnapshot: _toDouble(data['hourlyRateSnapshot']),
      hasDeposit:
          data['hasDeposit'] as bool? ??
          ((_toDouble(data['depositAmount']) ?? 0) > 0),
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
      minorDeductionAmount: _toDouble(data['minorDeductionAmount']),
      minorIssueReason: (data['minorIssueReason'] as String?) ?? '',
      minorIssuePhotoUrl: (data['minorIssuePhotoUrl'] as String?) ?? '',
      minorIssueReportedAt: _toNullableDate(data['minorIssueReportedAt']),
      minorIssueBorrowerDecision:
          (data['minorIssueBorrowerDecision'] as String?) ??
          AppConstants.minorIssueDecisionPending,
      minorIssueBorrowerRespondedAt: _toNullableDate(
        data['minorIssueBorrowerRespondedAt'],
      ),
      disputeReportId: (data['disputeReportId'] as String?) ?? '',
      disputeReason: (data['disputeReason'] as String?) ?? '',
      disputeEvidenceImageUrl:
          (data['disputeEvidenceImageUrl'] as String?) ?? '',
      disputeReportedAt: _toNullableDate(data['disputeReportedAt']),
      adminResolution:
          (data['adminResolution'] as String?) ??
          AppConstants.adminResolutionPending,
      adminResolutionReason: (data['adminResolutionReason'] as String?) ?? '',
      adminResolvedAt: _toNullableDate(data['adminResolvedAt']),
      adminResolvedBy: (data['adminResolvedBy'] as String?) ?? '',
      depositStatus: _parseDepositStatus(data),
      depositHeldAmount: _toDouble(data['depositHeldAmount']) ?? 0,
      depositRefundAmount: _toDouble(data['depositRefundAmount']) ?? 0,
      depositRefundedAt: _toNullableDate(data['depositRefundedAt']),
      damageDeductionAmount: _toDouble(data['damageDeductionAmount']) ?? 0,
      damageDecision:
          (data['damageDecision'] as String?) ?? AppConstants.damageDecisionNone,
      damageDecisionReason: (data['damageDecisionReason'] as String?) ?? '',
      damageDecidedAt: _toNullableDate(data['damageDecidedAt']),
      xenditRefundId: (data['xenditRefundId'] as String?) ?? '',
      xenditPaymentRequestId:
          (data['xenditPaymentRequestId'] as String?) ?? '',
      xenditPaymentId: (data['xenditPaymentId'] as String?) ?? '',
      xenditInvoiceId: (data['xenditInvoiceId'] as String?) ?? '',
      xenditReferenceId: (data['xenditReferenceId'] as String?) ?? '',
      xenditChannelCode: (data['xenditChannelCode'] as String?) ?? '',
      xenditFailureReason: (data['xenditFailureReason'] as String?) ?? '',
      refundStatus: _parseRefundStatus(data),
      refundFailureReason: (data['refundFailureReason'] as String?) ?? '',
      lenderBaseEarning: _toDouble(data['lenderBaseEarning']) ?? 0,
      lenderDamageEarning: _toDouble(data['lenderDamageEarning']) ?? 0,
      lenderTotalEarning: _toDouble(data['lenderTotalEarning']) ?? 0,
      manualPayoutStatus: _parseManualPayoutStatus(data),
      manualPayoutMarkedAt: _toNullableDate(data['manualPayoutMarkedAt']),
      manualPayoutMarkedBy: (data['manualPayoutMarkedBy'] as String?) ?? '',
      manualPayoutReference:
          (data['manualPayoutReference'] as String?) ?? '',
      manualPayoutNote: (data['manualPayoutNote'] as String?) ?? '',
      settlementMode: (data['settlementMode'] as String?) ?? '',
      borrowerReviewSubmitted:
          data['borrowerReviewSubmitted'] as bool? ?? false,
      borrowerReviewSubmittedAt: _toNullableDate(
        data['borrowerReviewSubmittedAt'],
      ),
      ownerReviewSubmitted: data['ownerReviewSubmitted'] as bool? ?? false,
      ownerReviewSubmittedAt: _toNullableDate(
        data['ownerReviewSubmittedAt'],
      ),
      reviewGraceEndsAt: _toNullableDate(data['reviewGraceEndsAt']),
    );
  }

  /// Marketplace DB model: serializes the borrow request back to Firestore using the same field names as the backend.
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
      'paymentStatus': paymentStatus,
      'paymentCompletedAt': paymentCompletedAt == null
          ? null
          : Timestamp.fromDate(paymentCompletedAt!),
      'paymentProvider': paymentProvider.isEmpty ? null : paymentProvider,
      'chatId': chatId.isEmpty ? null : chatId,
      'handoverCode': handoverCode.isEmpty ? null : handoverCode,
      'returnCode': returnCode.isEmpty ? null : returnCode,
      'hasUsageFee': hasUsageFee,
      'usageFeeAmount': hasUsageFee ? usageFeeAmount : null,
      'rentalMode': rentalMode,
      'rentalUnitCount': rentalUnitCount,
      'dailyRateSnapshot': hasUsageFee ? dailyRateSnapshot : null,
      'hourlyRateSnapshot': hasUsageFee ? hourlyRateSnapshot : null,
      'hasDeposit': hasDeposit,
      'depositAmount': hasDeposit ? depositAmount : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectedAt': rejectedAt == null ? null : Timestamp.fromDate(rejectedAt!),
      'rejectionReason': rejectionReason,
      'pickupConfirmedAt': pickupConfirmedAt == null
          ? null
          : Timestamp.fromDate(pickupConfirmedAt!),
      'handoverConfirmedAt': handoverConfirmedAt == null
          ? null
          : Timestamp.fromDate(handoverConfirmedAt!),
      'returnSubmittedAt': returnSubmittedAt == null
          ? null
          : Timestamp.fromDate(returnSubmittedAt!),
      'returnConfirmedAt': returnConfirmedAt == null
          ? null
          : Timestamp.fromDate(returnConfirmedAt!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'pickupProofImageUrl': pickupProofImageUrl.isEmpty
          ? null
          : pickupProofImageUrl,
      'handoverProofImageUrl': handoverProofImageUrl.isEmpty
          ? null
          : handoverProofImageUrl,
      'returnProofImageUrl': returnProofImageUrl.isEmpty
          ? null
          : returnProofImageUrl,
      'itemConditionBefore': itemConditionBefore.isEmpty
          ? null
          : itemConditionBefore,
      'itemConditionAfter': itemConditionAfter.isEmpty
          ? null
          : itemConditionAfter,
      'returnNotes': returnNotes,
      'ownerReturnNotes': ownerReturnNotes,
      'depositDecision': depositDecision,
      'depositDecisionReason': depositDecisionReason.isEmpty
          ? null
          : depositDecisionReason,
      'depositDecidedAt': depositDecidedAt == null
          ? null
          : Timestamp.fromDate(depositDecidedAt!),
      'minorDeductionAmount': minorDeductionAmount,
      'minorIssueReason': minorIssueReason.isEmpty
          ? null
          : minorIssueReason,
      'minorIssuePhotoUrl': minorIssuePhotoUrl.isEmpty
          ? null
          : minorIssuePhotoUrl,
      'minorIssueReportedAt': minorIssueReportedAt == null
          ? null
          : Timestamp.fromDate(minorIssueReportedAt!),
      'minorIssueBorrowerDecision': minorIssueBorrowerDecision,
      'minorIssueBorrowerRespondedAt':
          minorIssueBorrowerRespondedAt == null
          ? null
          : Timestamp.fromDate(minorIssueBorrowerRespondedAt!),
      'disputeReportId': disputeReportId.isEmpty ? null : disputeReportId,
      'disputeReason': disputeReason.isEmpty ? null : disputeReason,
      'disputeEvidenceImageUrl': disputeEvidenceImageUrl.isEmpty
          ? null
          : disputeEvidenceImageUrl,
      'disputeReportedAt': disputeReportedAt == null
          ? null
          : Timestamp.fromDate(disputeReportedAt!),
      'adminResolution': adminResolution,
      'adminResolutionReason': adminResolutionReason.isEmpty
          ? null
          : adminResolutionReason,
      'adminResolvedAt': adminResolvedAt == null
          ? null
          : Timestamp.fromDate(adminResolvedAt!),
      'adminResolvedBy': adminResolvedBy.isEmpty ? null : adminResolvedBy,
      'depositStatus': depositStatus,
      'depositHeldAmount': depositHeldAmount,
      'depositRefundAmount': depositRefundAmount,
      'depositRefundedAt': depositRefundedAt == null
          ? null
          : Timestamp.fromDate(depositRefundedAt!),
      'damageDeductionAmount': damageDeductionAmount,
      'damageDecision': damageDecision,
      'damageDecisionReason': damageDecisionReason,
      'damageDecidedAt': damageDecidedAt == null
          ? null
          : Timestamp.fromDate(damageDecidedAt!),
      'xenditRefundId': xenditRefundId.isEmpty ? null : xenditRefundId,
      'xenditPaymentRequestId': xenditPaymentRequestId.isEmpty
          ? null
          : xenditPaymentRequestId,
      'xenditPaymentId': xenditPaymentId.isEmpty ? null : xenditPaymentId,
      'xenditInvoiceId': xenditInvoiceId.isEmpty ? null : xenditInvoiceId,
      'xenditReferenceId': xenditReferenceId.isEmpty
          ? null
          : xenditReferenceId,
      'xenditChannelCode': xenditChannelCode.isEmpty
          ? null
          : xenditChannelCode,
      'xenditFailureReason': xenditFailureReason.isEmpty
          ? null
          : xenditFailureReason,
      'refundStatus': refundStatus,
      'refundFailureReason':
          refundFailureReason.isEmpty ? null : refundFailureReason,
      'lenderBaseEarning': lenderBaseEarning,
      'lenderDamageEarning': lenderDamageEarning,
      'lenderTotalEarning': lenderTotalEarning,
      'manualPayoutStatus': manualPayoutStatus,
      'manualPayoutMarkedAt': manualPayoutMarkedAt == null
          ? null
          : Timestamp.fromDate(manualPayoutMarkedAt!),
      'manualPayoutMarkedBy':
          manualPayoutMarkedBy.isEmpty ? null : manualPayoutMarkedBy,
      'manualPayoutReference':
          manualPayoutReference.isEmpty ? null : manualPayoutReference,
      'manualPayoutNote': manualPayoutNote.isEmpty ? null : manualPayoutNote,
      'settlementMode': settlementMode.isEmpty ? null : settlementMode,
      'borrowerReviewSubmitted': borrowerReviewSubmitted,
      'borrowerReviewSubmittedAt': borrowerReviewSubmittedAt == null
          ? null
          : Timestamp.fromDate(borrowerReviewSubmittedAt!),
      'ownerReviewSubmitted': ownerReviewSubmitted,
      'ownerReviewSubmittedAt': ownerReviewSubmittedAt == null
          ? null
          : Timestamp.fromDate(ownerReviewSubmittedAt!),
      'reviewGraceEndsAt': reviewGraceEndsAt == null
          ? null
          : Timestamp.fromDate(reviewGraceEndsAt!),
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

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _parseDepositDecision(Map<String, dynamic> data) {
    final raw = (data['depositDecision'] as String?)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    final hd =
        data['hasDeposit'] as bool? ??
        ((_toDouble(data['depositAmount']) ?? 0) > 0);
    return hd
        ? AppConstants.depositDecisionPending
        : AppConstants.depositDecisionNotRequired;
  }

  static String _parseDepositStatus(Map<String, dynamic> data) {
    final raw = (data['depositStatus'] as String?)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    final hasDeposit =
        data['hasDeposit'] as bool? ??
        ((_toDouble(data['depositAmount']) ?? 0) > 0);
    if (!hasDeposit) return AppConstants.depositStatusNotRequired;
    if (data['paymentStatus'] == AppConstants.paymentStatusCompleted) {
      return AppConstants.depositStatusHeld;
    }
    return '';
  }

  static String _parseRefundStatus(Map<String, dynamic> data) {
    final raw = (data['refundStatus'] as String?)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    return _parseDepositStatus(data) == AppConstants.depositStatusNotRequired
        ? AppConstants.refundStatusNotRequired
        : AppConstants.refundStatusNotStarted;
  }

  static String _parseManualPayoutStatus(Map<String, dynamic> data) {
    final raw = (data['manualPayoutStatus'] as String?)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    return AppConstants.manualPayoutStatusNotReady;
  }
}
