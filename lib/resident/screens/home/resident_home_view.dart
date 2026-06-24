import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/logic/verification_access.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/resident/screens/chat/resident_messages_view.dart';
import 'package:jirani/resident/screens/connections/resident_connections_view.dart';
import 'package:jirani/resident/screens/notifications/resident_notifications_view.dart';
import 'package:provider/provider.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;
const String _kHomeServicesAsset = 'assets/Home Services(1)-Photoroom.png';
const String _kShareItemsAsset = 'assets/Share Items-Photoroom.png';

List<BoxShadow> _softSurfaceShadow({
  double opacity = 0.10,
  double blurRadius = 24,
  double dy = 12,
}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: blurRadius,
      spreadRadius: -4,
      offset: Offset(0, dy),
    ),
  ];
}

/// Resident home - Figma Group 26.
class ResidentHomeView extends StatefulWidget {
  const ResidentHomeView({super.key});

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView> {
  final PageController _carouselController = PageController(
    viewportFraction: 0.86,
  );
  Timer? _carouselTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _adminWarningSub;
  int _carouselIndex = 0;
  String? _warningWatchUserId;
  final Set<String> _shownAdminWarningIds = <String>{};

  static const _carouselSlides = <_CarouselSlide>[
    _CarouselSlide(
      title: 'RESIDENCE NEWS & EVENTS',
      subtitle:
          'Latest announcements, notices, and community highlights from your residence will appear here.',
      badge: 'COMING SOON',
      icon: Icons.campaign_outlined,
    ),
    _CarouselSlide(
      title: 'UPCOMING COMMUNITY EVENTS',
      subtitle:
          'Resident events, activities, and shared facilities updates can be published by admins for everyone.',
      badge: 'EVENTS',
      icon: Icons.event_available_outlined,
    ),
    _CarouselSlide(
      title: 'IMPORTANT RESIDENCE NOTICES',
      subtitle:
          'Admin notices about maintenance, safety, and neighborhood reminders will be shown to residents.',
      badge: 'NOTICE',
      icon: Icons.apartment_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _adminWarningSub?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_carouselController.hasClients) return;

      final nextIndex = (_carouselIndex + 1) % _carouselSlides.length;
      _carouselController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
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

  void _openMessages(BuildContext context, AppUser? user) {
    if (!residentHasFullAppAccess(user)) {
      _onLockedTap(context, user);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResidentMessagesView()),
    );
  }

  void _openNotifications(BuildContext context, AppUser? user) {
    if (!residentHasFullAppAccess(user)) {
      _onLockedTap(context, user);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentNotificationsView(),
      ),
    );
  }

  Future<void> _refreshHome(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    await auth.refreshCurrentUser();
    if (!context.mounted) return;

    final refreshedUser = auth.currentUser;
    context.read<ConnectionProvider>().watchForUser(refreshedUser, force: true);
    context.read<ChatProvider>().watchForUser(refreshedUser, force: true);
  }

  void _watchAdminWarnings(AppUser? user) {
    final uid = user?.uid ?? '';
    if (uid.isEmpty || _warningWatchUserId == uid) return;
    _warningWatchUserId = uid;
    _adminWarningSub?.cancel();
    _adminWarningSub = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          final docs = snapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['type'] == 'adminWarning' && data['read'] != true;
              })
              .toList()
            ..sort((a, b) {
              final aDate = _notificationDate(a.data()['createdAt']);
              final bDate = _notificationDate(b.data()['createdAt']);
              return bDate.compareTo(aDate);
            });
          if (!mounted || docs.isEmpty) return;
          final doc = docs.first;
          if (!_shownAdminWarningIds.add(doc.id)) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showAdminWarningDialog(doc);
          });
        });
  }

  Future<void> _showAdminWarningDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final title = ((data['title'] as String?) ?? 'Community Trust Warning')
        .trim();
    final body = ((data['body'] as String?) ?? '').trim();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title.isEmpty ? 'Community Trust Warning' : title),
          content: Text(
            body.isEmpty
                ? 'Your recent ratings need attention. Please improve communication and marketplace care.'
                : body,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );
    await doc.reference.update({'read': true});
  }

  DateTime _notificationDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    _watchAdminWarnings(user);
    final incomingConnectionCount = context
        .watch<ConnectionProvider>()
        .incomingRequestCount;
    final unreadMessageCount = context.watch<ChatProvider>().totalUnreadCount;
    final firstName = _firstName(user?.fullName ?? '');

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _kBrandTeal,
          onRefresh: () => _refreshHome(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  user,
                  firstName,
                  incomingConnectionCount,
                  unreadMessageCount,
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
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppUser? user,
    String firstName,
    int incomingConnectionCount,
    int unreadMessageCount,
  ) {
    final isDark = context.isDarkUi;
    final communityName = user?.communityName.trim().isNotEmpty == true
        ? user!.communityName.trim()
        : 'Jirani Residence';

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
                          style: TextStyle(
                            color: context.appMuted,
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
                  _CommunityChip(label: communityName),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.glassFill( lightAlpha: 0.66),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.glassBorder( lightAlpha: 0.82),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.24 : 0.08,
                      ),
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
                        onTap: () => _openMessages(context, user),
                        badgeCount: unreadMessageCount,
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
                        onTap: () => _openNotifications(context, user),
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
              boxShadow: _softSurfaceShadow(
                opacity: 0.05,
                blurRadius: 18,
                dy: 8,
              ),
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
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 306,
        child: PageView.builder(
          controller: _carouselController,
          clipBehavior: Clip.none,
          itemCount: _carouselSlides.length,
          onPageChanged: (i) => setState(() => _carouselIndex = i),
          itemBuilder: (context, index) {
            final slide = _carouselSlides[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 22),
              child: _CarouselCard(
                slide: slide,
                active: index == _carouselIndex,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 12),
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
              color: active ? _kBrandTeal : context.residentOutline(),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 28,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: _kBrandTeal.withValues(alpha: 0.08),
                  blurRadius: 18,
                  spreadRadius: -10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: context.glassFill( lightAlpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.glassBorder( lightAlpha: 0.90),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.22,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _kBrandTeal.withValues(alpha: 0.07),
                                border: Border.all(
                                  color: _kBrandTeal.withValues(alpha: 0.08),
                                ),
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
                          style: TextStyle(
                            color: context.appInk,
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
                          style: TextStyle(
                            color: context.appMuted,
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
                  Expanded(
                    child: Text(
                      'Explore Jirani',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.appInk,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Fast access to community services and sharing.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appMuted,
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
                    subtitle: 'Trusted help nearby',
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
    final isDark = context.isDarkUi;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 78, minHeight: 82),
        child: Ink(
          decoration: BoxDecoration(
            color: context.glassFill( lightAlpha: 0.62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Theme.of(context).colorScheme.outlineVariant
                  : _kBrandTeal.withValues(alpha: 0.08),
            ),
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: context.appInk,
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
    final isDark = context.isDarkUi;

    return Container(
      constraints: const BoxConstraints(maxWidth: 190, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.glassFill( lightAlpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kBrandTeal,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
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
    required this.badge,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.slide, required this.active});

  final _CarouselSlide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: _softSurfaceShadow(
          opacity: active ? 0.18 : 0.10,
          blurRadius: active ? 30 : 20,
          dy: active ? 16 : 10,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _gradientFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.48, 1],
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    slide.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(slide.icon, size: 24, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 4,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kBrandTeal,
            const Color(0xFF83C5BE),
            const Color(0xFFE9C46A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          slide.icon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
