part of '../admin_service.dart';

mixin _AdminServiceVerificationMixin on _AdminServiceBase {
  Future<VerificationRequest?> getVerificationRequestById(
    String requestId,
  ) async {
    debugPrint('[AdminService][getById] requestId=$requestId');
    final doc = await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId)
        .get();
    final data = doc.data();
    if (data == null) return null;
    final mapped = VerificationRequest.fromMap({...data, 'id': doc.id});
    debugPrint(
      '[AdminService][getById] mapped docId=${doc.id} requestId=${mapped.id} residentUid=${mapped.userId} status=${mapped.status}',
    );
    return mapped;
  }

  Future<void> approveVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
    ExtractedDocumentData? reviewedOcrData,
  }) async {
    if (requestId.trim().isEmpty) {
      throw Exception('Verification request ID is missing.');
    }
    if (residentUid.trim().isEmpty) {
      throw Exception(
        'Resident user ID is missing from this verification request.',
      );
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }

    debugPrint(
      '[AdminService][approve] requestId=$requestId residentUid=$residentUid adminUid=$adminUid',
    );
    final batch = _firestore.batch();
    final requestRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId);
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(residentUid);
    final logRef = _firestore
        .collection(AppConstants.activityLogsCollection)
        .doc();
    debugPrint('[AdminService][approve] requestRef=${requestRef.path}');
    debugPrint('[AdminService][approve] userRef=${userRef.path}');

    final requestUpdates = <String, dynamic>{
      'status': AppConstants.verificationVerified,
      'adminStatus': AppConstants.adminStatusConfirmed,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reviewedOcrData != null) {
      requestUpdates.addAll(_reviewedOcrUpdates(reviewedOcrData, adminUid));
    }

    batch.update(requestRef, requestUpdates);
    batch.update(userRef, {
      'verificationStatus': AppConstants.verificationVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(logRef, {
      'type': AppConstants.activityVerificationApproved,
      'actorId': adminUid,
      'targetUserId': residentUid,
      'requestId': requestId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AdminService][approve] batch commit started');
    try {
      await batch.commit();
      debugPrint('Approve batch committed successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin verification updates.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
    required String rejectionReason,
  }) async {
    if (requestId.trim().isEmpty) {
      throw Exception('Verification request ID is missing.');
    }
    if (residentUid.trim().isEmpty) {
      throw Exception(
        'Resident user ID is missing from this verification request.',
      );
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    final reason = rejectionReason.trim();
    if (reason.isEmpty) {
      throw Exception('Rejection reason is required.');
    }

    debugPrint(
      '[AdminService][reject] requestId=$requestId residentUid=$residentUid adminUid=$adminUid reason="$reason"',
    );
    final batch = _firestore.batch();
    final requestRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId);
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(residentUid);
    final logRef = _firestore
        .collection(AppConstants.activityLogsCollection)
        .doc();
    debugPrint('[AdminService][reject] requestRef=${requestRef.path}');
    debugPrint('[AdminService][reject] userRef=${userRef.path}');

    batch.update(requestRef, {
      'status': AppConstants.verificationRejected,
      'adminStatus': AppConstants.adminStatusRejected,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'verificationStatus': AppConstants.verificationRejected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(logRef, {
      'type': AppConstants.activityVerificationRejected,
      'actorId': adminUid,
      'targetUserId': residentUid,
      'requestId': requestId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AdminService][reject] batch commit started');
    try {
      await batch.commit();
      debugPrint('Reject batch committed successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin verification updates.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Map<String, dynamic> _reviewedOcrUpdates(
    ExtractedDocumentData data,
    String adminUid,
  ) {
    return <String, dynamic>{
      'documentType': data.type.name,
      'ocrText': data.fullText,
      'ocrFields': data.toFieldMap(),
      'extractedFields': _reviewedExtractedFields(data),
      'ocrStructuredData': data.toMap(),
      'ocrReviewedAt': FieldValue.serverTimestamp(),
      'ocrReviewedBy': adminUid,
    };
  }

  Map<String, dynamic> _reviewedExtractedFields(ExtractedDocumentData data) {
    final fields = <String, dynamic>{};
    void add(String key, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      fields[key] = <String, dynamic>{
        'value': trimmed,
        'confidence': 1.0,
        'source': 'admin_review',
      };
    }

    switch (data.type) {
      case DocumentType.tenancyAgreement:
        add('tenant_name', data.tenantName);
        add('landlord_name', data.landlordName);
        add('unit_number', data.unitNumber);
        add('agreement_date', data.agreementDate);
        add('property_address', data.propertyAddress);
        break;
      case DocumentType.utilityBill:
        add('account_number', data.accountNumber);
        add('bill_date', data.billDate);
        add('bill_holder_name', data.billHolderName ?? data.tenantName);
        add('due_date', data.dueDate);
        add('service_address', data.serviceAddress ?? data.propertyAddress);
        add('total_amount', data.totalAmount ?? data.amount);
        add('utility_issuer_or_provider', data.utilityProvider);
        add('utility_type', data.utilityType ?? data.billType);
        break;
      case DocumentType.accessCard:
      case DocumentType.otherProof:
      case DocumentType.unknown:
        add('resident_name', data.residentName ?? data.tenantName);
        add('unit_number', data.unitNumber);
        add('property_address', data.propertyAddress);
        add('issuer', data.issuer);
        add('document_date', data.documentDate);
        add('card_number', data.cardNumber);
        add('summary', data.summary);
        break;
    }
    return fields;
  }
}
