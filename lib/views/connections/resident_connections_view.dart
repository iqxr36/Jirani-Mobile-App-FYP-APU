import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jirani/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/connection_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/views/connections/resident_connection_requests_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 390;

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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth - 32,
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
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
    return Column(
      children: [
        Container(
          width: 280,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 48, maxWidth: 276),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1F2937),
                size: 20,
              ),
              const SizedBox(width: 24),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        const horizontalGap = 12.0;
        final cardWidth = (constraints.maxWidth - horizontalGap) / 2;

        return Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            spacing: horizontalGap,
            runSpacing: 16,
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
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 201,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 12),
            child: Column(
              children: [
                const _NeighborAvatar(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: Text(
                    _neighborBio(neighbor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: _kMutedText,
                      fontSize: 6.6,
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                    ),
                  ),
                ),
                const Spacer(),
                _ConnectButton(
                  connected: connected,
                  incomingRequest: incomingRequest,
                  outgoingRequest: outgoingRequest,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
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
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFCFE4E9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: _kBrandTeal,
        size: 42,
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
        ? 'Connection sent'
        : 'Connect +';
    final icon = connected
        ? Icons.check_rounded
        : incomingRequest
        ? Icons.reply_rounded
        : outgoingRequest
        ? Icons.link_rounded
        : null;

    return SizedBox(
      width: double.infinity,
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: icon == null
              ? Text(
                  label,
                  key: ValueKey(label),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Row(
                  key: ValueKey(label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 12 + safeBottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: onShowAll,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kBrandTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Show All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onMyConnections,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kBrandTeal,
                          backgroundColor: _kBrandTeal.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: _kBrandTeal.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Text(
                              'My Connections',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (pendingCount > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: _CountBadge(count: pendingCount),
                              ),
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
        style: const TextStyle(
          color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, color: _kBrandTeal, size: 40),
          SizedBox(height: 12),
          Text(
            'No connections yet',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap Connect + on a neighbor to add them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMutedText,
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
