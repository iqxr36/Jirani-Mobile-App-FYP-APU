import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/views/connections/resident_connection_requests_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;
const double _kPageGutter = 16;
const double _kCardMaxWidth = _kMaxContentWidth - (_kPageGutter * 2);

class ResidentConnectionsView extends StatefulWidget {
  const ResidentConnectionsView({super.key, this.communityName});

  final String? communityName;

  @override
  State<ResidentConnectionsView> createState() =>
      _ResidentConnectionsViewState();
}

class _ResidentConnectionsViewState extends State<ResidentConnectionsView> {
  void _openConnectionRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentConnectionRequestsView(communityName: widget.communityName),
      ),
    );
  }

  Future<void> _handleNeighborAction(AppUser neighbor) async {
    final provider = context.read<ConnectionProvider>();
    final connection = provider.connectionWith(neighbor.uid);
    final messenger = ScaffoldMessenger.of(context);
    final name = neighbor.fullName.isNotEmpty ? neighbor.fullName : 'neighbor';

    try {
      if (provider.hasIncomingRequest(neighbor.uid)) {
        _openConnectionRequests();
        return;
      }
      if (provider.hasOutgoingRequest(neighbor.uid) && connection != null) {
        await provider.withdrawRequest(connection);
        messenger.showSnackBar(
          SnackBar(content: Text('Connection request to $name withdrawn.')),
        );
        return;
      }
      if (provider.isConnected(neighbor.uid)) {
        messenger.showSnackBar(
          SnackBar(content: Text('You are already connected with $name.')),
        );
        return;
      }

      await provider.sendRequest(neighbor);
      messenger.showSnackBar(
        SnackBar(content: Text('Connection request sent to $name.')),
      );
    } catch (_) {
      final message =
          provider.errorMessage ?? 'Unable to update this connection.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : (provider.currentUser?.communityName.trim().isNotEmpty == true
              ? provider.currentUser!.communityName.trim().toUpperCase()
              : 'ONE SOUTH RESIDENCE');

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _BottomActionBar(
        onShowAll: () {},
        onMyConnections: _openConnectionRequests,
        pendingCount: provider.incomingRequestCount,
      ),
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
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ConnectionsHeader(),
                          const SizedBox(height: 20),
                          _CommunityPill(label: communityName),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: _kPageGutter),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kCardMaxWidth,
                      ),
                      child: _NeighborGrid(
                        neighbors: provider.communityResidents,
                        connectionProvider: provider,
                        onNeighborAction: _handleNeighborAction,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 124)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionsHeader extends StatelessWidget {
  const _ConnectionsHeader();

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
            'My Community',
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

class _CommunityPill extends StatelessWidget {
  const _CommunityPill({required this.label});

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

class _NeighborGrid extends StatelessWidget {
  const _NeighborGrid({
    required this.neighbors,
    required this.connectionProvider,
    required this.onNeighborAction,
  });

  final List<AppUser> neighbors;
  final ConnectionProvider connectionProvider;
  final ValueChanged<AppUser> onNeighborAction;

  @override
  Widget build(BuildContext context) {
    if (neighbors.isEmpty) {
      return const _EmptyConnectionsState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalGap = 14.0;
        final useSingleColumn = constraints.maxWidth < 520;
        final cardWidth = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - horizontalGap) / 2;

        return Center(
          child: Wrap(
            alignment: useSingleColumn
                ? WrapAlignment.center
                : WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            spacing: horizontalGap,
            runSpacing: 14,
            children: [
              for (final neighbor in neighbors)
                SizedBox(
                  width: cardWidth,
                  child: _NeighborCard(
                    neighbor: neighbor,
                    connection: connectionProvider.connectionWith(neighbor.uid),
                    incomingRequest: connectionProvider.hasIncomingRequest(
                      neighbor.uid,
                    ),
                    outgoingRequest: connectionProvider.hasOutgoingRequest(
                      neighbor.uid,
                    ),
                    onAction: () => onNeighborAction(neighbor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NeighborCard extends StatelessWidget {
  const _NeighborCard({
    required this.neighbor,
    required this.connection,
    required this.incomingRequest,
    required this.outgoingRequest,
    required this.onAction,
  });

  final AppUser neighbor;
  final ConnectionModel? connection;
  final bool incomingRequest;
  final bool outgoingRequest;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final displayName = neighbor.fullName.isNotEmpty
        ? neighbor.fullName
        : 'Verified Neighbor';
    final connected = connection?.isAccepted ?? false;

    return Semantics(
      label: connected
          ? 'Connected neighbor profile for $displayName'
          : 'Neighbor profile for $displayName',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 156),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
          boxShadow: context.softSurfaceShadow(
            lightOpacity: 0.11,
            blurRadius: 24,
            dy: 12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _NeighborAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appInk,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const _VerifiedBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _neighborBio(neighbor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ConnectButton(
              connected: connected,
              incomingRequest: incomingRequest,
              outgoingRequest: outgoingRequest,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  String _neighborBio(AppUser neighbor) {
    final unit = neighbor.unitNumber.trim();
    final community = neighbor.communityName.trim();
    if (unit.isNotEmpty && community.isNotEmpty) {
      return 'Verified resident in $community, unit $unit.';
    }
    if (community.isNotEmpty) {
      return 'Verified resident in $community.';
    }
    return 'Verified resident in your community.';
  }
}

class _NeighborAvatar extends StatelessWidget {
  const _NeighborAvatar();

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
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFF34C759),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 9, color: Colors.white),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.connected,
    required this.incomingRequest,
    required this.outgoingRequest,
    required this.onPressed,
  });

  final bool connected;
  final bool incomingRequest;
  final bool outgoingRequest;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = connected
        ? 'Connected'
        : incomingRequest
        ? 'Respond'
        : outgoingRequest
        ? 'Request sent'
        : 'Connect';
    final icon = connected
        ? Icons.check_rounded
        : incomingRequest
        ? Icons.reply_rounded
        : outgoingRequest
        ? Icons.link_rounded
        : Icons.person_add_alt_1_rounded;
    final secondary = outgoingRequest;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: secondary
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBrandTeal,
                backgroundColor: _kBrandTeal.withValues(alpha: 0.05),
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: _kBrandTeal.withValues(alpha: 0.38)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: _kBrandTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onShowAll,
    required this.onMyConnections,
    required this.pendingCount,
  });

  final VoidCallback onShowAll;
  final VoidCallback onMyConnections;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: context.softSurfaceShadow(
                lightOpacity: 0.18,
                blurRadius: 26,
                dy: 12,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.glassFill(lightAlpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.glassBorder(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: onShowAll,
                            icon: const Icon(Icons.groups_rounded, size: 18),
                            label: const Text('Show All'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kBrandTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: onMyConnections,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kBrandTeal,
                              backgroundColor: _kBrandTeal.withValues(
                                alpha: 0.06,
                              ),
                              side: BorderSide(
                                color: _kBrandTeal.withValues(alpha: 0.42),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 18),
                                const SizedBox(width: 6),
                                const Flexible(
                                  child: Text(
                                    'My Connections',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 6),
                                  _CountBadge(count: pendingCount),
                                ],
                              ],
                            ),
                          ),
                        ),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF90170B),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyConnectionsState extends StatelessWidget {
  const _EmptyConnectionsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.08,
          blurRadius: 20,
          dy: 10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined, color: _kBrandTeal, size: 40),
          const SizedBox(height: 12),
          Text(
            'No connections yet',
            style: TextStyle(
              color: context.appInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Connect + on a neighbor to add them here.',
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
    );
  }
}
