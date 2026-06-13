import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/views/connections/resident_connection_requests_view.dart';

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
  static const _neighbors = <_NeighborProfile>[
    _NeighborProfile(
      id: 'faisal',
      name: 'Faisal Ahmed',
      bio:
          'Hi, my name is Faisal a tech student. I offer fixing tech devices...',
    ),
    _NeighborProfile(
      id: 'abu',
      name: 'Abu Khalil',
      bio:
          'Hi, my name is Abu Khalil a Carpenter. I offer home maintenance services...',
    ),
    _NeighborProfile(
      id: 'june',
      name: 'June Lee',
      bio: 'Hi, my name is June Lee a teacher. I offer tutoring services...',
    ),
    _NeighborProfile(
      id: 'sarah',
      name: 'Sarah Kim',
      bio:
          'Hi, my name is Sarah Kim an undergraduate student. I offer babysitting services...',
    ),
  ];

  final Set<String> _sentRequestIds = <String>{'faisal'};

  void _toggleRequest(String id) {
    setState(() {
      if (_sentRequestIds.contains(id)) {
        _sentRequestIds.remove(id);
      } else {
        _sentRequestIds.add(id);
      }
    });
  }

  void _openConnectionRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentConnectionRequestsView(communityName: widget.communityName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : 'ONE SOUTH RESIDENCE';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _BottomActionBar(
        onShowAll: () {},
        onMyConnections: _openConnectionRequests,
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
                        neighbors: _neighbors,
                        sentRequestIds: _sentRequestIds,
                        onToggleRequest: _toggleRequest,
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
    required this.sentRequestIds,
    required this.onToggleRequest,
  });

  final List<_NeighborProfile> neighbors;
  final Set<String> sentRequestIds;
  final ValueChanged<String> onToggleRequest;

  @override
  Widget build(BuildContext context) {
    if (neighbors.isEmpty) {
      return const _EmptyConnectionsState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 16,
          children: [
            for (final neighbor in neighbors)
              SizedBox(
                width: cardWidth,
                child: _NeighborCard(
                  neighbor: neighbor,
                  requestSent: sentRequestIds.contains(neighbor.id),
                  onToggleRequest: () => onToggleRequest(neighbor.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NeighborCard extends StatelessWidget {
  const _NeighborCard({
    required this.neighbor,
    required this.requestSent,
    required this.onToggleRequest,
  });

  final _NeighborProfile neighbor;
  final bool requestSent;
  final VoidCallback onToggleRequest;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: requestSent
          ? 'Connection request sent to ${neighbor.name}'
          : 'Neighbor profile for ${neighbor.name}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 201,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 8,
                offset: const Offset(0, 5),
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
                        neighbor.name,
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
                    neighbor.bio,
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
                  requestSent: requestSent,
                  onPressed: onToggleRequest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  const _ConnectButton({required this.requestSent, required this.onPressed});

  final bool requestSent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
          child: requestSent
              ? const Row(
                  key: ValueKey('sent'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_rounded, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'Connection sent',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Connect +',
                  key: ValueKey('connect'),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
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
  });

  final VoidCallback onShowAll;
  final VoidCallback onMyConnections;

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
                        child: const Text(
                          'My Connections',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
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

class _NeighborProfile {
  const _NeighborProfile({
    required this.id,
    required this.name,
    required this.bio,
  });

  final String id;
  final String name;
  final String bio;
}
