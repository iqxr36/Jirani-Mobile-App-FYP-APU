part of '../resident_home_view.dart';

class ResidentHomeView extends StatefulWidget {
  const ResidentHomeView({
    super.key,
    this.onOpenMarketplace,
    this.onOpenServices,
  });

  final VoidCallback? onOpenMarketplace;
  final VoidCallback? onOpenServices;

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView> {
  final PageController _carouselController = PageController(
    viewportFraction: 0.86,
  );
  Timer? _carouselTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _adminWarningSub;
  StreamSubscription<List<CommunityPostModel>>? _communityPostsSub;
  final _communityPostService = CommunityPostService();
  List<CommunityPostModel> _communityPosts = const <CommunityPostModel>[];
  int _carouselIndex = 0;
  String? _warningWatchUserId;
  String? _watchedCommunityId;
  bool _watchedWithFullAccess = false;
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
    _communityPostsSub?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  List<_CarouselSlide> get _activeCarouselSlides {
    if (_communityPosts.isEmpty) return _carouselSlides;
    return _communityPosts
        .map(
          (post) => _CarouselSlide(
            title: post.title.toUpperCase(),
            subtitle: post.body,
            badge: post.displayCategory.toUpperCase(),
            icon: post.icon,
            imageUrl: post.imageUrl,
            postId: post.id,
          ),
        )
        .toList(growable: false);
  }

  void _watchCommunityPosts(AppUser? user) {
    final communityId = user?.communityId.trim() ?? '';
    final canWatch = residentCanStartProtectedListeners(user);
    if (communityId == _watchedCommunityId &&
        canWatch == _watchedWithFullAccess) {
      return;
    }
    _watchedCommunityId = communityId;
    _watchedWithFullAccess = canWatch;
    _communityPostsSub?.cancel();
    _communityPostsSub = null;
    if (communityId.isEmpty || !canWatch) {
      if (_communityPosts.isNotEmpty) {
        if (mounted) {
          setState(() => _communityPosts = const <CommunityPostModel>[]);
        } else {
          _communityPosts = const <CommunityPostModel>[];
        }
      }
      return;
    }
    _communityPostsSub = _communityPostService
        .watchPublishedPostsForCommunity(communityId)
        .listen(
          (posts) {
            if (!mounted) return;
            setState(() => _communityPosts = posts);
          },
          onError: (Object error) {
            _communityPostsSub?.cancel();
            _communityPostsSub = null;
            if (!mounted) return;
            setState(() => _communityPosts = const <CommunityPostModel>[]);
          },
        );
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_carouselController.hasClients) return;

      final nextIndex = (_carouselIndex + 1) % _activeCarouselSlides.length;
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

  void _openPost(BuildContext context, _CarouselSlide slide) {
    final postId = slide.postId;
    if (postId == null || postId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityPostDetailView(postId: postId),
      ),
    );
  }

  void _openMarketplace(BuildContext context, AppUser? user) {
    if (!residentHasFullAppAccess(user)) {
      _onLockedTap(context, user);
      return;
    }

    final openMarketplace = widget.onOpenMarketplace;
    if (openMarketplace != null) {
      openMarketplace();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentMarketplaceView(),
      ),
    );
  }

  void _openServices(BuildContext context, AppUser? user) {
    if (!residentHasFullAppAccess(user)) {
      _onLockedTap(context, user);
      return;
    }

    final openServices = widget.onOpenServices;
    if (openServices != null) {
      openServices();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentServicesView(),
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
    _watchCommunityPosts(user);
    final incomingConnectionCount = context
        .watch<ConnectionProvider>()
        .incomingRequestCount;
    final unreadMessageCount = context.watch<ChatProvider>().totalUnreadCount;
    final unreadNotificationCount =
        context.watch<NotificationProvider>().unreadCount;
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
                  unreadNotificationCount,
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
    int unreadNotificationCount,
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
                            fontSize: 20,
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
                        badgeCount: unreadNotificationCount,
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
    final slides = _activeCarouselSlides;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 306,
        child: PageView.builder(
          controller: _carouselController,
          clipBehavior: Clip.none,
          itemCount: slides.length,
          onPageChanged: (i) => setState(() => _carouselIndex = i),
          itemBuilder: (context, index) {
            final slide = slides[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 22),
              child: slide.hasPost
                  ? Semantics(
                      button: true,
                      label: 'Open ${slide.title}',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openPost(context, slide),
                          child: _CarouselCard(
                            slide: slide,
                            active: index == _carouselIndex,
                          ),
                        ),
                      ),
                    )
                  : _CarouselCard(
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
    final slides = _activeCarouselSlides;
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(slides.length, (i) {
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
                        fontSize: 20,
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
                  Expanded(
                    child: _ExploreJiraniActionTile(
                      semanticLabel: 'Home Services',
                      title: 'Home Services',
                      assetPath: _kHomeServicesAsset,
                      badgeIcon: Icons.home_repair_service_outlined,
                      fallbackIcon: Icons.home_repair_service_outlined,
                      onTap: () => _openServices(context, user),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExploreJiraniActionTile(
                      semanticLabel: 'Share Items',
                      title: 'Share Items',
                      assetPath: _kShareItemsAsset,
                      badgeIcon: Icons.inventory_2_outlined,
                      fallbackIcon: Icons.inventory_2_outlined,
                      onTap: () => _openMarketplace(context, user),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreJiraniActionTile extends StatelessWidget {
  const _ExploreJiraniActionTile({
    required this.semanticLabel,
    required this.title,
    required this.assetPath,
    required this.badgeIcon,
    required this.fallbackIcon,
    required this.onTap,
  });

  final String semanticLabel;
  final String title;
  final String? assetPath;
  final IconData badgeIcon;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkUi;
    final scheme = Theme.of(context).colorScheme;
    final accent = isDark ? scheme.primary : _kBrandTeal;
    final radius = BorderRadius.circular(24);
    final borderColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.82)
        : accent.withValues(alpha: 0.14);
    final imageSurface = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.74)
        : const Color(0xFFEAF7F7);
    final imageGlow = isDark
        ? scheme.primary.withValues(alpha: 0.18)
        : const Color(0xFFE9C46A).withValues(alpha: 0.24);

    return Semantics(
      button: true,
      label: semanticLabel,
      hint: 'Opens $title',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
              blurRadius: 26,
              spreadRadius: -10,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.14),
              blurRadius: 20,
              spreadRadius: -12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: context.glassFill(lightAlpha: 0.96),
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: accent.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: accent.withValues(alpha: isDark ? 0.12 : 0.06),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return accent.withValues(alpha: isDark ? 0.16 : 0.08);
              }
              if (states.contains(WidgetState.focused)) {
                return accent.withValues(alpha: isDark ? 0.14 : 0.07);
              }
              return null;
            }),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1.03,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: imageSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: isDark ? 0.18 : 0.10,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                imageSurface,
                                imageGlow,
                                imageSurface.withValues(
                                  alpha: isDark ? 0.86 : 0.98,
                                ),
                              ],
                              stops: const [0, 0.54, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 32),
                          child: assetPath != null
                              ? Image.asset(
                                  assetPath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _TileIconFallback(icon: fallbackIcon),
                                )
                              : _TileIconFallback(icon: fallbackIcon),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _TileIconBadge(icon: badgeIcon),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _TileGlassLabel(title: title, accent: accent),
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
}

class _TileGlassLabel extends StatelessWidget {
  const _TileGlassLabel({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkUi;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.32)
            : Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : accent.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
            blurRadius: 16,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileIconBadge extends StatelessWidget {
  const _TileIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkUi;
    final accent = isDark ? Theme.of(context).colorScheme.primary : _kBrandTeal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.36 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
            blurRadius: 12,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}

class _TileIconFallback extends StatelessWidget {
  const _TileIconFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.isDarkUi
        ? Theme.of(context).colorScheme.primary
        : _kBrandTeal;
    return Center(
      child: Icon(
        icon,
        size: 46,
        color: accent.withValues(alpha: context.isDarkUi ? 0.76 : 0.58),
      ),
    );
  }
}
