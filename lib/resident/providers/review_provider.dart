// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : review_provider.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
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

  Future<bool> hasUserReviewedServiceRequest({
    required String serviceRequestId,
    required String reviewerId,
  }) {
    return _service.hasUserReviewedServiceRequest(
      serviceRequestId: serviceRequestId,
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

  Future<void> createServiceReview({
    required ServiceRequestModel serviceRequest,
    required String reviewerId,
    required String reviewerName,
    required int rating,
    required String comment,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.createServiceReview(
        serviceRequest: serviceRequest,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        rating: rating,
        comment: comment,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
