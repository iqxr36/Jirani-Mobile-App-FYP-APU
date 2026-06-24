import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFF59E0B);
const double _kMaxContentWidth = 440;

final DateFormat _reviewDateFormat = DateFormat('MMM d, yyyy');

class PublicResidentProfileView extends StatelessWidget {
  const PublicResidentProfileView({
    super.key,
    required this.userId,
    this.fallbackName = 'Resident',
  });

  final String userId;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(userId)
                .snapshots(),
            builder: (context, userSnapshot) {
              final data = userSnapshot.data?.data();
              final user = data == null ? null : AppUser.fromMap(data);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            18,
                            16,
                            24 + bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(onBack: () => Navigator.of(context).pop()),
                              const SizedBox(height: 16),
                              if (userSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  user == null)
                                const _StatePanel(
                                  icon: Icons.person_search_rounded,
                                  title: 'Loading profile',
                                  message:
                                      'Checking resident reputation and listings.',
                                )
                              else if (userSnapshot.hasError)
                                _StatePanel(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Profile unavailable',
                                  message: userSnapshot.error
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                )
                              else if (user == null)
                                _StatePanel(
                                  icon: Icons.person_off_outlined,
                                  title: 'Resident not found',
                                  message:
                                      '$fallbackName may no longer have an active profile.',
                                )
                              else
                                _PublicProfileContent(user: user),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PublicProfileContent extends StatelessWidget {
  const _PublicProfileContent({required this.user});

  final AppUser user;

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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Resident Profile',
            style: TextStyle(
              color: context.appInk,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.user,
    required this.reviews,
    required this.lentCount,
  });

  final AppUser user;
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
              fontSize: 22,
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

  final AppUser user;
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

class _ListingPreview extends StatelessWidget {
  const _ListingPreview({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final imageUrl = item.imageUrls.isEmpty ? '' : item.imageUrls.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 58,
              color: _kBrandTeal.withValues(alpha: 0.10),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_rounded, color: _kBrandTeal)
                  : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _categoryLabel(item.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.hasUsageFee ? '${_money(item.feeAmount)} / day' : 'Free',
            style: const TextStyle(
              color: _kBrandTeal,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final title = review.role == AppConstants.reviewRoleBorrowerToOwner
        ? 'Borrower Review'
        : 'Lender Review';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _RatingPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _reviewDateFormat.format(review.publishedAt ?? review.createdAt),
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.user, required this.radius});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.trim();
    final initials = name.isEmpty
        ? 'R'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.characters.first.toUpperCase())
              .join();
    final imageUrl = user.profileImageUrl.trim();
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.avatarPlaceholder,
      child: Text(
        initials,
        style: const TextStyle(
          color: _kBrandTeal,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent
            ? (context.isDarkUi
                ? scheme.tertiaryContainer.withValues(alpha: 0.72)
                : const Color(0xFFFFF7E6))
            : _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent
              ? (context.isDarkUi
                  ? scheme.tertiary
                  : const Color(0xFFFFC857))
              : _kBrandTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: accent
                ? (context.isDarkUi
                    ? scheme.onTertiaryContainer
                    : const Color(0xFF9A6700))
                : _kBrandTeal,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent
                  ? (context.isDarkUi
                      ? scheme.onTertiaryContainer
                      : const Color(0xFF7A5200))
                  : context.appInk,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _kWarmAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _kWarmAccent, size: 15),
          const SizedBox(width: 3),
          Text(
            '$rating',
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
    final ink = context.appInk;
    final muted = context.appMuted;

    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 6),
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
                color: ink,
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
                color: muted,
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

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
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

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appInk,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.glassFill(),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: context.appInk),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.glassBorder()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkUi ? 0.24 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _reviewMetric(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return '-';
  final total = reviews.fold<int>(0, (total, review) => total + review.rating);
  return (total / reviews.length).toStringAsFixed(1);
}

String _money(double? value) {
  final amount = value ?? 0;
  if (amount == 0) return 'RM 0';
  return amount % 1 == 0
      ? 'RM ${amount.toStringAsFixed(0)}'
      : 'RM ${amount.toStringAsFixed(2)}';
}

String _categoryLabel(String value) {
  return switch (value) {
    AppConstants.itemCategoryTools => 'Tools',
    AppConstants.itemCategoryKitchen => 'Kitchen',
    AppConstants.itemCategoryElectronics => 'Electronics',
    AppConstants.itemCategoryCleaning => 'Cleaning',
    AppConstants.itemCategoryStudy => 'Study',
    AppConstants.itemCategoryEventItems => 'Event Items',
    AppConstants.itemCategoryOther => 'Other',
    _ => value.isEmpty ? 'Other' : value,
  };
}
