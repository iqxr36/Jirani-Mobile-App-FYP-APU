import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/item_listing_form.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';

// Marketplace listing data layer: validates listing ownership, stores item documents, and uploads item images.
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

  static const Set<String> _allowedImageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  };

  // Marketplace listing feature: streams available, unarchived items in the selected community and applies local search.
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

  // Marketplace listing feature: streams all listings owned by the signed-in lender.
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

  // Marketplace listing feature: fetches one listing document for details, edits, or borrow flows.
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

  // Marketplace listing feature: creates a listing after validating auth, residency, fields, and image files.
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

    final validationError = ItemListingFormValidator.validateListing(
      title: title,
      description: description,
      category: category,
      condition: condition,
      imageCount: imagePaths.length,
      hasUsageFee: hasUsageFee,
      hasDeposit: hasDeposit,
      feeAmount: feeAmount,
      depositAmount: depositAmount,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }
    _validateImagePaths(imagePaths);

    final docRef = _firestore.collection(AppConstants.itemsCollection).doc();
    List<Reference> uploadedRefs = const [];
    try {
      final upload = await _uploadItemImages(
        uid: uid,
        itemId: docRef.id,
        filePaths: imagePaths,
      );
      uploadedRefs = upload.refs;

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
        'imageUrls': upload.urls,
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
      await _deleteUploadedImages(uploadedRefs);
      if (e is Exception) rethrow;
      throw Exception('Failed to publish item. Please try again.');
    }
  }

  // Marketplace listing feature: updates a lender-owned item and appends newly uploaded images if provided.
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

    final existing = ItemModel.fromMap(snap.id, data);
    final newPaths = newImagePaths ?? const <String>[];
    final validationError = ItemListingFormValidator.validateListing(
      title: title,
      description: description,
      category: category,
      condition: condition,
      imageCount: existing.imageUrls.length + newPaths.length,
      hasUsageFee: hasUsageFee,
      hasDeposit: hasDeposit,
      feeAmount: feeAmount,
      depositAmount: depositAmount,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }
    if (newPaths.isNotEmpty) {
      _validateImagePaths(newPaths);
    }

    List<Reference> uploadedRefs = const [];
    try {
      var imageUrls = existing.imageUrls;
      if (newPaths.isNotEmpty) {
        final upload = await _uploadItemImages(
          uid: uid,
          itemId: itemId,
          filePaths: newPaths,
        );
        uploadedRefs = upload.refs;
        imageUrls = <String>[...existing.imageUrls, ...upload.urls];
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
      await _deleteUploadedImages(uploadedRefs);
      if (e is Exception) rethrow;
      throw Exception('Failed to update item.');
    }
  }

  // Marketplace listing feature: archives a lender-owned item so borrowers no longer see it.
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

  // Marketplace listing feature: restores an archived lender-owned item to available status.
  Future<void> unarchiveItem(String itemId) async {
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
      throw Exception('You can only unarchive your own item.');
    }

    try {
      await docRef.update({
        'isArchived': false,
        'status': AppConstants.itemStatusAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unarchive item.');
    }
  }

  // Marketplace listing feature: uploads item images and returns download URLs for listing documents.
  Future<List<String>> uploadItemImages({
    required String uid,
    required String itemId,
    required List<String> filePaths,
  }) async {
    final upload = await _uploadItemImages(
      uid: uid,
      itemId: itemId,
      filePaths: filePaths,
    );
    return upload.urls;
  }

  // Marketplace listing feature: uploads each image to Storage and rolls back partial uploads on failure.
  Future<_ItemImageUploadResult> _uploadItemImages({
    required String uid,
    required String itemId,
    required List<String> filePaths,
  }) async {
    if (filePaths.isEmpty) {
      return const _ItemImageUploadResult(urls: <String>[], refs: <Reference>[]);
    }

    final urls = <String>[];
    final refs = <Reference>[];
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
        await ref.putFile(
          File(filePath),
          SettableMetadata(contentType: _itemImageContentType(fileName)),
        );
        refs.add(ref);
        urls.add(await ref.getDownloadURL());
      } catch (e) {
        await _deleteUploadedImages(refs);
        throw Exception('Failed to upload item images.');
      }
    }
    return _ItemImageUploadResult(urls: urls, refs: refs);
  }

  // Marketplace listing feature: validates selected images exist, use allowed extensions, and fit size limits.
  void _validateImagePaths(List<String> filePaths) {
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Selected photo is no longer available.');
      }

      final lower = filePath.toLowerCase();
      if (!_allowedImageExtensions.any(lower.endsWith)) {
        throw Exception('Only JPG, PNG, WEBP, HEIC, or HEIF photos are supported.');
      }

      final size = file.lengthSync();
      if (size > ItemListingFormValidator.maxImageBytes) {
        throw Exception('Each photo must be 10 MB or smaller.');
      }
    }
  }

  // Marketplace listing feature: best-effort cleanup for Storage images when Firestore saving fails.
  Future<void> _deleteUploadedImages(List<Reference> refs) async {
    for (final ref in refs) {
      try {
        await ref.delete();
      } catch (_) {
        // Best-effort cleanup for orphaned uploads.
      }
    }
  }

  // Marketplace listing feature: maps image extension to Firebase Storage content type.
  static String _itemImageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  // Marketplace listing feature: derives display/payment category from fee and deposit settings.
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

// Marketplace listing feature: carries uploaded image URLs and Storage refs for rollback support.
class _ItemImageUploadResult {
  const _ItemImageUploadResult({required this.urls, required this.refs});

  final List<String> urls;
  final List<Reference> refs;
}
