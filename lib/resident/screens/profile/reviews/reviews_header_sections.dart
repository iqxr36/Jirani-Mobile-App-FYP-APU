// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : reviews_header_sections.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_reviews_view.dart';

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Back',
              onTap: onBack,
            ),
          ),
          const Text(
            'Ratings & Reviews',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.user,
    required this.reviews,
    required this.lendingReviews,
    required this.borrowingReviews,
    required this.serviceProvidingReviews,
  });

  final AppUser user;
  final List<ReviewModel> reviews;
  final List<ReviewModel> lendingReviews;
  final List<ReviewModel> borrowingReviews;
  final List<ReviewModel> serviceProvidingReviews;

  @override
  Widget build(BuildContext context) {
    final score = reviews.isEmpty
        ? user.communityTrustScore
        : _averageRating(reviews);
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kWarmAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: _kWarmAccent,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score <= 0 ? '-' : score.toStringAsFixed(1),
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reviews.length} published ${reviews.length == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(
                        color: context.appMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.trustedResident) const _TrustedPill(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricTile(
                label: 'As Lender',
                value: _metricValue(lendingReviews),
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'As Borrower',
                value: _metricValue(borrowingReviews),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricTile(
                label: 'As Provider',
                value: _metricValue(serviceProvidingReviews),
              ),
              const SizedBox(width: 8),
              _MetricTile(label: 'Total', value: '${reviews.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlindReviewNotice extends StatelessWidget {
  const _BlindReviewNotice({required this.isTrusted});

  final bool isTrusted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkUi
            ? context.residentScheme.primaryContainer.withValues(alpha: 0.45)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.isDarkUi
              ? context.residentScheme.primary.withValues(alpha: 0.42)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isTrusted
                ? Icons.workspace_premium_rounded
                : Icons.visibility_off_outlined,
            color: _kBrandTeal,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Published feedback is anonymous. Waiting reviews stay hidden during the blind review period.',
              style: TextStyle(
                color: context.appInk,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
