// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request_service.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

/// Marketplace borrow lifecycle orchestration (client-side).
///
/// Status flow (happy path):
/// `pending` → owner `approved` → borrower payment `completed` → owner
/// `pickupReady` → borrower `active` (handover) → borrower `returnSubmitted`
/// → owner `completed` (or `minorIssuePending` / `disputed` branches).
///
/// Side paths: owner `rejected`, borrower `cancelled` (from `pending` only).
/// Proof images upload to Storage; status transitions are enforced in Firestore
/// rules (`firestore_rules/04_borrow.functions.rules`) and mirrored here.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/marketplace_borrow_flow.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/borrow_request.dart';

part 'borrow_request/borrow_request_queries.dart';
part 'borrow_request/borrow_request_lifecycle.dart';
part 'borrow_request/borrow_request_handover.dart';
part 'borrow_request/borrow_request_return.dart';
part 'borrow_request/borrow_request_disputes.dart';

abstract class _BorrowRequestServiceBase {
  _BorrowRequestServiceBase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _storageOverride = storage;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage? _storageOverride;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(AppConstants.reportsCollection);

  /// Marketplace deposit: calls the backend resolver so refunds happen server-side, never directly in Flutter.
  Future<void> _resolveMarketplaceDeposit({
    required String borrowRequestId,
    required String decision,
    required double damageDeductionAmount,
    required String reason,
    String reportId = '',
  }) async {
    final callable = _functions.httpsCallable('resolveMarketplaceDeposit');
    await callable.call<void>({
      'borrowRequestId': borrowRequestId,
      'decision': decision,
      'damageDeductionAmount': damageDeductionAmount,
      'reason': reason,
      'reportId': reportId,
    });
  }

  /// Marketplace deposit: confirms a borrow request was paid through a managed provider before resolving held deposit money.
  bool _hasCompletedManagedPayment(BorrowRequest request) {
    return request.paymentProvider == AppConstants.paymentProviderXendit &&
        request.paymentStatus == AppConstants.paymentStatusCompleted;
  }
}

/// Marketplace service: combines query, lifecycle, handover, return, and dispute mixins for borrow requests.
class BorrowRequestService extends _BorrowRequestServiceBase
    with
        _BorrowRequestQueriesMixin,
        _BorrowRequestLifecycleMixin,
        _BorrowRequestHandoverMixin,
        _BorrowRequestDisputeMixin,
        _BorrowRequestReturnMixin {
  BorrowRequestService({
    super.auth,
    super.firestore,
    super.functions,
    super.storage,
  });
}
