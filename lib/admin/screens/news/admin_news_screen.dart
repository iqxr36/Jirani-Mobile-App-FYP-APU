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

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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
    setState(() => _submitting = true);
    try {
      final draft = await _service.createDraft(
        communityId: communityId,
        authorId: authorId,
        authorName: admin.communityName.isNotEmpty
            ? admin.communityName
            : 'Community admin',
        type: _postType,
        title: _titleController.text,
        body: _bodyController.text,
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
      });
      if (mounted) _showSnack('Draft saved.');
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
      await _service.publishPost(postId: post.id, authorId: authorId);
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

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final communityId = admin.communityId.trim();
    final community = admin.communityName.isNotEmpty
        ? admin.communityName
        : 'Current community';

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'News & announcements',
          subtitle:
              'Create news, announcements, warnings, events, and maintenance notices for residents.',
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
                value: _postType,
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
                        children: [
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
    final status = post.isPublished ? 'Published' : 'Draft';

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
                      errorWidget: (_, __, ___) => Container(
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
                      Text(
                        '$status · $date · ${post.displayCategory}',
                        style: const TextStyle(color: AdminColors.muted),
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
          ],
        ),
      ),
    );
  }
}
