part of '../resident_connections_view.dart';

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
