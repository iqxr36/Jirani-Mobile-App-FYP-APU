import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/models/borrow_request.dart';
import 'package:jirani/models/review_model.dart';

class ReviewService {
  ReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _borrowRequests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  static String reviewDocId(String borrowRequestId, String reviewerId) =>
      '${borrowRequestId.replaceAll('/', '_')}_$reviewerId';

  Future<bool> hasUserReviewedBorrowRequest({
    required String borrowRequestId,
    required String reviewerId,
  }) async {
    final snap = await _reviews.doc(reviewDocId(borrowRequestId, reviewerId)).get();
    return snap.exists;
  }

  Stream<List<ReviewModel>> watchReviewsForUser(String userId) {
    return _reviews.where('revieweeId', isEqualTo: userId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList();
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

    late final String revieweeId;
    late final String revieweeName;
    if (role == AppConstants.reviewRoleBorrowerToOwner) {
      if (reviewerId != borrowRequest.borrowerId) {
        throw Exception('Only the borrower can submit this review.');
      }
      revieweeId = borrowRequest.ownerId;
      revieweeName = borrowRequest.ownerName;
    } else if (role == AppConstants.reviewRoleOwnerToBorrower) {
      if (reviewerId != borrowRequest.ownerId) {
        throw Exception('Only the owner can submit this review.');
      }
      revieweeId = borrowRequest.borrowerId;
      revieweeName = borrowRequest.borrowerName;
    } else {
      throw Exception('Invalid review role.');
    }

    final rid = reviewDocId(borrowRequest.id, reviewerId);
    final reviewRef = _reviews.doc(rid);
    final requestRef = _borrowRequests.doc(borrowRequest.id);
    final userRef = _users.doc(revieweeId);

    try {
      await _firestore.runTransaction((txn) async {
        final reqSnap = await txn.get(requestRef);
        final reqData = reqSnap.data();
        if (reqData == null) throw Exception('Borrow request not found.');
        final req = BorrowRequest.fromMap(reqSnap.id, reqData);
        if (req.status != AppConstants.borrowStatusCompleted) {
          throw Exception('Only completed borrow requests can be reviewed.');
        }
        if (role == AppConstants.reviewRoleBorrowerToOwner) {
          if (reviewerId != req.borrowerId) {
            throw Exception('Only the borrower can submit this review.');
          }
        } else if (role == AppConstants.reviewRoleOwnerToBorrower) {
          if (reviewerId != req.ownerId) {
            throw Exception('Only the owner can submit this review.');
          }
        } else {
          throw Exception('Invalid review role.');
        }

        final existing = await txn.get(reviewRef);
        if (existing.exists) {
          throw Exception('You already submitted a review for this borrow request.');
        }

        final userSnap = await txn.get(userRef);
        if (!userSnap.exists) {
          throw Exception('Missing user profile for the person being reviewed.');
        }
        final u = userSnap.data();

        txn.set(reviewRef, {
          'borrowRequestId': req.id,
          'itemId': req.itemId,
          'reviewerId': reviewerId,
          'reviewerName': reviewerName,
          'revieweeId': revieweeId,
          'revieweeName': revieweeName,
          'rating': rating,
          'comment': comment.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        final oldScore = (u?['reputationScore'] as num?)?.toDouble() ?? 0;
        final oldTotal = (u?['totalReviews'] as num?)?.toInt() ?? 0;
        final newTotal = oldTotal + 1;
        final newScore = ((oldScore * oldTotal) + rating) / newTotal;

        txn.update(userRef, {
          'reputationScore': newScore,
          'totalReviews': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for reviews.');
      }
      throw Exception(e.message ?? 'Failed to submit review.');
    }
  }
}
