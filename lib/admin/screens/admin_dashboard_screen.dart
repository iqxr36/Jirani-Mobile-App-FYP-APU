import 'package:flutter/material.dart';
import 'package:jirani/admin/models/admin_section.dart';
import 'package:jirani/admin/screens/dashboard/admin_overview_screen.dart';
import 'package:jirani/admin/screens/dashboard/admin_transactions_screen.dart';
import 'package:jirani/admin/screens/listings/admin_listings_screen.dart';
import 'package:jirani/admin/screens/news/admin_news_screen.dart';
import 'package:jirani/admin/screens/reports/admin_reports_screen.dart';
import 'package:jirani/admin/screens/settings/admin_settings_screen.dart';
import 'package:jirani/admin/screens/users/admin_residents_screen.dart';
import 'package:jirani/admin/screens/verification/admin_verification_screen.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/widgets/admin_status_widgets.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminProvider>(
      create: (_) => AdminProvider(),
      child: _AdminDashboardView(
        onLogout: onLogout,
        isLoggingOut: isLoggingOut,
      ),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView({
    required this.onLogout,
    required this.isLoggingOut,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  AdminSection _section = AdminSection.overview;
  String? _selectedRequestId;
  String? _configuredAdminUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentAdmin = context.watch<AuthViewModel>().currentAdmin;
    if (currentAdmin != null && currentAdmin.uid != _configuredAdminUid) {
      _configuredAdminUid = currentAdmin.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AdminProvider>().configureForAdmin(currentAdmin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        JiraniResponsive.windowClass(context) == JiraniWindowClass.expanded;
    final content = _AdminContent(
      section: _section,
      selectedRequestId: _selectedRequestId,
      onSelectRequest: (id) => setState(() => _selectedRequestId = id),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        body: Row(
          children: [
            _AdminSidebar(
              section: _section,
              onChanged: (section) => setState(() => _section = section),
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    section: _section,
                    onLogout: widget.onLogout,
                    isLoggingOut: widget.isLoggingOut,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.background,
      drawer: Drawer(
        child: SafeArea(
          child: _AdminSidebar(
            section: _section,
            onChanged: (section) {
              setState(() => _section = section);
              Navigator.of(context).pop();
            },
            compact: true,
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(_section.title),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.isLoggingOut ? null : widget.onLogout,
            icon: widget.isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndexFor(_section),
        onDestinationSelected: (index) {
          setState(() => _section = _sectionForBottomIndex(index));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'Verify',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  int _bottomIndexFor(AdminSection section) {
    return switch (section) {
      AdminSection.overview => 0,
      AdminSection.verification => 1,
      AdminSection.residents => 2,
      _ => 3,
    };
  }

  AdminSection _sectionForBottomIndex(int index) {
    return switch (index) {
      0 => AdminSection.overview,
      1 => AdminSection.verification,
      2 => AdminSection.residents,
      _ => AdminSection.listings,
    };
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.section,
    required this.onChanged,
    this.compact = false,
  });

  final AdminSection section;
  final ValueChanged<AdminSection> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : 280,
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      'assets/In-app-logo-Jirani.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.apartment_rounded,
                        color: AdminColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jirani Admin',
                        style: TextStyle(
                          color: AdminColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Community portal',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: AdminSection.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = AdminSection.values[index];
                final selected = item == section;
                return Semantics(
                  selected: selected,
                  button: true,
                  child: Material(
                    color: selected
                        ? AdminColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onChanged(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? AdminColors.primary
                                  : AdminColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: selected
                                      ? AdminColors.primary
                                      : AdminColors.ink,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminStatusNotice(
              icon: Icons.shield_moon_rounded,
              title: 'Secure mode',
              body: 'Admin actions are logged for audit history.',
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.section,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final AdminSection section;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthViewModel>().currentAdmin;
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  section.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search residents, reports, listings',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          AdminAvatar(
            name: admin?.fullName ?? 'Admin',
            imageUrl: admin?.profileImageUrl ?? '',
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign out',
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.section,
    required this.selectedRequestId,
    required this.onSelectRequest,
  });

  final AdminSection section;
  final String? selectedRequestId;
  final ValueChanged<String> onSelectRequest;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const AdminScrollBehavior(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(section),
          child: switch (section) {
            AdminSection.overview => const AdminOverviewScreen(),
            AdminSection.verification => AdminVerificationScreen(
              selectedRequestId: selectedRequestId,
              onSelectRequest: onSelectRequest,
            ),
            AdminSection.residents => const AdminResidentsScreen(),
            AdminSection.news => const AdminNewsScreen(),
            AdminSection.listings => const AdminListingsScreen(),
            AdminSection.reports => const AdminReportsScreen(),
            AdminSection.transactions => const AdminTransactionsScreen(),
            AdminSection.settings => const AdminSettingsScreen(),
          },
        ),
      ),
    );
  }
}
