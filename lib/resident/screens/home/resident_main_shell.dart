import 'package:flutter/material.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/home/resident_home_view.dart';
import 'package:jirani/resident/screens/home/resident_marketplace_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/resident/screens/profile/resident_profile_view.dart';
import 'package:jirani/shared/widgets/verification_locked_overlay.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

enum ResidentTab { home, marketplace, services, profile }

/// Main resident shell - Figma Group 26 bottom navigation + tab bodies.
class ResidentMainShell extends StatefulWidget {
  const ResidentMainShell({super.key});

  @override
  State<ResidentMainShell> createState() => _ResidentMainShellState();
}

class _ResidentMainShellState extends State<ResidentMainShell> {
  ResidentTab _tab = ResidentTab.home;

  void _selectTab(ResidentTab tab) {
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _tab.index,
        children: [
          const ResidentHomeView(),
          VerificationLockedOverlay(
            user: user,
            child: const ResidentMarketplaceView(),
          ),
          VerificationLockedOverlay(
            user: user,
            child: const ResidentServicesView(),
          ),
          const ResidentProfileView(),
        ],
      ),
      bottomNavigationBar: _ResidentBottomNav(
        selected: _tab,
        onSelected: _selectTab,
      ),
    );
  }
}

class _ResidentBottomNav extends StatelessWidget {
  const _ResidentBottomNav({required this.selected, required this.onSelected});

  final ResidentTab selected;
  final ValueChanged<ResidentTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surface.withValues(alpha: 0.94)
              : scheme.surface,
          borderRadius: BorderRadius.circular(80),
          border: Border.all(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.72)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _kBrandTeal.withValues(alpha: 0.08),
              blurRadius: 14,
              spreadRadius: -10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_rounded,
                selected: selected == ResidentTab.home,
                onTap: () => onSelected(ResidentTab.home),
              ),
              _NavItem(
                label: 'Marketplace',
                icon: Icons.storefront_outlined,
                selected: selected == ResidentTab.marketplace,
                onTap: () => onSelected(ResidentTab.marketplace),
              ),
              _NavItem(
                label: 'Services',
                icon: Icons.build_circle_outlined,
                selected: selected == ResidentTab.services,
                onTap: () => onSelected(ResidentTab.services),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline,
                selected: selected == ResidentTab.profile,
                onTap: () => onSelected(ResidentTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 52 : 40,
              height: selected ? 44 : 36,
              decoration: BoxDecoration(
                color: selected ? _kBrandTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _kBrandTeal.withValues(alpha: 0.22),
                          blurRadius: 14,
                          spreadRadius: -6,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: selected ? 26 : 24,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
