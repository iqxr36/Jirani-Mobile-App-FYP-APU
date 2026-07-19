// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_post_detail_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/shared/models/community_post_model.dart';
import 'package:jirani/shared/services/community_post_service.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const String _kUnavailableMessage = 'This update is no longer available.';

class CommunityPostDetailView extends StatefulWidget {
  const CommunityPostDetailView({super.key, required this.postId});

  final String postId;

  @override
  State<CommunityPostDetailView> createState() =>
      _CommunityPostDetailViewState();
}

class _CommunityPostDetailViewState extends State<CommunityPostDetailView> {
  final _service = CommunityPostService();
  CommunityPostModel? _post;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await _service.getPublishedPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _mapLoadError(error);
        _loading = false;
      });
    }
  }

  String _mapLoadError(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return _kUnavailableMessage;
    }
    final raw = error.toString();
    if (raw.contains('permission-denied') ||
        raw.contains('PERMISSION_DENIED')) {
      return _kUnavailableMessage;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: _kBrandTeal,
                    ),
                    const Expanded(
                      child: Text(
                        'Community update',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kBrandTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kBrandTeal));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.left,
            style: TextStyle(color: context.appMuted),
          ),
        ),
      );
    }

    final post = _post;
    if (post == null) {
      return Center(
        child: Text(
          _kUnavailableMessage,
          style: TextStyle(color: context.appMuted),
        ),
      );
    }

    final publishedLabel = post.publishedAt == null
        ? (post.expiredAt == null
              ? ''
              : DateFormat('d MMM yyyy').format(post.expiredAt!))
        : DateFormat('d MMM yyyy').format(post.publishedAt!);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => ColoredBox(
                    color: context.appMuted.withValues(alpha: 0.1),
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: post.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(post.icon, size: 16, color: post.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      post.displayCategory,
                      style: TextStyle(
                        color: post.accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isStatusExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.appMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Expired',
                    style: TextStyle(
                      color: context.appMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: context.appInk,
            ),
          ),
          if (publishedLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              publishedLabel,
              style: TextStyle(
                color: context.appMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            post.body,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: context.appInk,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
