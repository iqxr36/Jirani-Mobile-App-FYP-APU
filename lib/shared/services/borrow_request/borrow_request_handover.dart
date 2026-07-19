// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request_handover.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../borrow_request_service.dart';

mixin _BorrowRequestHandoverMixin on _BorrowRequestServiceBase {
  Future<String?> _uploadProofImage({
    required String requestId,
    required String uid,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Proof image file not found.');
    }
    final fileName = localPath.split(RegExp(r'[/\\]')).last;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageBorrowRequestProofsPath)
        .child(requestId)
        .child(uid)
        .child('${ts}_$fileName');
    await ref.putFile(
      file,
      SettableMetadata(contentType: _proofImageContentType(fileName)),
    );
    return ref.getDownloadURL();
  }

  static String _proofImageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  /// Borrower: pickupReady → active after entering the lender's handover code.
  Future<void> confirmPickupReady({
    required String requestId,
    required String borrowerId,
    required String handoverCode,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can confirm pickup.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can confirm pickup.');
      }
      if (request.status != AppConstants.borrowStatusPickupReady) {
        throw Exception(
          'Pickup can only be confirmed after the lender starts handover.',
        );
      }
      if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
        throw Exception('Complete payment before coordinating handover.');
      }
      final expectedCode = request.handoverCode.trim();
      if (expectedCode.isEmpty || handoverCode.trim() != expectedCode) {
        throw Exception('Invalid handover code.');
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusActive,
        'handoverConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to confirm pickup.');
    }
  }

  /// Owner: approved → pickupReady by starting the in-person handover.
  Future<void> confirmHandover({
    required String requestId,
    required String ownerId,
    required String conditionBefore,
    String? localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can confirm handover.');
    }
    final cond = conditionBefore.trim();
    if (cond.isEmpty) {
      throw Exception('Item condition before handover is required.');
    }
    final allowedBefore = {
      AppConstants.borrowConditionBeforeExcellent,
      AppConstants.borrowConditionBeforeGood,
      AppConstants.borrowConditionBeforeFair,
      AppConstants.borrowConditionBeforeDamaged,
    };
    if (!allowedBefore.contains(cond)) {
      throw Exception('Invalid condition before handover.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can confirm handover.');
      }
      if (request.status != AppConstants.borrowStatusApproved) {
        throw Exception(
          'Handover can only start after this request is approved.',
        );
      }
      if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
        throw Exception('Payment must be completed before handover.');
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(
          requestId: requestId,
          uid: ownerId,
          localPath: localProofPath.trim(),
        );
      }

      final batch = _firestore.batch();
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusPickupReady,
        'pickupConfirmedAt': FieldValue.serverTimestamp(),
        'handoverCode': request.handoverCode.trim().isEmpty
            ? MarketplaceBorrowFlow.generateFourDigitCode()
            : request.handoverCode,
        'itemConditionBefore': cond,
        'updatedAt': FieldValue.serverTimestamp(),
        'handoverProofImageUrl': ?proofUrl,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to confirm handover.');
    }
  }

  /// Borrower: active → returnSubmitted
}
