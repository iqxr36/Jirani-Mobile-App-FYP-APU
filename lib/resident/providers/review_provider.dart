import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/shared/services/review_service.dart';

// Review feature: submits one-time marketplace reviews and streams public review lists.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewService? service})
    : _service = service ?? ReviewService();

  final ReviewService _service;

  bool _busy = false;
  bool get isSubmitting => _busy;

  // Review feature: streams published reviews for a resident profile.
  Stream<List<ReviewModel>> reviewsForUser(String userId) =>
      _service.watchReviewsForUser(userId);

  // Review feature: checks whether this borrow request already has a review from the current user.
  Future<bool> hasUserReviewedBorrowRequest({
    required String borrowRequestId,
    required String reviewerId,
  }) {
    return _service.hasUserReviewedBorrowRequest(
      borrowRequestId: borrowRequestId,
      reviewerId: reviewerId,
    );
  }

  // Review feature: creates the borrower's or lender's one-time review after transaction completion.
  Future<void> createReview({
    required BorrowRequest borrowRequest,
    required String reviewerId,
    required String reviewerName,
    required String role,
    required int rating,
    required String comment,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.createReview(
        borrowRequest: borrowRequest,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        role: role,
        rating: rating,
        comment: comment,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
