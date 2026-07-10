import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_section.dart';
import 'package:jirani/admin/screens/dashboard/admin_overview_screen.dart';
import 'package:jirani/admin/screens/dashboard/admin_transactions_screen.dart';
import 'package:jirani/admin/screens/listings/admin_listings_screen.dart';
import 'package:jirani/admin/screens/news/admin_news_screen.dart';
import 'package:jirani/admin/screens/notifications/admin_notifications_screen.dart';
import 'package:jirani/admin/screens/reports/admin_reports_screen.dart';
import 'package:jirani/admin/screens/settings/admin_settings_screen.dart';
import 'package:jirani/admin/screens/users/admin_residents_screen.dart';
import 'package:jirani/admin/screens/verification/admin_verification_screen.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/theme/admin_theme_data.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/admin/providers/admin_theme_provider.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/data/repositories/notification_repository.dart';
import 'package:jirani/shared/models/notification_model.dart';
import 'package:provider/provider.dart';

// Admin portal UI feature: top-level shell for sidebar navigation, scoped dashboard content, and notification routing.
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
  String? _selectedReportId;
  String? _configuredAdminUid;
  String? _appliedThemeAdminUid;
  String? _appliedThemePresetId;

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
    if (currentAdmin != null &&
        (currentAdmin.uid != _appliedThemeAdminUid ||
            currentAdmin.themePresetId != _appliedThemePresetId)) {
      _appliedThemeAdminUid = currentAdmin.uid;
      _appliedThemePresetId = currentAdmin.themePresetId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<AdminThemeProvider>()
            .syncFromAdminProfile(currentAdmin.themePresetId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        JiraniResponsive.windowClass(context) == JiraniWindowClass.expanded;
    final currentAdmin = context.watch<AuthViewModel>().currentAdmin;
    final content = _AdminContent(
      section: _section,
      selectedRequestId: _selectedRequestId,
      selectedReportId: _selectedReportId,
      adminUid: currentAdmin?.uid ?? '',
      onSelectRequest: (id) => setState(() => _selectedRequestId = id),
      onNotificationSelected: _openNotificationTarget,
    );

    return Consumer<AdminThemeProvider>(
      builder: (context, adminTheme, _) {
        final adminThemeData = buildAdminTheme(
          primary: adminTheme.preset.primary,
          secondary: adminTheme.preset.secondary,
        );
        if (wide) {
          return Theme(
            data: adminThemeData,
            child: Scaffold(
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
                          onNotificationSelected: _openNotificationTarget,
                        ),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Theme(
          data: adminThemeData,
          child: Scaffold(
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
                AdminNotificationBell(
                  adminUid: currentAdmin?.uid ?? '',
                  onNotificationSelected: _openNotificationTarget,
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
          ),
        );
      },
    );
  }

  // Admin notification feature: routes admin notification taps to reports, verification, or dashboard sections.
  void _openNotificationTarget(NotificationModel notification) {
    final requestId = notification.verificationRequestId.trim();
    final reportId = notification.reportId.trim();
    if (requestId.isNotEmpty) {
      setState(() {
        _section = AdminSection.verification;
        _selectedRequestId = requestId;
      });
      return;
    }
    if (reportId.isNotEmpty) {
      setState(() {
        _section = AdminSection.reports;
        _selectedReportId = reportId;
      });
    }
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
                      errorBuilder: (_, _, _) => Icon(
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
    required this.onNotificationSelected,
  });

  final AdminSection section;
  final VoidCallback onLogout;
  final bool isLoggingOut;
  final ValueChanged<NotificationModel> onNotificationSelected;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final admin = auth.currentAdmin;
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
          AdminNotificationBell(
            adminUid: admin?.uid ?? '',
            onNotificationSelected: onNotificationSelected,
          ),
          const SizedBox(width: 10),
          AdminAvatar(
            name: admin?.fullName ?? 'Admin',
            imageUrl: admin?.profileImageUrl ?? '',
            previewBytes: auth.adminProfileImageBytes,
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

// Admin notification feature: app-bar bell that previews unread admin notifications.
class AdminNotificationBell extends StatefulWidget {
  const AdminNotificationBell({
    super.key,
    required this.adminUid,
    required this.onNotificationSelected,
  });

  final String adminUid;
  final ValueChanged<NotificationModel> onNotificationSelected;

  @override
  State<AdminNotificationBell> createState() => _AdminNotificationBellState();
}

class _AdminNotificationBellState extends State<AdminNotificationBell> {
  final NotificationRepository _repository = NotificationRepository();

  @override
  Widget build(BuildContext context) {
    final adminUid = widget.adminUid.trim();
    if (adminUid.isEmpty) {
      return IconButton.filledTonal(
        tooltip: 'Notifications',
        onPressed: null,
        style: IconButton.styleFrom(
          backgroundColor: AdminColors.primary.withValues(alpha: 0.12),
          foregroundColor: AdminColors.primary,
        ),
        icon: const Icon(Icons.notifications_none_rounded),
      );
    }

    return StreamBuilder<int>(
      stream: _repository.watchUnreadCount(adminUid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              tooltip: 'Notifications',
              onPressed: () => _showNotifications(context),
              style: IconButton.styleFrom(
                backgroundColor: AdminColors.primary.withValues(alpha: 0.12),
                foregroundColor: AdminColors.primary,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.danger,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AdminColors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Admin notification feature: opens the notification dialog and marks visible notifications as read.
  Future<void> _showNotifications(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AdminNotificationDialog(
        adminUid: widget.adminUid,
        repository: _repository,
        onNotificationSelected: (notification) async {
          await _repository.markRead(notification.id);
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          widget.onNotificationSelected(notification);
        },
      ),
    );
  }
}

class _AdminNotificationDialog extends StatelessWidget {
  const _AdminNotificationDialog({
    required this.adminUid,
    required this.repository,
    required this.onNotificationSelected,
  });

  final String adminUid;
  final NotificationRepository repository;
  final Future<void> Function(NotificationModel notification)
  onNotificationSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 72, right: 28, left: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => repository.markAllRead(adminUid),
                    child: const Text('Mark all read'),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AdminColors.border),
            Flexible(
              child: StreamBuilder<List<NotificationModel>>(
                stream: repository.watchNotifications(adminUid),
                builder: (context, snapshot) {
                  final notifications =
                      snapshot.data ?? const <NotificationModel>[];
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      notifications.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (notifications.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(color: AdminColors.muted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AdminColors.border),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _AdminNotificationTile(
                        notification: notification,
                        onTap: () => onNotificationSelected(notification),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  const _AdminNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canNavigate =
        notification.verificationRequestId.trim().isNotEmpty ||
        notification.reportId.trim().isNotEmpty;
    return Material(
      color: notification.unread
          ? AdminColors.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: canNavigate ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: notification.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          notification.relativeTime,
                          style: const TextStyle(
                            color: AdminColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.displayCategory,
                      style: TextStyle(
                        color: notification.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.section,
    required this.selectedRequestId,
    required this.selectedReportId,
    required this.adminUid,
    required this.onSelectRequest,
    required this.onNotificationSelected,
  });

  final AdminSection section;
  final String? selectedRequestId;
  final String? selectedReportId;
  final String adminUid;
  final ValueChanged<String> onSelectRequest;
  final ValueChanged<NotificationModel> onNotificationSelected;

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
            AdminSection.notifications => AdminNotificationsScreen(
              adminUid: adminUid,
              onNotificationSelected: onNotificationSelected,
            ),
            AdminSection.residents => const AdminResidentsScreen(),
            AdminSection.news => const AdminNewsScreen(),
            AdminSection.listings => const AdminListingsScreen(),
            AdminSection.reports => AdminReportsScreen(
              selectedReportId: selectedReportId,
            ),
            AdminSection.transactions => const AdminTransactionsScreen(),
            AdminSection.settings => const AdminSettingsScreen(),
          },
        ),
      ),
    );
  }
}
