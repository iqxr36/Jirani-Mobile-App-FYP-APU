import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';

class ItemRepository {
  ItemRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<ItemModel>> watchAvailableItems({
    String? searchQuery,
    String? category,
    String? communityId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.itemsCollection)
        .where('status', isEqualTo: AppConstants.itemStatusAvailable)
        .where('isArchived', isEqualTo: false);

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    if (communityId != null && communityId.isNotEmpty) {
      query = query.where('communityId', isEqualTo: communityId);
    }

    return query.snapshots().map((snapshot) {
      final currentUid = _auth.currentUser?.uid;
      final items = snapshot.docs
          .map((d) => ItemModel.fromMap(d.id, d.data()))
          .where((item) => currentUid == null || item.ownerId != currentUid)
          .toList(growable: false);

      final q = (searchQuery ?? '').trim().toLowerCase();
      final filtered = q.isEmpty
          ? items
          : items
                .where((item) {
                  return item.title.toLowerCase().contains(q) ||
                      item.category.toLowerCase().contains(q) ||
                      item.description.toLowerCase().contains(q);
                })
                .toList(growable: false);

      final sorted = filtered.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    });
  }

  Stream<List<ItemModel>> watchMyItems() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<ItemModel>>.value(const <ItemModel>[]);
    }

    final query = _firestore
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: uid);

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((d) => ItemModel.fromMap(d.id, d.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.itemsCollection)
          .doc(itemId)
          .get();
      final data = doc.data();
      if (data == null) return null;
      return ItemModel.fromMap(doc.id, data);
    } catch (e) {
      throw Exception('Failed to load item details.');
    }
  }

  Future<void> addItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required List<String> imagePaths,
    required bool hasUsageFee,
    double? feeAmount,
    required bool hasDeposit,
    double? depositAmount,
    required String pickupInstructions,
    required AppUser currentUser,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to publish an item.');
    }
    if (currentUser.uid != uid) {
      throw Exception('You can only publish items from your own profile.');
    }
    if (!currentUser.isVerifiedResident) {
      throw Exception('Only verified residents can list marketplace items.');
    }
    if (imagePaths.isEmpty) {
      throw Exception('Add at least one item photo.');
    }

    try {
      final docRef = _firestore.collection(AppConstants.itemsCollection).doc();
      final imageUrls = await uploadItemImages(
        uid: uid,
        itemId: docRef.id,
        filePaths: imagePaths,
      );

      final resolvedLendingType = _deriveLendingType(
        hasUsageFee: hasUsageFee,
        hasDeposit: hasDeposit,
      );
      await docRef.set({
        'ownerId': uid,
        'ownerName': currentUser.fullName,
        'ownerEmail': currentUser.email,
        'ownerPhotoUrl': currentUser.profileImageUrl,
        'ownerVerified': currentUser.isVerifiedResident,
        'ownerReputationScore': currentUser.reputationScore.toDouble(),
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'condition': condition,
        'imageUrls': imageUrls,
        'lendingType': resolvedLendingType,
        'hasUsageFee': hasUsageFee,
        'feeAmount': hasUsageFee ? feeAmount : null,
        'hasDeposit': hasDeposit,
        'depositAmount': hasDeposit ? depositAmount : null,
        'status': AppConstants.itemStatusAvailable,
        'communityId': currentUser.communityId,
        'communityName': currentUser.communityName,
        'pickupInstructions': pickupInstructions.trim(),
        'isArchived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to publish item. Please try again.');
    }
  }

  Future<void> updateItem({
    required String itemId,
    required String title,
    required String description,
    required String category,
    required String condition,
    required bool hasUsageFee,
    double? feeAmount,
    required bool hasDeposit,
    double? depositAmount,
    required String pickupInstructions,
    List<String>? newImagePaths,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in.');
    }

    final docRef = _firestore
        .collection(AppConstants.itemsCollection)
        .doc(itemId);
    final snap = await docRef.get();
    final data = snap.data();
    if (data == null) {
      throw Exception('Item not found.');
    }
    if ((data['ownerId'] as String?) != uid) {
      throw Exception('You can only edit your own item.');
    }

    try {
      final existing = ItemModel.fromMap(snap.id, data);
      var imageUrls = existing.imageUrls;
      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        final uploaded = await uploadItemImages(
          uid: uid,
          itemId: itemId,
          filePaths: newImagePaths,
        );
        imageUrls = <String>[...existing.imageUrls, ...uploaded];
      }

      final resolvedLendingType = _deriveLendingType(
        hasUsageFee: hasUsageFee,
        hasDeposit: hasDeposit,
      );
      await docRef.update({
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'condition': condition,
        'lendingType': resolvedLendingType,
        'hasUsageFee': hasUsageFee,
        'feeAmount': hasUsageFee ? feeAmount : null,
        'hasDeposit': hasDeposit,
        'depositAmount': hasDeposit ? depositAmount : null,
        'pickupInstructions': pickupInstructions.trim(),
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item.');
    }
  }

  Future<void> archiveItem(String itemId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in.');
    }

    final docRef = _firestore
        .collection(AppConstants.itemsCollection)
        .doc(itemId);
    final snap = await docRef.get();
    final data = snap.data();
    if (data == null) {
      throw Exception('Item not found.');
    }
    if ((data['ownerId'] as String?) != uid) {
      throw Exception('You can only archive your own item.');
    }

    try {
      await docRef.update({
        'isArchived': true,
        'status': AppConstants.itemStatusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to archive item.');
    }
  }

  Future<List<String>> uploadItemImages({
    required String uid,
    required String itemId,
    required List<String> filePaths,
  }) async {
    if (filePaths.isEmpty) return const <String>[];

    final urls = <String>[];
    for (final filePath in filePaths) {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final objectName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage
          .ref()
          .child(AppConstants.storageItemImagesPath)
          .child(uid)
          .child(itemId)
          .child(objectName);

      try {
        await ref.putFile(File(filePath));
        urls.add(await ref.getDownloadURL());
      } catch (e) {
        throw Exception('Failed to upload item images.');
      }
    }
    return urls;
  }

  static String _deriveLendingType({
    required bool hasUsageFee,
    required bool hasDeposit,
  }) {
    if (hasUsageFee && hasDeposit) return AppConstants.lendingTypeFeeAndDeposit;
    if (hasUsageFee) return AppConstants.lendingTypeSmallFee;
    if (hasDeposit) return AppConstants.lendingTypeDepositRequired;
    return AppConstants.lendingTypeFree;
  }
}
