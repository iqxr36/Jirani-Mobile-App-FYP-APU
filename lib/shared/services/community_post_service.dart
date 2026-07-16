import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_post_model.dart';

const String _durationOneDay = 'oneDay';
const String _durationOneWeek = 'oneWeek';
const String _durationOneMonth = 'oneMonth';

/// Community news service: manages admin-created news, announcements, warnings, events, and maintenance posts.
class CommunityPostService {
  CommunityPostService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(AppConstants.communityPostsCollection);

  /// Community news admin/resident feed: streams posts for a community, optionally only published posts.
  Stream<List<CommunityPostModel>> watchCommunityPosts({
    required String communityId,
    bool publishedOnly = false,
  }) {
    var query = _posts.where('communityId', isEqualTo: communityId.trim());
    if (publishedOnly) {
      query = query.where(
        'status',
        isEqualTo: AppConstants.communityPostStatusPublished,
      );
    }
    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => CommunityPostModel.fromMap(doc.id, doc.data()))
          .where((post) => !publishedOnly || post.isVisibleToResidents)
          .toList();
      posts.sort((a, b) {
        final aDate = a.publishedAt ?? a.updatedAt;
        final bDate = b.publishedAt ?? b.updatedAt;
        return bDate.compareTo(aDate);
      });
      return posts;
    });
  }

  /// Community news resident feed: streams published posts visible to residents in one community.
  Stream<List<CommunityPostModel>> watchPublishedPostsForCommunity(
    String communityId,
  ) {
    return watchCommunityPosts(communityId: communityId, publishedOnly: true);
  }

  /// Community news detail: loads a published or expired post for resident deep links.
  Future<CommunityPostModel?> getPublishedPost(String postId) async {
    final id = postId.trim();
    if (id.isEmpty) return null;
    final snap = await _posts.doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    final post = CommunityPostModel.fromMap(snap.id, data);
    if (!post.isReadableByResidents) return null;
    return post;
  }

  /// Community news admin flow: creates a draft post before publishing notifications to residents.
  Future<CommunityPostModel> createDraft({
    required String communityId,
    required String authorId,
    required String authorName,
    required String type,
    required String title,
    required String body,
    String audience = 'All residents',
    String? imageUrl,
    DateTime? scheduledPublishAt,
    DateTime? expiresAt,
    String publishDuration = _durationOneWeek,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != authorId) {
      throw Exception('Missing signed-in admin profile.');
    }
    final post = CommunityPostModel(
      id: '',
      communityId: communityId.trim(),
      type: type,
      title: title.trim(),
      body: body.trim(),
      status: AppConstants.communityPostStatusDraft,
      authorId: authorId,
      authorName: authorName.trim().isEmpty ? 'Admin' : authorName.trim(),
      audience: audience.trim().isEmpty ? 'All residents' : audience.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrl: imageUrl,
      scheduledPublishAt: scheduledPublishAt,
      expiresAt: expiresAt,
      publishDuration: _normalizePublishDuration(publishDuration),
    );
    try {
      final doc = _posts.doc();
      await doc.set({...post.toCreateMap(), 'id': doc.id});
      final saved = await doc.get();
      return CommunityPostModel.fromMap(saved.id, saved.data() ?? {});
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules are deployed and your '
          'admin profile has a valid communityId.',
        );
      }
      throw Exception(e.message ?? 'Failed to save draft.');
    }
  }

  /// Community news admin flow: uploads a post cover image to Firebase Storage.
  Future<String> uploadCoverImage({
    required String adminId,
    required String postId,
    required Uint8List bytes,
    String originalFileName = '',
    String? mimeType,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Cover image is empty.');
    }
    final extension = _coverImageExtension(
      fileName: originalFileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageCommunityPostImagesPath)
        .child(adminId)
        .child(postId)
        .child('cover_$ts.$extension');
    try {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _coverImageContentType(extension)),
      );
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
          'Permission denied uploading cover image. Check Storage rules are deployed.',
        );
      }
      throw Exception(e.message ?? 'Failed to upload cover image.');
    }
  }

  /// Community news admin flow: replaces a draft post cover image after author ownership validation.
  Future<void> replaceCoverImage({
    required String postId,
    required String authorId,
    required Uint8List bytes,
    String originalFileName = '',
    String? mimeType,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != authorId) {
      throw Exception('Missing signed-in admin profile.');
    }
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Post not found.');
    final post = CommunityPostModel.fromMap(snap.id, data);
    if (post.authorId != authorId) {
      throw Exception('Only the author can update this post cover.');
    }

    final imageUrl = await uploadCoverImage(
      adminId: authorId,
      postId: postId,
      bytes: bytes,
      originalFileName: originalFileName,
      mimeType: mimeType,
    );

    try {
      await ref.update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules are deployed and your '
          'admin profile has a valid communityId.',
        );
      }
      throw Exception(e.message ?? 'Failed to update post cover.');
    }
  }

  /// Community news storage: detects the safest image extension from MIME type, bytes, or filename.
  static String _coverImageExtension({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) {
    final mime = (mimeType ?? '').trim().toLowerCase();
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 12) {
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') return 'webp';
    }

    final trimmed = fileName.trim().toLowerCase();
    final extension = trimmed.contains('.') ? trimmed.split('.').last : 'jpg';
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension == 'jpeg' ? 'jpg' : extension,
      _ => 'jpg',
    };
  }

  /// Community news storage: maps supported image extensions to Storage content types.
  static String _coverImageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  /// Community news admin flow: edits draft post content before it is published.
  Future<void> updatePost({
    required String postId,
    required String authorId,
    String? title,
    String? body,
    String? type,
    String? audience,
    String? imageUrl,
    DateTime? scheduledPublishAt,
    DateTime? expiresAt,
    String? publishDuration,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != authorId) {
      throw Exception('Missing signed-in admin profile.');
    }
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Post not found.');
    final post = CommunityPostModel.fromMap(snap.id, data);
    if (post.authorId != authorId) {
      throw Exception('Only the author can edit this post.');
    }
    if (post.isPublished) {
      throw Exception('Published posts cannot be edited.');
    }
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) updates['title'] = title.trim();
      if (body != null) updates['body'] = body.trim();
      if (type != null) updates['type'] = type;
      if (audience != null) updates['audience'] = audience.trim();
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (publishDuration != null) {
        updates['publishDuration'] = _normalizePublishDuration(
          publishDuration,
        );
      }
      if (scheduledPublishAt != null) {
        updates['scheduledPublishAt'] = Timestamp.fromDate(scheduledPublishAt);
      }
      if (expiresAt != null) {
        updates['expiresAt'] = Timestamp.fromDate(expiresAt);
      }
      await ref.update(updates);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules are deployed and your '
          'admin profile has a valid communityId.',
        );
      }
      throw Exception(e.message ?? 'Failed to update post.');
    }
  }

  /// Community news admin flow: publishes a draft and lets Cloud Functions fan out resident notifications.
  Future<void> publishPost({
    required String postId,
    required String authorId,
    String? publishDuration,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != authorId) {
      throw Exception('Missing signed-in admin profile.');
    }
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Post not found.');
    final post = CommunityPostModel.fromMap(snap.id, data);
    if (post.authorId != authorId) {
      throw Exception('Only the author can publish this post.');
    }
    if (post.isPublished) return;
    final normalizedDuration = _normalizePublishDuration(
      publishDuration ?? post.publishDuration,
    );
    final publishAt = DateTime.now();
    final expiresAt = _expiresAtFor(publishAt, normalizedDuration);
    try {
      await ref.update({
        'status': AppConstants.communityPostStatusPublished,
        'publishedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'publishDuration': normalizedDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Community post notifications are created server-side by Cloud Functions.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules are deployed and your '
          'admin profile has a valid communityId.',
        );
      }
      throw Exception(e.message ?? 'Failed to publish post.');
    }
  }

  /// Community news lifecycle: publishes due scheduled drafts and marks expired posts as expired.
  Future<CommunityPostLifecycleResult> reconcileScheduledPosts({
    required String communityId,
  }) async {
    final trimmedCommunityId = communityId.trim();
    if (trimmedCommunityId.isEmpty) {
      return const CommunityPostLifecycleResult();
    }
    final now = DateTime.now();
    final snapshot = await _posts
        .where('communityId', isEqualTo: trimmedCommunityId)
        .get();
    final batch = _firestore.batch();
    var dueCount = 0;
    var expiredCount = 0;

    for (final doc in snapshot.docs) {
      final post = CommunityPostModel.fromMap(doc.id, doc.data());
      if (post.isScheduled &&
          post.scheduledPublishAt != null &&
          !post.scheduledPublishAt!.isAfter(now)) {
        final duration = _normalizePublishDuration(post.publishDuration);
        batch.update(doc.reference, {
          'status': AppConstants.communityPostStatusPublished,
          'publishedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(_expiresAtFor(now, duration)),
          'publishDuration': duration,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        dueCount++;
        continue;
      }

      if (post.isPublished &&
          post.expiresAt != null &&
          !post.expiresAt!.isAfter(now)) {
        batch.update(doc.reference, {
          'status': AppConstants.communityPostStatusExpired,
          'publishedAt': null,
          'scheduledPublishAt': null,
          'expiresAt': null,
          'expiredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        expiredCount++;
      }
    }

    if (dueCount > 0 || expiredCount > 0) {
      await batch.commit();
    }
    return CommunityPostLifecycleResult(
      published: dueCount,
      expired: expiredCount,
    );
  }

  static DateTime _expiresAtFor(DateTime publishAt, String duration) {
    return switch (_normalizePublishDuration(duration)) {
      _durationOneDay => publishAt.add(const Duration(days: 1)),
      _durationOneMonth => DateTime(
          publishAt.year,
          publishAt.month + 1,
          publishAt.day,
          publishAt.hour,
          publishAt.minute,
          publishAt.second,
          publishAt.millisecond,
          publishAt.microsecond,
        ),
      _ => publishAt.add(const Duration(days: 7)),
    };
  }

  static String _normalizePublishDuration(String value) {
    return switch (value.trim()) {
      _durationOneDay => _durationOneDay,
      _durationOneMonth => _durationOneMonth,
      _durationOneWeek => _durationOneWeek,
      _ => _durationOneWeek,
    };
  }

  /// Community news admin flow: deletes a post after checking admin identity and community scope.
  Future<void> deletePost({
    required String postId,
    required String adminId,
    String? communityId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != adminId) {
      throw Exception('Missing signed-in admin profile.');
    }
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final post = CommunityPostModel.fromMap(snap.id, data);
    final scopedCommunityId = communityId?.trim();
    if (scopedCommunityId != null &&
        scopedCommunityId.isNotEmpty &&
        post.communityId != scopedCommunityId) {
      throw Exception('This post belongs to a different community.');
    }
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules are deployed and your '
          'admin profile has a valid communityId.',
        );
      }
      throw Exception(e.message ?? 'Failed to delete post.');
    }
  }
}

class CommunityPostLifecycleResult {
  const CommunityPostLifecycleResult({
    this.published = 0,
    this.expired = 0,
  });

  final int published;
  final int expired;
}
