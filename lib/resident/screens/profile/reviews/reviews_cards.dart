// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : reviews_cards.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_reviews_view.dart';

class _AnonymousReviewCard extends StatelessWidget {
  const _AnonymousReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final serviceReview =
        review.role == AppConstants.reviewRoleServiceRequesterToProvider;
    final title = serviceReview
        ? 'Service Review'
        : review.role == AppConstants.reviewRoleBorrowerToOwner
            ? 'Borrower Review'
            : 'Lender Review';
    final focus = serviceReview
        ? 'Service experience'
        : review.role == AppConstants.reviewRoleBorrowerToOwner
            ? 'Lending experience'
            : 'Borrowing experience';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kBrandTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: _kBrandTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.appInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$focus · ${_reviewDateFormat.format(review.publishedAt ?? review.createdAt)}',
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _RatingPill(rating: review.rating),
              ],
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment.trim(),
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _kWarmAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _kWarmAccent, size: 16),
          const SizedBox(width: 3),
          Text(
            '$rating',
            style: TextStyle(
              color: context.appInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustedPill extends StatelessWidget {
  const _TrustedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFC857)),
      ),
      child: const Text(
        'Trusted',
        style: TextStyle(
          color: Color(0xFF7A5200),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.softSurface(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.residentOutline()),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appInk,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
