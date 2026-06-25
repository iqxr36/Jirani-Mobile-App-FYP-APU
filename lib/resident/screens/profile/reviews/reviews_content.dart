part of '../resident_reviews_view.dart';

class _ReviewsContent extends StatelessWidget {
  const _ReviewsContent({
    required this.user,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final AppUser user;
  final _ReviewTab selectedTab;
  final ValueChanged<_ReviewTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: context.read<ReviewProvider>().reviewsForUser(user.uid),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ReviewModel>[];
        final lendingReviews = reviews
            .where((r) => r.role == AppConstants.reviewRoleBorrowerToOwner)
            .toList();
        final borrowingReviews = reviews
            .where((r) => r.role == AppConstants.reviewRoleOwnerToBorrower)
            .toList();
        final filtered = switch (selectedTab) {
          _ReviewTab.all => reviews,
          _ReviewTab.lending => lendingReviews,
          _ReviewTab.borrowing => borrowingReviews,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
            _ScorePanel(
              user: user,
              reviews: reviews,
              lendingReviews: lendingReviews,
              borrowingReviews: borrowingReviews,
            ),
            const SizedBox(height: 14),
            _BlindReviewNotice(isTrusted: user.trustedResident),
            const SizedBox(height: 14),
            _ReviewTabBar(selected: selectedTab, onChanged: onTabChanged),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting &&
                reviews.isEmpty)
              const _LoadingState()
            else if (snapshot.hasError)
              _ErrorState(message: snapshot.error.toString())
            else if (filtered.isEmpty)
              _EmptyReviewState(tab: selectedTab)
            else
              ...filtered.map((review) => _AnonymousReviewCard(review: review)),
          ],
        );
      },
    );
  }
}
