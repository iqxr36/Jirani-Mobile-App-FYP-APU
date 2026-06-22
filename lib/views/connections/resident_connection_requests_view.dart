import 'package:flutter/material.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;
const double _kPageGutter = 16;
const double _kCardMaxWidth = _kMaxContentWidth - (_kPageGutter * 2);

class ResidentConnectionRequestsView extends StatefulWidget {
  const ResidentConnectionRequestsView({super.key, this.communityName});

  final String? communityName;

  @override
  State<ResidentConnectionRequestsView> createState() =>
      _ResidentConnectionRequestsViewState();
}

class _ResidentConnectionRequestsViewState
    extends State<ResidentConnectionRequestsView> {
  int _selectedTab = 0;

  Future<void> _accept(
    ConnectionProvider provider,
    ConnectionModel connection,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.acceptRequest(connection);
      messenger.showSnackBar(
        const SnackBar(content: Text('Connection request accepted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to accept this request.',
          ),
        ),
      );
    }
  }

  Future<void> _decline(
    ConnectionProvider provider,
    ConnectionModel connection,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.declineRequest(connection);
      messenger.showSnackBar(
        const SnackBar(content: Text('Connection request declined.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to decline this request.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final activeTabErrorMessage =
        (_selectedTab == 0
                ? provider.incomingRequestsError
                : provider.connectionsError)
            ?.trim();
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : (provider.currentUser?.communityName.trim().isNotEmpty == true
              ? provider.currentUser!.communityName.trim().toUpperCase()
              : 'ONE SOUTH RESIDENCE');

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
                      padding: const EdgeInsets.fromLTRB(
                        _kPageGutter,
                        8,
                        _kPageGutter,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RequestsHeader(),
                          const SizedBox(height: 18),
                          _CommunityBadge(label: communityName),
                          const SizedBox(height: 18),
                          _SegmentedTabBar(
                            selectedIndex: _selectedTab,
                            onTabChanged: (index) =>
                                setState(() => _selectedTab = index),
                          ),
                          const SizedBox(height: 12),
                          _ConnectionStatusCard(
                            isLoading: provider.isLoading,
                            errorMessage: activeTabErrorMessage,
                            requestCount: provider.incomingRequests.length,
                            neighborCount: provider.connections.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedTab == 0) ..._buildRequestsContent(provider),
              if (_selectedTab == 1) ..._buildNeighborsContent(provider),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestsContent(ConnectionProvider provider) {
    final requests = provider.incomingRequests;
    if (requests.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoRequestsState()),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_kPageGutter, 18, _kPageGutter, 0),
        sliver: SliverList.separated(
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final request = requests[index];
            final requester = provider.userById(request.fromUserId);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                child: _RequestCard(
                  connection: request,
                  requester: requester,
                  submitting: provider.isSubmitting,
                  onAccept: () => _accept(provider, request),
                  onDecline: () => _decline(provider, request),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildNeighborsContent(ConnectionProvider provider) {
    final connections = provider.connections;
    final currentUserId = provider.currentUser?.uid ?? '';
    if (connections.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoNeighborsState()),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_kPageGutter, 18, _kPageGutter, 0),
        sliver: SliverList.separated(
          itemCount: connections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final connection = connections[index];
            final neighborId = connection.otherUserId(currentUserId);
            final neighbor = provider.userById(neighborId);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                child: _ConnectedNeighborRow(
                  connection: connection,
                  neighbor: neighbor,
                  fallbackUserId: neighborId,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 32,
              ),
            ),
          ),
          const Text(
            'Connection Requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxWidth: 286),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.13, blurRadius: 18, dy: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: context.appInk,
              size: 20,
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.76),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.08, blurRadius: 16, dy: 8),
      ),
      child: Row(
        children: [
          _TabPill(
            label: 'Connection Requests',
            selected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          const SizedBox(width: 4),
          _TabPill(
            label: 'My Neighbors',
            selected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? _kBrandTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? context.softSurfaceShadow(
                        lightOpacity: 0.16,
                        blurRadius: 12,
                        dy: 5,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? onPrimary : context.appMuted,
                  fontSize: 11,
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

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
    required this.isLoading,
    required this.errorMessage,
    required this.requestCount,
    required this.neighborCount,
  });

  final bool isLoading;
  final String? errorMessage;
  final int requestCount;
  final int neighborCount;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final icon = hasError
        ? Icons.info_outline_rounded
        : isLoading
        ? Icons.sync_rounded
        : Icons.verified_user_outlined;
    final message = hasError
        ? errorMessage!
        : isLoading
        ? 'Syncing your latest connection updates...'
        : '$neighborCount connected neighbor${neighborCount == 1 ? '' : 's'} · $requestCount pending request${requestCount == 1 ? '' : 's'}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF4E5)
            : _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? const Color(0xFFE29578).withValues(alpha: 0.34)
              : _kBrandTeal.withValues(alpha: 0.16),
        ),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.05, blurRadius: 14, dy: 6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasError ? const Color(0xFFB45309) : _kBrandTeal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: hasError ? const Color(0xFF92400E) : _kBrandTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.connection,
    required this.requester,
    required this.submitting,
    required this.onAccept,
    required this.onDecline,
  });

  final ConnectionModel connection;
  final AppUser? requester;
  final bool submitting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final name = requester?.fullName.isNotEmpty == true
        ? requester!.fullName
        : 'Verified Neighbor';
    final role = requester == null
        ? 'Verified resident'
        : _neighborRole(requester!);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.12, blurRadius: 24, dy: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RequestAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kBrandTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(connection.updatedAt),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$name wants to connect with you as a verified neighbor in your community.',
            style: TextStyle(
              color: context.appInk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appInk,
                    backgroundColor: context.glassFill(lightAlpha: 0.78),
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(
                      color: context.residentOutline(),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: submitting ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBrandTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectedNeighborRow extends StatelessWidget {
  const _ConnectedNeighborRow({
    required this.connection,
    required this.neighbor,
    required this.fallbackUserId,
  });

  final ConnectionModel connection;
  final AppUser? neighbor;
  final String fallbackUserId;

  @override
  Widget build(BuildContext context) {
    final name = neighbor?.fullName.isNotEmpty == true
        ? neighbor!.fullName
        : 'Verified Neighbor';
    final role = neighbor == null
        ? 'Profile syncing · ${_shortUserId(fallbackUserId)}'
        : _neighborRole(neighbor!);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.09, blurRadius: 18, dy: 8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.avatarPlaceholder,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _kBrandTeal,
              size: 36,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    color: _kBrandTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeLabel(connection.updatedAt),
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: context.avatarPlaceholder,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: _kBrandTeal,
        size: 40,
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFF34C759),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
    );
  }
}

class _NoRequestsState extends StatelessWidget {
  const _NoRequestsState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyStateCard(
      icon: Icons.mark_email_read_outlined,
      title: 'No pending requests',
      message:
          'New connection requests from verified neighbors will appear here.',
    );
  }
}

class _NoNeighborsState extends StatelessWidget {
  const _NoNeighborsState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyStateCard(
      icon: Icons.group_outlined,
      title: 'No neighbors yet',
      message: 'Neighbors you connect with will appear here.',
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.93),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.08, blurRadius: 20, dy: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kBrandTeal, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: context.appInk,
                fontSize: 16,
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
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _neighborRole(AppUser user) {
  final unit = user.unitNumber.trim();
  if (unit.isNotEmpty) return 'Resident neighbor - Unit $unit';
  return 'Resident neighbor';
}

String _shortUserId(String uid) {
  if (uid.length <= 6) return uid;
  return 'ID ${uid.substring(0, 6)}...';
}

String _timeLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  return '${(diff.inDays / 30).floor()} months ago';
}
