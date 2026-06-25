part of '../resident_connection_requests_view.dart';

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
