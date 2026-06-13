import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 390;

class ResidentConnectionRequestsView extends StatefulWidget {
  const ResidentConnectionRequestsView({super.key, this.communityName});

  final String? communityName;

  @override
  State<ResidentConnectionRequestsView> createState() =>
      _ResidentConnectionRequestsViewState();
}

class _ResidentConnectionRequestsViewState
    extends State<ResidentConnectionRequestsView> {
  static const _requests = <_ConnectionRequest>[
    _ConnectionRequest(
      id: 'nadia',
      name: 'Nadia Rahman',
      role: 'Resident neighbor',
      message:
          'Hi, I live nearby and would like to connect for community updates.',
      timeAgo: '12 min ago',
    ),
    _ConnectionRequest(
      id: 'omar',
      name: 'Omar Hassan',
      role: 'Home maintenance helper',
      message:
          'I can help with small home repairs and would like to be in your network.',
      timeAgo: '1 hr ago',
    ),
    _ConnectionRequest(
      id: 'aisha',
      name: 'Aisha Lim',
      role: 'Tutor',
      message:
          'I saw we are in the same residence. Let us connect for tutoring requests.',
      timeAgo: 'Yesterday',
    ),
  ];

  static const _acceptedNeighbors = <_AcceptedNeighbor>[
    _AcceptedNeighbor(
      id: 'faisal',
      name: 'Faisal Ahmed',
      role: 'Tech student',
      timeAgo: '2 days ago',
    ),
    _AcceptedNeighbor(
      id: 'abu',
      name: 'Abu Khalil',
      role: 'Carpenter',
      timeAgo: '1 week ago',
    ),
    _AcceptedNeighbor(
      id: 'june',
      name: 'June Lee',
      role: 'Teacher',
      timeAgo: '2 weeks ago',
    ),
    _AcceptedNeighbor(
      id: 'sarah',
      name: 'Sarah Kim',
      role: 'Undergraduate student',
      timeAgo: '1 month ago',
    ),
  ];

  int _selectedTab = 0;

  final Set<String> _acceptedIds = <String>{};
  final Set<String> _declinedIds = <String>{};

  List<_ConnectionRequest> get _visibleRequests {
    return _requests
        .where((request) => !_declinedIds.contains(request.id))
        .toList(growable: false);
  }

  void _accept(String id) {
    setState(() {
      _acceptedIds.add(id);
      _declinedIds.remove(id);
    });
  }

  void _decline(String id) {
    setState(() {
      _declinedIds.add(id);
      _acceptedIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : 'ONE SOUTH RESIDENCE';

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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedTab == 0) ..._buildRequestsContent(),
              if (_selectedTab == 1) ..._buildNeighborsContent(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestsContent() {
    if (_visibleRequests.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoRequestsState()),
        ),
      ];
    }
    return [
      SliverList.separated(
        itemCount: _visibleRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final request = _visibleRequests[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kMaxContentWidth - 32,
              ),
              child: _RequestCard(
                request: request,
                accepted: _acceptedIds.contains(request.id),
                onAccept: () => _accept(request.id),
                onDecline: () => _decline(request.id),
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildNeighborsContent() {
    if (_acceptedNeighbors.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoNeighborsState()),
        ),
      ];
    }
    return [
      SliverList.separated(
        itemCount: _acceptedNeighbors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final neighbor = _acceptedNeighbors[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kMaxContentWidth - 32,
              ),
              child: _ConnectedNeighborRow(neighbor: neighbor),
            ),
          );
        },
      ),
    ];
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

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

// ── Community badge ──────────────────────────────────────────────────────────

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, maxWidth: 276),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
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

// ── Segmented tab bar ────────────────────────────────────────────────────────

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
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? _kBrandTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _kMutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.accepted,
    required this.onAccept,
    required this.onDecline,
  });

  final _ConnectionRequest request;
  final bool accepted;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accepted
              ? _kBrandTeal.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
                            request.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
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
                      request.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kBrandTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.timeAgo,
                      style: const TextStyle(
                        color: _kMutedText,
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
            request.message,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (accepted)
            const _AcceptedBanner()
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kBrandTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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

// ── Connected neighbor row (Tab 1) ───────────────────────────────────────────

class _ConnectedNeighborRow extends StatelessWidget {
  const _ConnectedNeighborRow({required this.neighbor});

  final _AcceptedNeighbor neighbor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFCFE4E9),
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
                        neighbor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
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
                  neighbor.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        ],
      ),
    );
  }
}

// ── Shared avatar & badge widgets ────────────────────────────────────────────

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFCFE4E9),
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

class _AcceptedBanner extends StatelessWidget {
  const _AcceptedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: _kBrandTeal, size: 18),
          SizedBox(width: 8),
          Text(
            'Connection accepted',
            style: TextStyle(
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

// ── Empty states ─────────────────────────────────────────────────────────────

class _NoRequestsState extends StatelessWidget {
  const _NoRequestsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined, color: _kBrandTeal, size: 42),
            SizedBox(height: 12),
            Text(
              'No pending requests',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New connection requests from verified neighbors will appear here.',
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
      ),
    );
  }
}

class _NoNeighborsState extends StatelessWidget {
  const _NoNeighborsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, color: _kBrandTeal, size: 42),
            SizedBox(height: 12),
            Text(
              'No neighbors yet',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Neighbors you connect with will appear here.',
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
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class _ConnectionRequest {
  const _ConnectionRequest({
    required this.id,
    required this.name,
    required this.role,
    required this.message,
    required this.timeAgo,
  });

  final String id;
  final String name;
  final String role;
  final String message;
  final String timeAgo;
}

class _AcceptedNeighbor {
  const _AcceptedNeighbor({
    required this.id,
    required this.name,
    required this.role,
    required this.timeAgo,
  });

  final String id;
  final String name;
  final String role;
  final String timeAgo;
}
