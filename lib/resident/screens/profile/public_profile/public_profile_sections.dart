part of '../public_resident_profile_view.dart';

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
            'Resident Profile',
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

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.user,
    required this.reviews,
    required this.lentCount,
  });

  final PublicResidentProfile user;
  final List<ReviewModel> reviews;
  final int lentCount;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.trim().isEmpty ? 'Resident' : user.fullName;
    final ink = context.appInk;
    final muted = context.appMuted;
    final score = user.communityTrustScore > 0
        ? user.communityTrustScore
        : user.reputationScore;

    return _GlassPanel(
      child: Column(
        children: [
          _PublicAvatar(user: user, radius: 42),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: user.isVerifiedResident
                    ? Icons.verified_user_rounded
                    : Icons.person_outline_rounded,
                label: user.isVerifiedResident
                    ? 'Verified resident'
                    : 'Resident',
              ),
              if (user.communityName.trim().isNotEmpty)
                _InfoPill(
                  icon: Icons.location_on_outlined,
                  label: user.communityName.trim(),
                ),
              if (user.trustedResident)
                const _InfoPill(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Trusted Resident',
                  accent: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricTile(
                label: 'Trust Score',
                value: user.totalReviews == 0 ? '-' : score.toStringAsFixed(1),
              ),
              const SizedBox(width: 8),
              _MetricTile(label: 'Reviews', value: '${reviews.length}'),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Lent',
                value: '$lentCount',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricTile(
                label: 'Provided Services',
                value: '${user.completedServicesProvided}',
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Requested Services',
                value: '${user.completedServicesRequested}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contact details and unit number are private. Reviews shown here are published anonymously.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBreakdown extends StatelessWidget {
  const _TrustBreakdown({
    required this.user,
    required this.borrowedCount,
    required this.lenderReviews,
    required this.borrowerReviews,
  });

  final PublicResidentProfile user;
  final int borrowedCount;
  final List<ReviewModel> lenderReviews;
  final List<ReviewModel> borrowerReviews;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Trust Breakdown'),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricTile(
                label: 'As Lender',
                value: _reviewMetric(lenderReviews),
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'As Borrower',
                value: _reviewMetric(borrowerReviews),
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Borrowed',
                value: '$borrowedCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublicListingsSection extends StatelessWidget {
  const _PublicListingsSection({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.itemsCollection)
          .where('ownerId', isEqualTo: ownerId)
          .where('status', isEqualTo: AppConstants.itemStatusAvailable)
          .where('isArchived', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final items = (snapshot.data?.docs ?? const [])
            .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel('Active Listings'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  items.isEmpty)
                const _InlineState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Loading listings',
                  message: 'Checking active marketplace items.',
                )
              else if (snapshot.hasError)
                _InlineState(
                  icon: Icons.error_outline_rounded,
                  title: 'Listings unavailable',
                  message: snapshot.error
                      .toString()
                      .replaceFirst('Exception: ', ''),
                )
              else if (items.isEmpty)
                const _InlineState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No active listings',
                  message: 'This resident does not have public items right now.',
                )
              else
                ...items.take(4).map((item) => _ListingPreview(item: item)),
            ],
          ),
        );
      },
    );
  }
}

class _PublicServicesSection extends StatelessWidget {
  const _PublicServicesSection({
    required this.providerId,
    required this.communityId,
  });

  final String providerId;
  final String communityId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.servicesCollection)
          .where('providerId', isEqualTo: providerId)
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: AppConstants.serviceStatusActive)
          .snapshots(),
      builder: (context, snapshot) {
        final services = (snapshot.data?.docs ?? const [])
            .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel('Active Services'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  services.isEmpty)
                const _InlineState(
                  icon: Icons.handyman_outlined,
                  title: 'Loading services',
                  message: 'Checking active services from this resident.',
                )
              else if (snapshot.hasError)
                _InlineState(
                  icon: Icons.error_outline_rounded,
                  title: 'Services unavailable',
                  message: snapshot.error
                      .toString()
                      .replaceFirst('Exception: ', ''),
                )
              else if (services.isEmpty)
                const _InlineState(
                  icon: Icons.handyman_outlined,
                  title: 'No active services',
                  message:
                      'This resident does not have public services right now.',
                )
              else
                ...services
                    .take(4)
                    .map((service) => _ServicePreview(service: service)),
            ],
          ),
        );
      },
    );
  }
}

class _AnonymousReviewsSection extends StatelessWidget {
  const _AnonymousReviewsSection({
    required this.reviews,
    required this.isLoading,
    required this.hasError,
    required this.errorText,
  });

  final List<ReviewModel> reviews;
  final bool isLoading;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Anonymous Reviews'),
          const SizedBox(height: 12),
          if (isLoading)
            const _InlineState(
              icon: Icons.rate_review_outlined,
              title: 'Loading reviews',
              message: 'Only published blind reviews are shown.',
            )
          else if (hasError)
            _InlineState(
              icon: Icons.error_outline_rounded,
              title: 'Reviews unavailable',
              message: (errorText ?? 'Could not load reviews.')
                  .replaceFirst('Exception: ', ''),
            )
          else if (reviews.isEmpty)
            const _InlineState(
              icon: Icons.rate_review_outlined,
              title: 'No published reviews',
              message: 'Reviews appear after the blind review period.',
            )
          else
            ...reviews.map((review) => _ReviewPreview(review: review)),
        ],
      ),
    );
  }
}

