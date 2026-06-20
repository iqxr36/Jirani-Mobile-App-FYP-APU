import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/review_model.dart';

class ReviewService {
  ReviewService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const Duration _reviewGracePeriod = Duration(days: 3);
  static const double _trustedResidentThreshold = 4.5;
  static const double _lowTrustThreshold = 3.5;
  static const int _trustedResidentMinimumReviews = 3;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _borrowRequests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

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
    var shouldPublish = false;

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

        final existing = await txn.get(reviewRef);
        if (existing.exists) {
          throw Exception(
            'You already submitted a review for this borrow request.',
          );
        }

        final revieweeSnap = await txn.get(_users.doc(reviewee.id));
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
        final otherFlagField = role == AppConstants.reviewRoleBorrowerToOwner
            ? 'ownerReviewSubmitted'
            : 'borrowerReviewSubmitted';
        final otherSubmitted = reqData[otherFlagField] as bool? ?? false;
        shouldPublish =
            otherSubmitted || !DateTime.now().isBefore(publishAfter);

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

      if (shouldPublish) {
        await publishEligibleReviewsForBorrowRequest(borrowRequest);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for reviews.',
        );
      }
      throw Exception(e.message ?? 'Failed to submit review.');
    }
  }

  Future<void> publishEligibleReviewsForBorrowRequest(
    BorrowRequest borrowRequest,
  ) async {
    if (borrowRequest.status != AppConstants.borrowStatusCompleted) return;

    final requestSnap = await _borrowRequests.doc(borrowRequest.id).get();
    final requestData = requestSnap.data();
    if (requestData == null) return;
    final request = BorrowRequest.fromMap(requestSnap.id, requestData);
    if (request.status != AppConstants.borrowStatusCompleted) return;

    final publishAfter = _publishAfter(request);
    final borrowerSubmitted =
        requestData['borrowerReviewSubmitted'] as bool? ?? false;
    final ownerSubmitted =
        requestData['ownerReviewSubmitted'] as bool? ?? false;
    if (!borrowerSubmitted && !ownerSubmitted) return;

    final hasBothReviews = borrowerSubmitted && ownerSubmitted;
    final graceExpired = !DateTime.now().isBefore(publishAfter);
    if (!hasBothReviews && !graceExpired) return;

    final candidateReviewerIds = <String>[
      if (borrowerSubmitted) request.borrowerId,
      if (ownerSubmitted) request.ownerId,
    ];
    for (final reviewerId in candidateReviewerIds) {
      try {
        await _reviews.doc(reviewDocId(request.id, reviewerId)).update({
          'visible': true,
          'status': AppConstants.reviewStatusPublished,
          'publishedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        if (e.code != 'not-found' && e.code != 'failed-precondition') {
          rethrow;
        }
      }
    }

    await _borrowRequests.doc(request.id).update({
      'reviewsPublishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final publishedSnap = await _reviews
        .where('borrowRequestId', isEqualTo: request.id)
        .where('visible', isEqualTo: true)
        .get();
    final newlyPublished = publishedSnap.docs
        .map((doc) => _PublishedReview.fromMap(doc.id, doc.data()))
        .toList();
    final triggerByReviewee = <String, String>{};
    for (final review in newlyPublished) {
      triggerByReviewee[review.revieweeId] = review.id;
      await _createOneStarReviewReportIfNeeded(review, request);
    }

    for (final entry in triggerByReviewee.entries) {
      await _recalculateTrustScore(
        userId: entry.key,
        triggerReviewId: entry.value,
      );
    }
  }

  Future<void> _recalculateTrustScore({
    required String userId,
    required String triggerReviewId,
  }) async {
    final reviewsSnap = await _reviews
        .where('revieweeId', isEqualTo: userId)
        .where('visible', isEqualTo: true)
        .get();

    final visibleReviewDocs = reviewsSnap.docs;
    if (visibleReviewDocs.isEmpty) return;

    final now = DateTime.now();
    var weightedTotal = 0.0;
    var weightSum = 0.0;
    for (final doc in visibleReviewDocs) {
      final review = ReviewModel.fromMap(doc.id, doc.data());
      final ageDays = now.difference(review.createdAt).inDays.clamp(0, 3650);
      final weight = 1 / (1 + (ageDays / 90));
      weightedTotal += review.rating * weight;
      weightSum += weight;
    }

    final totalReviews = visibleReviewDocs.length;
    final trustScore = weightSum == 0 ? 0.0 : weightedTotal / weightSum;
    final trustedResident =
        trustScore >= _trustedResidentThreshold &&
        totalReviews >= _trustedResidentMinimumReviews;
    final accountFlagged = trustScore < _lowTrustThreshold;
    final flagReason = accountFlagged
        ? 'Community Trust Score dropped below ${_lowTrustThreshold.toStringAsFixed(1)}.'
        : '';

    await _users.doc(userId).update({
      'reputationScore': trustScore,
      'communityTrustScore': trustScore,
      'totalReviews': totalReviews,
      'trustedResident': trustedResident,
      'accountFlagged': accountFlagged,
      'trustFlagReason': flagReason,
      'lastTrustReviewId': triggerReviewId,
      'trustScoreUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (accountFlagged) {
      await _createLowTrustReportIfNeeded(
        reportedUserId: userId,
        trustScore: trustScore,
        totalReviews: totalReviews,
      );
    }
  }

  Future<void> _createOneStarReviewReportIfNeeded(
    _PublishedReview review,
    BorrowRequest borrowRequest,
  ) async {
    final looksLikeDamageCase =
        review.rating == 1 &&
        review.role == AppConstants.reviewRoleOwnerToBorrower &&
        borrowRequest.itemConditionAfter !=
            AppConstants.borrowConditionAfterSame;
    if (!looksLikeDamageCase) return;

    await _createAdminReportIfNeeded(
      reportId: 'trust_damage_${review.id}',
      type: AppConstants.reportTypeDamagedItem,
      relatedBorrowRequestId: borrowRequest.id,
      itemId: borrowRequest.itemId,
      reportedUserId: review.revieweeId,
      reportedUserName: review.revieweeName,
      title: '1-star damage review',
      description:
          '${review.reviewerName} rated ${review.revieweeName} 1 star after an item return issue. Comment: ${review.comment.isEmpty ? 'No comment provided.' : review.comment}',
    );
  }

  Future<void> _createLowTrustReportIfNeeded({
    required String reportedUserId,
    required double trustScore,
    required int totalReviews,
  }) async {
    final reportedSnap = await _users.doc(reportedUserId).get();
    final reported = reportedSnap.data() ?? const <String, dynamic>{};
    await _createAdminReportIfNeeded(
      reportId: 'trust_low_$reportedUserId',
      type: AppConstants.reportTypeUserMisconduct,
      relatedBorrowRequestId: '',
      itemId: '',
      reportedUserId: reportedUserId,
      reportedUserName: _displayName(reported),
      title: 'Low Community Trust Score',
      description:
          '${_displayName(reported)} has a Community Trust Score of ${trustScore.toStringAsFixed(2)} from $totalReviews published reviews.',
    );
  }

  Future<void> _createAdminReportIfNeeded({
    required String reportId,
    required String type,
    required String relatedBorrowRequestId,
    required String itemId,
    required String reportedUserId,
    required String reportedUserName,
    required String title,
    required String description,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final reportRef = _reports.doc(reportId);
    final existing = await reportRef.get();
    if (existing.exists) return;

    final reporterSnap = await _users.doc(uid).get();
    final reporter = reporterSnap.data();
    if (reporter == null) return;

    await reportRef.set({
      'type': type,
      'relatedBorrowRequestId': relatedBorrowRequestId,
      'itemId': itemId,
      'reporterId': uid,
      'reporterName': _displayName(reporter),
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'communityId': (reporter['communityId'] as String?) ?? '',
      'communityName': (reporter['communityName'] as String?) ?? '',
      'title': title,
      'description': description,
      'status': AppConstants.reportStatusOpen,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  String _displayName(Map<String, dynamic> data) {
    final fullName = (data['fullName'] as String?)?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final first = (data['firstName'] as String?)?.trim() ?? '';
    final last = (data['lastName'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'Resident' : combined;
  }
}

class _Reviewee {
  const _Reviewee(this.id, this.name);

  final String id;
  final String name;
}

class _PublishedReview {
  const _PublishedReview({
    required this.id,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.role,
  });

  final String id;
  final String reviewerName;
  final String revieweeId;
  final String revieweeName;
  final int rating;
  final String comment;
  final String role;

  factory _PublishedReview.fromMap(String id, Map<String, dynamic> data) {
    return _PublishedReview(
      id: id,
      reviewerName: (data['reviewerName'] as String?) ?? 'Resident',
      revieweeId: (data['revieweeId'] as String?) ?? '',
      revieweeName: (data['revieweeName'] as String?) ?? 'Resident',
      rating: ReviewModel.fromMap(id, data).rating,
      comment: (data['comment'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
    );
  }
}
