import 'package:flutter/material.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/network_status_provider.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kCardMaxWidth = 390;

class NetworkStatusOverlay extends StatelessWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkStatusProvider>(
      builder: (context, network, _) {
        if (!network.shouldShowConnectivityGate) {
          return child;
        }

        return ConnectivityGateScreen(
          isRefreshing: network.isRefreshing,
          onRefresh: () => _refreshApp(context),
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

/// Full-screen offline gate shown during bootstrap and when the app is offline.
class ConnectivityGateScreen extends StatelessWidget {
  const ConnectivityGateScreen({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bottomInset = JiraniResponsive.bottomInset(context);
    final dividerGrey = context.residentOutline();

    return JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final topPad = h > 600 ? h * 0.06 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, topPad, 20, 24 + bottomInset),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: JiraniLogo(height: 88)),
                        const SizedBox(height: 14),
                        Text(
                          'No internet connection',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _kBrandTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.glassFill(),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: dividerGrey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  size: 48,
                                  color: context.residentScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Connect to Wi-Fi or mobile data to use Jirani.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: context.appMuted,
                                        height: 1.45,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Live updates are on hold until you reconnect.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.appMuted.withValues(
                                          alpha: 0.85,
                                        ),
                                        height: 1.4,
                                      ),
                                ),
                                const SizedBox(height: 22),
                                FilledButton.icon(
                                  onPressed: isRefreshing ? null : onRefresh,
                                  icon: isRefreshing
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.onAccent(
                                              context.residentScheme.primary,
                                            ),
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
