import 'package:flutter/material.dart';
import 'package:jirani/core/utils/verification_access.dart';
import 'package:jirani/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/views/connections/resident_connections_view.dart';
import 'package:provider/provider.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;
const String _kHomeServicesAsset = 'assets/Home Services(1)-Photoroom.png';
const String _kShareItemsAsset = 'assets/Share Items-Photoroom.png';

/// Resident home - Figma Group 26.
class ResidentHomeView extends StatefulWidget {
  const ResidentHomeView({super.key});

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView> {
  final PageController _carouselController = PageController(
    viewportFraction: 0.92,
  );
  int _carouselIndex = 0;

  static const _carouselSlides = <_CarouselSlide>[
    _CarouselSlide(
      title: 'BORROW & LEND WITH TRUSTED NEIGHBORS',
      subtitle:
          'Easily lend items, tools, or small loans within your community. Find what you need. Help those around you.',
      assetPath: _kShareItemsAsset,
    ),
    _CarouselSlide(
      title: 'HOME SERVICES FROM NEIGHBORS',
      subtitle: 'Book trusted help for everyday tasks in your building.',
      assetPath: _kHomeServicesAsset,
    ),
    _CarouselSlide(
      title: 'SHARE ITEMS SAFELY',
      subtitle: 'List and discover items with proof and community trust.',
      assetPath: _kShareItemsAsset,
    ),
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  String _greetingForTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'Neighbor';
    return parts.first;
  }

  void _onLockedTap(BuildContext context, AppUser? user) {
    showVerificationRequiredSnack(context, user: user);
  }

  void _openNeighbors(BuildContext context, AppUser? user) {
    if (!residentHasFullAppAccess(user)) {
      _onLockedTap(context, user);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentConnectionsView(communityName: user?.communityName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final incomingConnectionCount = context
        .watch<ConnectionProvider>()
        .incomingRequestCount;
    final firstName = _firstName(user?.fullName ?? '');

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                context,
                user,
                firstName,
                incomingConnectionCount,
              ),
            ),
            if (user != null && !residentHasFullAppAccess(user))
              SliverToBoxAdapter(child: _buildVerificationBanner(user)),
            SliverToBoxAdapter(child: _buildCarousel()),
            SliverToBoxAdapter(child: _buildPageIndicators()),
            SliverToBoxAdapter(child: _buildQuickActions(context, user)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppUser? user,
    String firstName,
    int incomingConnectionCount,
  ) {
    void locked() => _onLockedTap(context, user);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingForTime(),
                          style: const TextStyle(
                            color: Color(0xFF59666B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kBrandTeal,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CommunityChip(
                    label: user?.communityName.trim().isNotEmpty == true
                        ? user!.communityName.trim()
                        : 'Jirani',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderAction(
                        icon: Icons.forum_outlined,
                        label: 'Messages',
                        onTap: locked,
                      ),
                      const SizedBox(width: 14),
                      _HeaderAction(
                        icon: Icons.groups_outlined,
                        label: 'My Community',
                        onTap: () => _openNeighbors(context, user),
                        badgeCount: incomingConnectionCount,
                      ),
                      const Spacer(),
                      _HeaderAction(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: locked,
                        showBadge: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(AppUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBrandTeal.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, color: _kBrandTeal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      verificationStatusMessage(user.verificationStatus),
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 230,
        child: PageView.builder(
          controller: _carouselController,
          itemCount: _carouselSlides.length,
          onPageChanged: (i) => setState(() => _carouselIndex = i),
          itemBuilder: (context, index) {
            final slide = _carouselSlides[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _CarouselCard(slide: slide),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_carouselSlides.length, (i) {
          final active = i == _carouselIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 44 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: active ? _kBrandTeal : const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppUser? user) {
    Widget card({
      required String semanticLabel,
      required String title,
      required String subtitle,
      required String? assetPath,
      required IconData fallbackIcon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.22,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _kBrandTeal.withValues(alpha: 0.07),
                            ),
                            child: assetPath != null
                                ? Image.asset(
                                    assetPath,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _quickActionPlaceholder(
                                              fallbackIcon,
                                            ),
                                  )
                                : _quickActionPlaceholder(fallbackIcon),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF59666B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: _kBrandTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _kBrandTeal,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    void locked() => _onLockedTap(context, user);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _kBrandTeal,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Explore Jirani',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Fast access to community services and sharing.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF59666B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  card(
                    semanticLabel: 'Home Services',
                    title: 'Home Services',
                    subtitle: 'Book trusted help nearby',
                    assetPath: _kHomeServicesAsset,
                    fallbackIcon: Icons.home_repair_service_outlined,
                    onTap: locked,
                  ),
                  const SizedBox(width: 12),
                  card(
                    semanticLabel: 'Share Items',
                    title: 'Share Items',
                    subtitle: 'Borrow and lend safely',
                    assetPath: _kShareItemsAsset,
                    fallbackIcon: Icons.inventory_2_outlined,
                    onTap: locked,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionPlaceholder(IconData icon) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: _kBrandTeal.withValues(alpha: 0.55)),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 78, minHeight: 82),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBrandTeal.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _kBrandTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(icon, size: 24, color: _kBrandTeal),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF90170B),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else if (showBadge)
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF90170B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment_rounded, size: 18, color: _kBrandTeal),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kBrandTeal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide {
  const _CarouselSlide({
    required this.title,
    required this.subtitle,
    this.assetPath,
  });

  final String title;
  final String subtitle;
  final String? assetPath;
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.slide});

  final _CarouselSlide slide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (slide.assetPath != null)
              Image.asset(
                slide.assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _gradientFallback(),
              )
            else
              _gradientFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'NEIGHBORLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      height: 1.08,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBrandTeal, _kBrandTeal.withValues(alpha: 0.75)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.apartment_rounded, size: 56, color: Colors.white54),
      ),
    );
  }
}
