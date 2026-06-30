import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/notification_navigation.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/notification_provider.dart';
import 'package:jirani/shared/models/notification_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

// Notification UI feature: lists resident notifications and routes each tapped item to its related feature screen.
class ResidentNotificationsView extends StatefulWidget {
  const ResidentNotificationsView({super.key});

  @override
  State<ResidentNotificationsView> createState() =>
      _ResidentNotificationsViewState();
}

class _ResidentNotificationsViewState extends State<ResidentNotificationsView> {
  int _selectedFilter = 0;

  static const _filters = ['All', 'Unread', 'Updates'];

  Iterable<NotificationModel> _visibleNotifications(
    List<NotificationModel> notifications,
  ) {
    return switch (_selectedFilter) {
      1 => notifications.where((item) => item.unread),
      2 => notifications.where((item) => item.isCommunityUpdate),
      _ => notifications,
    };
  }

  // Notification UI feature: marks a notification as read and opens its marketplace/chat/service/community destination.
  Future<void> _handleTap(NotificationModel notification) async {
    final provider = context.read<NotificationProvider>();
    if (notification.unread) {
      await provider.markRead(notification.id);
    }
    if (!mounted) return;
    await navigateFromNotification(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = _visibleNotifications(provider.notifications).toList();
    final hasUnread = provider.unreadCount > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: _kBrandTeal,
            onRefresh: () async {},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NotificationsHeader(
                              onMarkAllRead: hasUnread
                                  ? () => provider.markAllRead()
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _HeroNoticeCard(),
                            const SizedBox(height: 16),
                            _FilterBar(
                              filters: _filters,
                              selectedIndex: _selectedFilter,
                              onChanged: (index) =>
                                  setState(() => _selectedFilter = index),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.isLoading && notifications.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _kBrandTeal),
                      ),
                    ),
                  )
                else if (notifications.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: 48,
                                color: context.appMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                switch (_selectedFilter) {
                                  1 => 'No unread notifications',
                                  2 => 'No residence updates yet',
                                  _ => 'No notifications yet',
                                },
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appInk,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Messages, connection requests, marketplace activity, and residence announcements will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _kMaxContentWidth,
                            ),
                            child: _NotificationCard(
                              notification: notification,
                              onTap: () => _handleTap(notification),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (provider.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Could not load live notifications.',
                            style: TextStyle(color: context.appMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({this.onMarkAllRead});

  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
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
            'Notifications',
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          if (onMarkAllRead != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onMarkAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: _kBrandTeal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroNoticeCard extends StatelessWidget {
  const _HeroNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.12,
          blurRadius: 26,
          dy: 14,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: _kBrandTeal,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay in the loop',
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Important residence updates, community actions, and admin announcements are collected here.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.07,
          blurRadius: 16,
          dy: 8,
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == filters.length - 1 ? 0 : 4,
                ),
                child: _FilterPill(
                  label: filters[index],
                  selected: selectedIndex == index,
                  onTap: () => onChanged(index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _kBrandTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              boxShadow: selected
                  ? context.softSurfaceShadow(
                      lightOpacity: 0.15,
                      blurRadius: 12,
                      dy: 5,
                    )
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? onPrimary : context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.10,
          blurRadius: 22,
          dy: 10,
        ),
      ),
      child: Material(
        color: context.glassFill(lightAlpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: notification.accentColor.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appInk,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (notification.unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFF90170B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Chip(
                            label: notification.displayCategory,
                            color: notification.accentColor,
                          ),
                          const Spacer(),
                          Text(
                            notification.relativeTime,
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
