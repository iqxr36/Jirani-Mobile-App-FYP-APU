import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_post_model.dart';
import 'package:jirani/shared/services/community_post_service.dart';
import 'package:provider/provider.dart';

const int _kMaxCoverImageBytes = 5 * 1024 * 1024;
const String _durationOneDay = 'oneDay';
const String _durationOneWeek = 'oneWeek';
const String _durationOneMonth = 'oneMonth';

// Admin community posts UI feature: creates, edits, publishes, and deletes community news/announcement posts.
class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _service = CommunityPostService();
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _postType = AppConstants.communityPostTypeNews;
  Uint8List? _coverImageBytes;
  String _coverImageFileName = '';
  String? _coverImageMimeType;
  bool _submitting = false;
  bool _scheduleEnabled = false;
  DateTime? _scheduledPublishAt;
  String _publishDuration = _durationOneWeek;
  String? _lastReconciledCommunityId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _queueLifecycleReconcile(String communityId) {
    final trimmed = communityId.trim();
    if (trimmed.isEmpty || trimmed == _lastReconciledCommunityId) return;
    _lastReconciledCommunityId = trimmed;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _service.reconcileScheduledPosts(communityId: trimmed);
      } catch (_) {
        // Backend scheduler is the source of truth; the page reconcile is best effort.
      }
    });
  }

  // Admin community posts UI feature: picks and validates a cover image before upload.
  Future<_PickedCoverImage?> _pickCoverImageBytes() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > _kMaxCoverImageBytes) {
      _showSnack('Choose a cover image under 5 MB.');
      return null;
    }
    return _PickedCoverImage(
      bytes: bytes,
      fileName: picked.name,
      mimeType: picked.mimeType,
    );
  }

  // Admin community posts UI feature: stores the selected cover image for a new draft.
  Future<void> _pickCoverImage() async {
    if (_submitting) return;
    final picked = await _pickCoverImageBytes();
    if (picked == null || !mounted) return;
    setState(() {
      _coverImageBytes = picked.bytes;
      _coverImageFileName = picked.fileName;
      _coverImageMimeType = picked.mimeType;
    });
  }

  // Admin community posts UI feature: clears the selected cover image from the draft form.
  void _removeCoverImage() {
    if (_submitting) return;
    setState(() {
      _coverImageBytes = null;
      _coverImageFileName = '';
      _coverImageMimeType = null;
    });
  }

  Future<void> _pickScheduledDateTime() async {
    if (_submitting) return;
    final now = DateTime.now();
    final base = _scheduledPublishAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduleEnabled = true;
      _scheduledPublishAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _clearSchedule() {
    if (_submitting) return;
    setState(() {
      _scheduleEnabled = false;
      _scheduledPublishAt = null;
    });
  }

  // Admin community posts UI feature: creates a draft post in Firestore.
  Future<void> _createDraft(AdminProvider admin) async {
    final communityId = admin.communityId.trim();
    final authorId = admin.currentAdminUid;
    if (communityId.isEmpty || authorId == null) {
      _showSnack('Select a community before creating posts.');
      return;
    }
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      _showSnack('Title and message are required.');
      return;
    }
    final scheduledPublishAt = _scheduleEnabled ? _scheduledPublishAt : null;
    if (_scheduleEnabled && scheduledPublishAt == null) {
      _showSnack('Choose when this draft should be published.');
      return;
    }
    if (scheduledPublishAt != null &&
        !scheduledPublishAt.isAfter(DateTime.now())) {
      _showSnack('Schedule the publish time in the future.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final expiresAt = scheduledPublishAt == null
          ? null
          : _expiresAtFor(scheduledPublishAt, _publishDuration);
      final draft = await _service.createDraft(
        communityId: communityId,
        authorId: authorId,
        authorName: admin.communityName.isNotEmpty
            ? admin.communityName
            : 'Community admin',
        type: _postType,
        title: _titleController.text,
        body: _bodyController.text,
        scheduledPublishAt: scheduledPublishAt,
        expiresAt: expiresAt,
        publishDuration: _publishDuration,
      );
      final coverBytes = _coverImageBytes;
      if (coverBytes != null && coverBytes.isNotEmpty) {
        final imageUrl = await _service.uploadCoverImage(
          adminId: authorId,
          postId: draft.id,
          bytes: coverBytes,
          originalFileName: _coverImageFileName,
          mimeType: _coverImageMimeType,
        );
        await _service.updatePost(
          postId: draft.id,
          authorId: authorId,
          imageUrl: imageUrl,
        );
      }
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _coverImageBytes = null;
        _coverImageFileName = '';
        _coverImageMimeType = null;
        _scheduleEnabled = false;
        _scheduledPublishAt = null;
        _publishDuration = _durationOneWeek;
      });
      if (mounted) {
        _showSnack(
          scheduledPublishAt == null
              ? 'Draft saved.'
              : 'Draft scheduled for ${_formatDateTime(scheduledPublishAt)}.',
        );
      }
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Admin community posts UI feature: replaces the cover image for an existing post.
  Future<void> _replacePostCover(
    CommunityPostModel post,
    AdminProvider admin,
  ) async {
    final authorId = admin.currentAdminUid;
    if (authorId == null || _submitting) return;

    final picked = await _pickCoverImageBytes();
    if (picked == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _service.replaceCoverImage(
        postId: post.id,
        authorId: authorId,
        bytes: picked.bytes,
        originalFileName: picked.fileName,
        mimeType: picked.mimeType,
      );
      if (mounted) _showSnack('Cover photo updated.');
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Admin community posts UI feature: publishes a post, which triggers resident notification fan-out.
  Future<void> _publish(CommunityPostModel post, AdminProvider admin) async {
    final authorId = admin.currentAdminUid;
    if (authorId == null) return;
    setState(() => _submitting = true);
    try {
      await _service.publishPost(
        postId: post.id,
        authorId: authorId,
        publishDuration: post.publishDuration,
      );
      if (mounted) {
        _showSnack('Published to residents. Notifications will be sent.');
      }
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Admin community posts UI feature: deletes a draft or published community post.
  Future<void> _deletePost(CommunityPostModel post, AdminProvider admin) async {
    final adminId = admin.currentAdminUid;
    if (adminId == null) return;
    if (_submitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(post.isPublished ? 'Remove published post?' : 'Delete draft?'),
          content: Text(
            post.isPublished
                ? 'Residents will no longer see "${post.title}" in their home feed. This cannot be undone.'
                : 'Delete "${post.title}" from your publishing queue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _service.deletePost(
        postId: post.id,
        adminId: adminId,
        communityId: admin.communityId,
      );
      if (mounted) {
        _showSnack(
          post.isPublished ? 'Post removed from residents.' : 'Draft deleted.',
        );
      }
    } catch (error) {
      if (mounted) _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static DateTime _expiresAtFor(DateTime publishAt, String duration) {
    return switch (duration) {
      _durationOneDay => publishAt.add(const Duration(days: 1)),
      _durationOneMonth => DateTime(
          publishAt.year,
          publishAt.month + 1,
          publishAt.day,
          publishAt.hour,
          publishAt.minute,
        ),
      _ => publishAt.add(const Duration(days: 7)),
    };
  }

  static String _formatDateTime(DateTime value) {
    return DateFormat('MMM d, yyyy h:mm a').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final communityId = admin.communityId.trim();
    _queueLifecycleReconcile(communityId);
    final community = admin.communityName.isNotEmpty
        ? admin.communityName
        : 'Current community';

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'News studio',
          subtitle:
              'Plan, schedule, publish, and expire resident updates for your community.',
          controls: [
            FilledButton.icon(
              onPressed: _submitting ? null : () => _createDraft(admin),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Save draft'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const AdminCommunityScopeBanner(),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'Compose resident update',
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Publishing to $community',
                style: const TextStyle(color: AdminColors.muted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _postType,
                decoration: const InputDecoration(labelText: 'Post type'),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.communityPostTypeNews,
                    child: Text('News'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.communityPostTypeAnnouncement,
                    child: Text('Announcement'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.communityPostTypeWarning,
                    child: Text('Warning'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.communityPostTypeEvent,
                    child: Text('Event'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.communityPostTypeMaintenance,
                    child: Text('Maintenance'),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _postType = value);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Post title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                enabled: !_submitting,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Resident message',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              _ScheduleComposer(
                enabled: _scheduleEnabled,
                scheduledAt: _scheduledPublishAt,
                duration: _publishDuration,
                disabled: _submitting,
                onToggle: (value) {
                  if (_submitting) return;
                  setState(() {
                    _scheduleEnabled = value;
                    if (value && _scheduledPublishAt == null) {
                      _scheduledPublishAt =
                          DateTime.now().add(const Duration(hours: 1));
                    }
                  });
                },
                onPickDateTime: _pickScheduledDateTime,
                onClear: _clearSchedule,
                onDurationChanged: (value) {
                  if (_submitting) return;
                  setState(() => _publishDuration = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickCoverImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add cover photo'),
                  ),
                  if (_coverImageBytes != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _submitting ? null : _removeCoverImage,
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
              if (_coverImageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _coverImageBytes!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (communityId.isEmpty)
          const AdminPanel(
            title: 'Publishing queue',
            padding: EdgeInsets.all(20),
            child: Text('Configure a community scope to manage posts.'),
          )
        else
          StreamBuilder<List<CommunityPostModel>>(
            stream: _service.watchCommunityPosts(communityId: communityId),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const <CommunityPostModel>[];
              final stats = _NewsStats.fromPosts(posts);
              return AdminPanel(
                title: 'Publishing queue',
                action: '${posts.length} posts',
                padding: const EdgeInsets.all(16),
                child: posts.isEmpty
                    ? const Text(
                        'No posts yet. Save a draft, then publish it.',
                        style: TextStyle(color: AdminColors.muted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NewsIntelligenceRow(stats: stats),
                          const SizedBox(height: 14),
                          for (var index = 0; index < posts.length; index++) ...[
                            _NewsQueueCard(
                              post: posts[index],
                              onPublish: posts[index].isDraft && !_submitting
                                  ? () => _publish(posts[index], admin)
                                  : null,
                              onReplaceCover: !_submitting
                                  ? () => _replacePostCover(posts[index], admin)
                                  : null,
                              onDelete: !_submitting
                                  ? () => _deletePost(posts[index], admin)
                                  : null,
                            ),
                            if (index != posts.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }
}

class _ScheduleComposer extends StatelessWidget {
  const _ScheduleComposer({
    required this.enabled,
    required this.scheduledAt,
    required this.duration,
    required this.disabled,
    required this.onToggle,
    required this.onPickDateTime,
    required this.onClear,
    required this.onDurationChanged,
  });

  final bool enabled;
  final DateTime? scheduledAt;
  final String duration;
  final bool disabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickDateTime;
  final VoidCallback onClear;
  final ValueChanged<String> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    final expiresAt = scheduledAt == null
        ? null
        : _AdminNewsScreenState._expiresAtFor(scheduledAt!, duration);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule_send_outlined,
                  color: AdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publishing schedule',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Save now, publish later, and return to drafts after the selected duration.',
                      style: TextStyle(color: AdminColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: disabled ? null : onToggle,
                activeTrackColor: AdminColors.primary,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: disabled ? null : onPickDateTime,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    scheduledAt == null
                        ? 'Choose date and time'
                        : _AdminNewsScreenState._formatDateTime(scheduledAt!),
                  ),
                ),
                TextButton.icon(
                  onPressed: disabled ? null : onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _DurationChip(value: _durationOneDay, label: '1 day'),
              _DurationChip(value: _durationOneWeek, label: '1 week'),
              _DurationChip(value: _durationOneMonth, label: '1 month'),
            ].map((chip) {
              return ChoiceChip(
                label: Text(chip.label),
                selected: duration == chip.value,
                onSelected: disabled
                    ? null
                    : (_) => onDurationChanged(chip.value),
                selectedColor: AdminColors.primary.withValues(alpha: 0.14),
                labelStyle: TextStyle(
                  color: duration == chip.value
                      ? AdminColors.primary
                      : AdminColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: duration == chip.value
                      ? AdminColors.primary
                      : AdminColors.border,
                ),
              );
            }).toList(),
          ),
          if (enabled && expiresAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Residents will see it until ${_AdminNewsScreenState._formatDateTime(expiresAt)}.',
              style: const TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ] else if (!enabled) ...[
            const SizedBox(height: 10),
            const Text(
              'When you publish manually, the post returns to drafts after this duration.',
              style: TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _DurationChip {
  const _DurationChip({required this.value, required this.label});

  final String value;
  final String label;
}

class _NewsStats {
  const _NewsStats({
    required this.published,
    required this.scheduled,
    required this.drafts,
    required this.expiringSoon,
  });

  final int published;
  final int scheduled;
  final int drafts;
  final int expiringSoon;

  factory _NewsStats.fromPosts(List<CommunityPostModel> posts) {
    final now = DateTime.now();
    return _NewsStats(
      published: posts.where((post) => post.isPublished).length,
      scheduled: posts.where((post) => post.isScheduled).length,
      drafts: posts.where((post) => post.isDraft && !post.isScheduled).length,
      expiringSoon: posts.where((post) {
        final expiresAt = post.expiresAt;
        return post.isPublished &&
            expiresAt != null &&
            expiresAt.isAfter(now) &&
            expiresAt.difference(now).inHours <= 24;
      }).length,
    );
  }
}

class _NewsIntelligenceRow extends StatelessWidget {
  const _NewsIntelligenceRow({required this.stats});

  final _NewsStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 720
            ? constraints.maxWidth
            : (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _NewsStatTile(
              width: width,
              icon: Icons.campaign_outlined,
              label: 'Live now',
              value: stats.published.toString(),
              color: AdminColors.success,
            ),
            _NewsStatTile(
              width: width,
              icon: Icons.schedule_send_outlined,
              label: 'Scheduled',
              value: stats.scheduled.toString(),
              color: AdminColors.primary,
            ),
            _NewsStatTile(
              width: width,
              icon: Icons.edit_note_rounded,
              label: 'Saved drafts',
              value: stats.drafts.toString(),
              color: AdminColors.warning,
            ),
            _NewsStatTile(
              width: width,
              icon: Icons.timer_outlined,
              label: 'Expire in 24h',
              value: stats.expiringSoon.toString(),
              color: AdminColors.danger,
            ),
          ],
        );
      },
    );
  }
}

class _NewsStatTile extends StatelessWidget {
  const _NewsStatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AdminColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Admin community posts UI feature: carries picked cover image bytes and filename.
class _PickedCoverImage {
  const _PickedCoverImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}

class _NewsQueueCard extends StatelessWidget {
  const _NewsQueueCard({
    required this.post,
    this.onPublish,
    this.onReplaceCover,
    this.onDelete,
  });

  final CommunityPostModel post;
  final VoidCallback? onPublish;
  final VoidCallback? onReplaceCover;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d').format(post.publishedAt ?? post.updatedAt);
    final status = post.isPublished
        ? 'Published'
        : post.isScheduled
            ? 'Scheduled'
            : 'Draft';
    final statusColor = post.isPublished
        ? AdminColors.success
        : post.isScheduled
            ? AdminColors.primary
            : AdminColors.warning;
    final scheduledAt = post.scheduledPublishAt;
    final expiresAt = post.expiresAt;

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: post.accentColor.withValues(alpha: 0.12),
                        child: Icon(post.icon, color: post.accentColor),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: post.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(post.icon, color: post.accentColor),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _QueueBadge(label: status, color: statusColor),
                          Text(
                            '$date - ${post.displayCategory}',
                            style: const TextStyle(color: AdminColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onPublish != null || onReplaceCover != null || onDelete != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (onPublish != null)
                        FilledButton(
                          onPressed: onPublish,
                          child: const Text('Publish'),
                        ),
                      if (onReplaceCover != null)
                        OutlinedButton.icon(
                          onPressed: onReplaceCover,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Replace cover'),
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: AdminColors.danger,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.ink, height: 1.4),
            ),
            if (scheduledAt != null || expiresAt != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (scheduledAt != null)
                    _QueueMetaPill(
                      icon: Icons.schedule_send_outlined,
                      text:
                          'Publishes ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
                    ),
                  if (expiresAt != null)
                    _QueueMetaPill(
                      icon: Icons.timer_outlined,
                      text:
                          'Returns to drafts ${DateFormat('MMM d, h:mm a').format(expiresAt)}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QueueMetaPill extends StatelessWidget {
  const _QueueMetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AdminColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
