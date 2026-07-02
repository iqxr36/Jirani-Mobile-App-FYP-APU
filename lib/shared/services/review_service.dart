import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/review_model.dart';

/// Blind-review submission for completed borrows.
///
/// After a borrow reaches [AppConstants.borrowStatusCompleted], each party may
/// submit one anonymous review. Reviews are stored with `visible: false` and
/// a `publishAfter` timestamp (3-day grace from completion). The Cloud Function
/// in `functions/src/review_publish.ts` publishes both reviews when grace ends
/// or when both sides have submitted — whichever comes first.
class ReviewService {
  ReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    bool useCallableSubmission = true,
  })
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions,
      _useCallableSubmission = useCallableSubmission;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;
  final bool _useCallableSubmission;

  static const Duration _reviewGracePeriod = Duration(days: 3);

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _borrowRequests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  /// Reviews feature: deterministic id prevents one user from reviewing the same borrow request more than once.
  static String reviewDocId(String borrowRequestId, String reviewerId) =>
      '${borrowRequestId.replaceAll('/', '_')}_$reviewerId';

  /// Reviews feature: checks whether the current resident has already submitted their one-time review.
  Future<bool> hasUserReviewedBorrowRequest({
    required String borrowRequestId,
    required String reviewerId,
  }) async {
    final snap = await _reviews
        .doc(reviewDocId(borrowRequestId, reviewerId))
        .get();
    return snap.exists;
  }

  /// Public profile reviews: streams published visible reviews for a resident.
  Stream<List<ReviewModel>> watchReviewsForUser(String userId) {
    return _reviews
        .where('revieweeId', isEqualTo: userId)
        .where('visible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((d) => ReviewModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Reviews feature: creates a hidden review and marks the borrow request side as reviewed in one transaction.
  Future<void> createReview({
    required BorrowRequest borrowRequest,
    required String reviewerId,
    required String reviewerName,
    required String role,
    required int rating,
    required String comment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != reviewerId) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    if (borrowRequest.status != AppConstants.borrowStatusCompleted) {
      throw Exception('Only completed borrow requests can be reviewed.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }

    final reviewee = _resolveReviewee(
      borrowRequest: borrowRequest,
      reviewerId: reviewerId,
      role: role,
    );

    final rid = reviewDocId(borrowRequest.id, reviewerId);
    final reviewRef = _reviews.doc(rid);
    final requestRef = _borrowRequests.doc(borrowRequest.id);
    var debugStage = 'starting review transaction';

    if (_useCallableSubmission) {
      try {
        final callable = (_functions ?? FirebaseFunctions.instance)
            .httpsCallable('createMarketplaceReview');
        await callable.call<void>({
          'borrowRequestId': borrowRequest.id,
          'reviewerName': reviewerName,
          'role': role,
          'rating': rating,
          'comment': comment.trim(),
        });
        return;
      } on FirebaseFunctionsException catch (e) {
        debugPrint(
          'ReviewService.createReview callable failed: '
          'code=${e.code}, message=${e.message}, '
          'borrowRequestId=${borrowRequest.id}, reviewId=$rid, '
          'reviewerId=$reviewerId, role=$role, '
          'ownerId=${borrowRequest.ownerId}, borrowerId=${borrowRequest.borrowerId}, '
          'status=${borrowRequest.status}, '
          'borrowerReviewSubmitted=${borrowRequest.borrowerReviewSubmitted}, '
          'ownerReviewSubmitted=${borrowRequest.ownerReviewSubmitted}',
        );
        if (e.code != 'internal' &&
            e.code != 'unavailable' &&
            e.code != 'not-found') {
          throw Exception(e.message ?? 'Failed to submit review.');
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'ReviewService.createReview callable unavailable: '
          'code=${e.code}, message=${e.message}',
        );
      }
    }

    try {
      await _firestore.runTransaction((txn) async {
        debugStage = 'read borrow request';
        final reqSnap = await txn.get(requestRef);
        final reqData = reqSnap.data();
        if (reqData == null) throw Exception('Borrow request not found.');
        final req = BorrowRequest.fromMap(reqSnap.id, reqData);
        if (req.status != AppConstants.borrowStatusCompleted) {
          throw Exception('Only completed borrow requests can be reviewed.');
        }
        _resolveReviewee(
          borrowRequest: req,
          reviewerId: reviewerId,
          role: role,
        );
        final alreadyReviewed =
            role == AppConstants.reviewRoleBorrowerToOwner
            ? req.borrowerReviewSubmitted
            : req.ownerReviewSubmitted;
        if (alreadyReviewed) {
          throw Exception(
            'You already submitted a review for this borrow request.',
          );
        }

        debugStage = 'read existing review';
        final existing = await txn.get(reviewRef);
        if (existing.exists) {
          throw Exception(
            'You already submitted a review for this borrow request.',
          );
        }

        final publishAfter = _publishAfter(req);
        final flagField = role == AppConstants.reviewRoleBorrowerToOwner
            ? 'borrowerReviewSubmitted'
            : 'ownerReviewSubmitted';
        final flagAtField = role == AppConstants.reviewRoleBorrowerToOwner
            ? 'borrowerReviewSubmittedAt'
            : 'ownerReviewSubmittedAt';

        debugStage = 'write hidden review and borrow review flag';
        txn.set(reviewRef, {
          'borrowRequestId': req.id,
          'itemId': req.itemId,
          'reviewerId': reviewerId,
          'reviewerName': reviewerName,
          'revieweeId': reviewee.id,
          'revieweeName': reviewee.name,
          'rating': rating,
          'comment': comment.trim(),
          'role': role,
          'visible': false,
          'status': AppConstants.reviewStatusHidden,
          'publishAfter': Timestamp.fromDate(publishAfter),
          'publishedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        txn.update(requestRef, {
          flagField: true,
          flagAtField: FieldValue.serverTimestamp(),
          'reviewGraceEndsAt': Timestamp.fromDate(publishAfter),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugStage = 'commit review transaction';
      });
      // Eligible reviews are published server-side when borrow request flags update.
    } on FirebaseException catch (e) {
      debugPrint(
        'ReviewService.createReview failed: '
        'stage=$debugStage, code=${e.code}, message=${e.message}, '
        'borrowRequestId=${borrowRequest.id}, reviewId=$rid, '
        'reviewerId=$reviewerId, role=$role, '
        'ownerId=${borrowRequest.ownerId}, borrowerId=${borrowRequest.borrowerId}, '
        'status=${borrowRequest.status}, '
        'borrowerReviewSubmitted=${borrowRequest.borrowerReviewSubmitted}, '
        'ownerReviewSubmitted=${borrowRequest.ownerReviewSubmitted}',
      );
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for reviews.',
        );
      }
      throw Exception(e.message ?? 'Failed to submit review.');
    }
  }

  /// Reviews feature: validates reviewer role and identifies the resident being reviewed.
  _Reviewee _resolveReviewee({
    required BorrowRequest borrowRequest,
    required String reviewerId,
    required String role,
  }) {
    if (role == AppConstants.reviewRoleBorrowerToOwner) {
      if (reviewerId != borrowRequest.borrowerId) {
        throw Exception('Only the borrower can submit this review.');
      }
      return _Reviewee(borrowRequest.ownerId, borrowRequest.ownerName);
    }
    if (role == AppConstants.reviewRoleOwnerToBorrower) {
      if (reviewerId != borrowRequest.ownerId) {
        throw Exception('Only the owner can submit this review.');
      }
      return _Reviewee(borrowRequest.borrowerId, borrowRequest.borrowerName);
    }
    throw Exception('Invalid review role.');
  }

  /// Reviews feature: calculates the 3-day blind review publish deadline from transaction completion.
  DateTime _publishAfter(BorrowRequest borrowRequest) {
    return (borrowRequest.completedAt ?? borrowRequest.updatedAt).add(
      _reviewGracePeriod,
    );
  }
}

/// Reviews helper model: stores the review target id/name after role validation.
class _Reviewee {
  const _Reviewee(this.id, this.name);

  final String id;
  final String name;
}
