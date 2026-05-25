import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/utils/verification_access.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:provider/provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;
const String _kHomeServicesAsset = 'assets/Home Services(1)-Photoroom.png';
const String _kShareItemsAsset = 'assets/Share Items-Photoroom.png';

/// Resident home — Figma Group 26.
class ResidentHomeView extends StatefulWidget {
  const ResidentHomeView({super.key});

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView> {
  final PageController _carouselController = PageController(viewportFraction: 0.88);
  int _carouselIndex = 0;

  static const _carouselSlides = <_CarouselSlide>[
    _CarouselSlide(
      title: 'BORROW & LEND WITH TRUSTED NEIGHBORS',
      subtitle:
          'Easily lend items, tools, or small loans within your community. Find what you need. Help those around you.',
      assetPath: 'assets/home-carousel.png',
    ),
    _CarouselSlide(
      title: 'HOME SERVICES FROM NEIGHBORS',
      subtitle: 'Book trusted help for everyday tasks in your building.',
    ),
    _CarouselSlide(
      title: 'SHARE ITEMS SAFELY',
      subtitle: 'List and discover items with proof and community trust.',
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final firstName = _firstName(user?.fullName ?? '');

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, user, firstName),
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

  Widget _buildHeader(BuildContext context, AppUser? user, String firstName) {
    void locked() => _onLockedTap(context, user);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_greetingForTime()}, $firstName 👋',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: _kBrandTeal,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 2,
                color: Colors.black.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeaderAction(
                        icon: Icons.forum_outlined,
                        label: 'Messages',
                        onTap: locked,
                      ),
                      const SizedBox(width: 20),
                      _HeaderAction(
                        icon: Icons.groups_outlined,
                        label: 'My Neighbors',
                        onTap: locked,
                      ),
                    ],
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
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 158,
        child: PageView.builder(
          controller: _carouselController,
          itemCount: _carouselSlides.length,
          onPageChanged: (i) => setState(() => _carouselIndex = i),
          itemBuilder: (context, index) {
            final slide = _carouselSlides[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _CarouselCard(slide: slide),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_carouselSlides.length, (i) {
          final active = i == _carouselIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 50 : 8,
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
      required String title,
      required String? assetPath,
      required IconData fallbackIcon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 1.05,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: assetPath != null
                        ? Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _quickActionPlaceholder(fallbackIcon),
                          )
                        : _quickActionPlaceholder(fallbackIcon),
                  ),
                ),
              ],
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
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  card(
                    title: 'HOME SERVICES',
                    assetPath: _kHomeServicesAsset,
                    fallbackIcon: Icons.home_repair_service_outlined,
                    onTap: locked,
                  ),
                  const SizedBox(width: 12),
                  card(
                    title: 'SHARE ITEMS',
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
      child: Center(child: Icon(icon, size: 48, color: _kBrandTeal.withValues(alpha: 0.55))),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 40, color: _kBrandTeal),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (slide.assetPath != null)
            Image.asset(
              slide.assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEIGHBORLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kBrandTeal,
            _kBrandTeal.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.apartment_rounded, size: 56, color: Colors.white54),
      ),
    );
  }
}
