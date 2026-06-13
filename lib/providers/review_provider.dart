import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewService? service})
    : _service = service ?? ReviewService();

  final ReviewService _service;

  bool _busy = false;
  bool get isSubmitting => _busy;

  Stream<List<ReviewModel>> reviewsForUser(String userId) =>
      _service.watchReviewsForUser(userId);

  Future<bool> hasUserReviewedBorrowRequest({
    required String borrowRequestId,
    required String reviewerId,
  }) {
    return _service.hasUserReviewedBorrowRequest(
      borrowRequestId: borrowRequestId,
      reviewerId: reviewerId,
    );
  }

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
