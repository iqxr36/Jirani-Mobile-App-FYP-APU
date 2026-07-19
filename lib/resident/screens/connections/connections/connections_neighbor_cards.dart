// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : connections_neighbor_cards.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_connections_view.dart';

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
    final community = neighbor.communityName.trim();
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
