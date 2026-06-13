import 'package:flutter/material.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/utils/admin_formatters.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AdminScrollBehavior extends ScrollBehavior {
  const AdminScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class AdminPageScroll extends StatelessWidget {
  const AdminPageScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(20),
    this.fillChild = false,
  });

  final String title;
  final String? action;
  final Widget child;
  final EdgeInsets padding;
  final bool fillChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: adminSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (action != null)
                  Text(
                    action!,
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (fillChild)
            Expanded(child: Padding(padding: padding, child: child))
          else
            Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class AdminControlBar extends StatelessWidget {
  const AdminControlBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controls,
  });

  final String title;
  final String subtitle;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminSurfaceDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidth =
              constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: titleWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AdminColors.muted),
                    ),
                  ],
                ),
              ),
              Wrap(spacing: 10, runSpacing: 10, children: controls),
            ],
          );
        },
      ),
    );
  }
}

class AdminResponsiveGrid extends StatelessWidget {
  const AdminResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.mainAxisExtent = 188,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count =
            (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class AdminCommunityScopeBanner extends StatelessWidget {
  const AdminCommunityScopeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final authUser = context.watch<AuthViewModel>().currentAdmin;
    final isSystemAdmin = admin.includeAllCommunities;
    final communityName = admin.communityName.isNotEmpty
        ? admin.communityName
        : authUser?.communityName.trim() ?? '';
    final communityId = admin.communityId.isNotEmpty
        ? admin.communityId
        : authUser?.communityId.trim() ?? '';
    final hasScope =
        isSystemAdmin ||
        communityId.trim().isNotEmpty ||
        communityName.trim().isNotEmpty;

    final title = isSystemAdmin
        ? 'System admin access'
        : hasScope
        ? 'Community admin scope'
        : 'Community assignment required';
    final body = isSystemAdmin
        ? 'You are viewing admin records across all communities.'
        : hasScope
        ? 'Showing residents and verification requests for ${communityName.isEmpty ? communityId : communityName}.'
        : 'This admin account has no communityId or communityName in Firestore, so community-scoped admin records are hidden.';
    final color = hasScope ? AdminColors.primary : AdminColors.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSystemAdmin
                ? Icons.admin_panel_settings_rounded
                : hasScope
                ? Icons.home_work_rounded
                : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: AdminColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
