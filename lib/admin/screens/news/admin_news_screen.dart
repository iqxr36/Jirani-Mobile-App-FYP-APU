import 'package:flutter/material.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminNewsScreen extends StatelessWidget {
  const AdminNewsScreen({super.key});

  static const _posts = <_NewsPost>[
    _NewsPost(
      title: 'Lift maintenance notice',
      category: 'Maintenance',
      status: 'Scheduled',
      date: 'Jun 18',
      audience: 'All residents',
      body:
          'Tower A lift maintenance is planned from 10:00 AM to 1:00 PM. Residents are advised to use the service lift during the maintenance window.',
      icon: Icons.build_circle_outlined,
      color: AdminColors.warning,
    ),
    _NewsPost(
      title: 'Community weekend breakfast',
      category: 'Event',
      status: 'Draft',
      date: 'Jun 22',
      audience: 'One South Residence',
      body:
          'A casual breakfast gathering at the multipurpose hall. Admins can publish final event details once confirmed.',
      icon: Icons.event_available_outlined,
      color: AdminColors.primary,
    ),
    _NewsPost(
      title: 'Security reminder',
      category: 'Notice',
      status: 'Published',
      date: 'Today',
      audience: 'Verified residents',
      body:
          'Residents are reminded not to share access cards and to report unknown visitors to the guardhouse.',
      icon: Icons.shield_outlined,
      color: AdminColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final community = admin.communityName.isNotEmpty
        ? admin.communityName
        : 'Current community';

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'News & announcements',
          subtitle:
              'Create residence news, event posts, and maintenance notices for residents.',
          controls: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('New post'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Schedule'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const AdminCommunityScopeBanner(),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = JiraniResponsive.isAdminWide(constraints.maxWidth);
            if (!wide) {
              return Column(
                children: [
                  _ComposerPanel(community: community),
                  const SizedBox(height: 18),
                  const _InsightsGrid(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _ComposerPanel(community: community)),
                const SizedBox(width: 18),
                const Expanded(flex: 4, child: _InsightsGrid()),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'Publishing queue',
          action: '${_posts.length} posts',
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var index = 0; index < _posts.length; index++) ...[
                _NewsQueueCard(post: _posts[index]),
                if (index != _posts.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerPanel extends StatelessWidget {
  const _ComposerPanel({required this.community});

  final String community;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _adminElevatedDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AdminColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compose resident update',
                        style: TextStyle(
                          color: AdminColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Draft news once, then publish it to the resident carousel and notification center.',
                        style: TextStyle(color: AdminColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ScopeChip(
                  icon: Icons.apartment_rounded,
                  label: community,
                  color: AdminColors.primary,
                ),
                const _ScopeChip(
                  icon: Icons.visibility_outlined,
                  label: 'Residents preview',
                  color: AdminColors.accent,
                ),
                const _ScopeChip(
                  icon: Icons.notifications_active_outlined,
                  label: 'Push-ready',
                  color: AdminColors.success,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _FieldPreview(
              label: 'Post title',
              value: 'Water supply interruption notice',
            ),
            const SizedBox(height: 12),
            const _FieldPreview(
              label: 'Resident message',
              value:
                  'Water supply may be temporarily interrupted from 9:00 AM to 12:00 PM while maintenance work is carried out.',
              tall: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsGrid extends StatelessWidget {
  const _InsightsGrid();

  @override
  Widget build(BuildContext context) {
    return AdminResponsiveGrid(
      minTileWidth: 180,
      mainAxisExtent: 132,
      children: const [
        _NewsMetricCard(
          label: 'Published',
          value: '12',
          icon: Icons.check_circle_outline_rounded,
          color: AdminColors.success,
        ),
        _NewsMetricCard(
          label: 'Drafts',
          value: '4',
          icon: Icons.edit_note_rounded,
          color: AdminColors.primary,
        ),
        _NewsMetricCard(
          label: 'Scheduled',
          value: '3',
          icon: Icons.schedule_rounded,
          color: AdminColors.warning,
        ),
        _NewsMetricCard(
          label: 'Residents reached',
          value: '86%',
          icon: Icons.trending_up_rounded,
          color: AdminColors.accent,
        ),
      ],
    );
  }
}

class _NewsMetricCard extends StatelessWidget {
  const _NewsMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _adminElevatedDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                color: color.withValues(alpha: 0.55),
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsQueueCard extends StatelessWidget {
  const _NewsQueueCard({required this.post});

  final _NewsPost post;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: post.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(post.icon, color: post.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            color: AdminColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _StatusPill(label: post.status, color: post.color),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.category_outlined,
                          label: post.category,
                        ),
                        _MetaChip(
                          icon: Icons.calendar_month_outlined,
                          label: post.date,
                        ),
                        _MetaChip(
                          icon: Icons.people_alt_outlined,
                          label: post.audience,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Open post',
                onPressed: () {},
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldPreview extends StatelessWidget {
  const _FieldPreview({
    required this.label,
    required this.value,
    this.tall = false,
  });

  final String label;
  final String value;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, 14, tall ? 22 : 12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Chip(icon: icon, label: label, color: color);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Chip(icon: icon, label: label, color: AdminColors.muted);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

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
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _adminElevatedDecoration() {
  return BoxDecoration(
    color: AdminColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AdminColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 24,
        spreadRadius: -10,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class _NewsPost {
  const _NewsPost({
    required this.title,
    required this.category,
    required this.status,
    required this.date,
    required this.audience,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String category;
  final String status;
  final String date;
  final String audience;
  final String body;
  final IconData icon;
  final Color color;
}
