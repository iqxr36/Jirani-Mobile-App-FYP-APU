part of '../public_resident_profile_view.dart';

class _PublicProfileContent extends StatelessWidget {
  const _PublicProfileContent({required this.user});

  final PublicResidentProfile user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: context.read<ReviewProvider>().reviewsForUser(user.uid),
      builder: (context, reviewSnapshot) {
        final reviews = reviewSnapshot.data ?? const <ReviewModel>[];
        final lenderReviews = reviews
            .where((r) => r.role == AppConstants.reviewRoleBorrowerToOwner)
            .toList();
        final borrowerReviews = reviews
            .where((r) => r.role == AppConstants.reviewRoleOwnerToBorrower)
            .toList();
        final lentCount = user.completedLendings < lenderReviews.length
            ? lenderReviews.length
            : user.completedLendings;
        final borrowedCount = user.completedBorrowings < borrowerReviews.length
            ? borrowerReviews.length
            : user.completedBorrowings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdentityPanel(user: user, reviews: reviews, lentCount: lentCount),
            const SizedBox(height: 14),
            _TrustBreakdown(
              user: user,
              borrowedCount: borrowedCount,
              lenderReviews: lenderReviews,
              borrowerReviews: borrowerReviews,
            ),
            const SizedBox(height: 14),
            _PublicListingsSection(ownerId: user.uid),
            const SizedBox(height: 14),
            _PublicServicesSection(
              providerId: user.uid,
              communityId: user.communityId,
            ),
            const SizedBox(height: 14),
            _AnonymousReviewsSection(
              reviews: reviews.take(4).toList(),
              isLoading:
                  reviewSnapshot.connectionState == ConnectionState.waiting &&
                  reviews.isEmpty,
              hasError: reviewSnapshot.hasError,
              errorText: reviewSnapshot.error?.toString(),
            ),
          ],
        );
      },
    );
  }
}
