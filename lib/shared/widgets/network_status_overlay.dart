import 'package:flutter/material.dart';
import 'package:jirani/providers/auth_provider.dart';
import 'package:jirani/providers/network_status_provider.dart';
import 'package:provider/provider.dart';

class NetworkStatusOverlay extends StatelessWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkStatusProvider>(
      builder: (context, network, _) {
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !network.isOffline,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: network.isOffline
                      ? _OfflineNetworkState(
                          key: const ValueKey('offline-network-state'),
                          isRefreshing: network.isRefreshing,
                          onRefresh: () => _refreshApp(context),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('online-network-state'),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshApp(BuildContext context) async {
    final isOnline = await context.read<NetworkStatusProvider>().refresh();
    if (!isOnline || !context.mounted) return;

    await context.read<AuthProvider>().refreshCurrentUser();
  }
}

class _OfflineNetworkState extends StatelessWidget {
  const _OfflineNetworkState({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: const Color(0xFF071817).withValues(alpha: 0.72),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 7, color: const Color(0xFFE29578)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE29578,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE29578,
                                      ).withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.wifi_off_rounded,
                                    color: Color(0xFF9A4D2D),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Connection paused',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: const Color(0xFF102B2A),
                                              fontSize: 21,
                                              fontWeight: FontWeight.w900,
                                              height: 1.12,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Jirani needs Wi-Fi or mobile data to keep your community information current.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF556361),
                                              fontWeight: FontWeight.w500,
                                              height: 1.45,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _NetworkStatusTile(
                              icon: Icons.cloud_off_outlined,
                              label: 'Live updates are on hold',
                            ),
                            const SizedBox(height: 8),
                            const _NetworkStatusTile(
                              icon: Icons.security_update_good_outlined,
                              label: 'Reconnect, then refresh safely',
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: isRefreshing ? null : onRefresh,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: const Color(0xFF006D77),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF006D77,
                                ).withValues(alpha: 0.48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: isRefreshing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: Text(
                                isRefreshing
                                    ? 'Checking connection'
                                    : 'Refresh App',
                              ),
                            ),
                          ],
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

class _NetworkStatusTile extends StatelessWidget {
  const _NetworkStatusTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E8E6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006D77), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF173836),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
