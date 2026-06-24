import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/review_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFF59E0B);
const double _kMaxContentWidth = 440;

final DateFormat _reviewDateFormat = DateFormat('MMM d, yyyy');

enum _ReviewTab { all, lending, borrowing }

class ResidentReviewsView extends StatefulWidget {
  const ResidentReviewsView({super.key});

  @override
  State<ResidentReviewsView> createState() => _ResidentReviewsViewState();
}

class _ResidentReviewsViewState extends State<ResidentReviewsView> {
  _ReviewTab _selectedTab = _ReviewTab.all;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottom),
                      child: user == null
                          ? const _SignedOutState()
                          : _ReviewsContent(
                              user: user,
                              selectedTab: _selectedTab,
                              onTabChanged: (tab) =>
                                  setState(() => _selectedTab = tab),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            'Ratings & Reviews',
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

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.user,
    required this.reviews,
    required this.lendingReviews,
    required this.borrowingReviews,
  });

  final AppUser user;
  final List<ReviewModel> reviews;
  final List<ReviewModel> lendingReviews;
  final List<ReviewModel> borrowingReviews;

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
                        fontSize: 30,
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

class _ReviewTabBar extends StatelessWidget {
  const _ReviewTabBar({required this.selected, required this.onChanged});

  final _ReviewTab selected;
  final ValueChanged<_ReviewTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'All',
            selected: selected == _ReviewTab.all,
            onTap: () => onChanged(_ReviewTab.all),
          ),
          _TabButton(
            label: 'Lending',
            selected: selected == _ReviewTab.lending,
            onTap: () => onChanged(_ReviewTab.lending),
          ),
          _TabButton(
            label: 'Borrowing',
            selected: selected == _ReviewTab.borrowing,
            onTap: () => onChanged(_ReviewTab.borrowing),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Expanded(
      child: Material(
        color: selected ? _kBrandTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? onPrimary : context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnonymousReviewCard extends StatelessWidget {
  const _AnonymousReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final title = review.role == AppConstants.reviewRoleBorrowerToOwner
        ? 'Borrower Review'
        : 'Lender Review';
    final focus = review.role == AppConstants.reviewRoleBorrowerToOwner
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

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState({required this.tab});

  final _ReviewTab tab;

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      _ReviewTab.all => 'No published reviews yet',
      _ReviewTab.lending => 'No lending reviews yet',
      _ReviewTab.borrowing => 'No borrowing reviews yet',
    };
    return _StatePanel(
      icon: Icons.rate_review_outlined,
      title: label,
      message: 'Completed reviews will appear here after the blind period.',
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.hourglass_empty_rounded,
      title: 'Loading reviews',
      message: 'Checking published marketplace feedback.',
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.error_outline_rounded,
      title: 'Reviews unavailable',
      message: message.replaceFirst('Exception: ', ''),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.lock_outline_rounded,
      title: 'Sign in required',
      message: 'Your reviews are available after signing in.',
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
    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
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
        color: context.glassFill(lightAlpha: 0.88),
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
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.08, blurRadius: 18, dy: 10),
      ),
      child: child,
    );
  }
}

double _averageRating(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String _metricValue(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return '-';
  return _averageRating(reviews).toStringAsFixed(1);
}
