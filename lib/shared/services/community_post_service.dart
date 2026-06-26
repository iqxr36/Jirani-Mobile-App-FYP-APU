import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_post_model.dart';

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
          .toList();
      posts.sort((a, b) {
        final aDate = a.publishedAt ?? a.updatedAt;
        final bDate = b.publishedAt ?? b.updatedAt;
        return bDate.compareTo(aDate);
      });
      return posts;
    });
  }

  Stream<List<CommunityPostModel>> watchPublishedPostsForCommunity(
    String communityId,
  ) {
    return watchCommunityPosts(communityId: communityId, publishedOnly: true);
  }

  Future<CommunityPostModel?> getPublishedPost(String postId) async {
    final id = postId.trim();
    if (id.isEmpty) return null;
    final snap = await _posts.doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    final post = CommunityPostModel.fromMap(snap.id, data);
    if (!post.isPublished) return null;
    return post;
  }

  Future<CommunityPostModel> createDraft({
    required String communityId,
    required String authorId,
    required String authorName,
    required String type,
    required String title,
    required String body,
    String audience = 'All residents',
    String? imageUrl,
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

  Future<String> uploadCoverImage({
    required String adminId,
    required String postId,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Cover image is empty.');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageCommunityPostImagesPath)
        .child(adminId)
        .child(postId)
        .child('cover_$ts.jpg');
    try {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
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

  Future<void> updatePost({
    required String postId,
    required String authorId,
    String? title,
    String? body,
    String? type,
    String? audience,
    String? imageUrl,
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
      await ref.update({
        if (title != null) 'title': title.trim(),
        if (body != null) 'body': body.trim(),
        if (type != null) 'type': type,
        if (audience != null) 'audience': audience.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  Future<void> publishPost({
    required String postId,
    required String authorId,
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
    try {
      await ref.update({
        'status': AppConstants.communityPostStatusPublished,
        'publishedAt': FieldValue.serverTimestamp(),
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
