import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  ReviewService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const Duration _reviewGracePeriod = Duration(days: 3);

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _borrowRequests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  static String reviewDocId(String borrowRequestId, String reviewerId) =>
      '${borrowRequestId.replaceAll('/', '_')}_$reviewerId';

  Future<bool> hasUserReviewedBorrowRequest({
    required String borrowRequestId,
    required String reviewerId,
  }) async {
    final snap = await _reviews
        .doc(reviewDocId(borrowRequestId, reviewerId))
        .get();
    return snap.exists;
  }

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

    try {
      await _firestore.runTransaction((txn) async {
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

        final existing = await txn.get(reviewRef);
        if (existing.exists) {
          throw Exception(
            'You already submitted a review for this borrow request.',
          );
        }

        final revieweeSnap = await txn.get(
          _firestore
              .collection(AppConstants.publicProfilesCollection)
              .doc(reviewee.id),
        );
        if (!revieweeSnap.exists) {
          throw Exception(
            'Missing user profile for the person being reviewed.',
          );
        }

        final publishAfter = _publishAfter(req);
        final flagField = role == AppConstants.reviewRoleBorrowerToOwner
            ? 'borrowerReviewSubmitted'
            : 'ownerReviewSubmitted';
        final flagAtField = role == AppConstants.reviewRoleBorrowerToOwner
            ? 'borrowerReviewSubmittedAt'
            : 'ownerReviewSubmittedAt';

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
      });
      // Eligible reviews are published server-side when borrow request flags update.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for reviews.',
        );
      }
      throw Exception(e.message ?? 'Failed to submit review.');
    }
  }

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

  DateTime _publishAfter(BorrowRequest borrowRequest) {
    return (borrowRequest.completedAt ?? borrowRequest.updatedAt).add(
      _reviewGracePeriod,
    );
  }
}

class _Reviewee {
  const _Reviewee(this.id, this.name);

  final String id;
  final String name;
}
