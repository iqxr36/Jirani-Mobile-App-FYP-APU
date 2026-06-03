import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/data/models/app_user.dart';
import 'package:jirani/data/models/verification_request.dart';

import 'verification_upload_platform_stub.dart'
    if (dart.library.io) 'verification_upload_platform_io.dart';

/// Thrown when the picked filename does not resolve to an allowed extension.
class VerificationUnsupportedFileTypeException implements Exception {
  VerificationUnsupportedFileTypeException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VerificationRepository {
  VerificationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const Duration _uploadTimeout = Duration(seconds: 90);
  static const Duration _networkTimeout = Duration(seconds: 25);

  User? get currentFirebaseUser => _auth.currentUser;

  Future<VerificationRequest?> getCurrentUserLatestRequest() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isEmpty) return null;

    DateTime submitted(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final sorted = snapshot.docs.toList()
      ..sort(
        (a, b) => submitted(
          b.data()['submittedAt'],
        ).compareTo(submitted(a.data()['submittedAt'])),
      );

    return VerificationRequest.fromMap(sorted.first.data());
  }

  /// Marks the user's latest cancellable request as cancelled and resets user verification to pending.
  Future<void> cancelLatestVerificationRequest() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }
    final uid = user.uid;

    final latest = await getCurrentUserLatestRequest();
    if (latest == null) {
      throw Exception('No verification request found.');
    }

    final st = latest.status;
    if (st != AppConstants.verificationSubmitted &&
        st != AppConstants.verificationRequestPending) {
      throw Exception('Only a pending or submitted request can be cancelled.');
    }

    await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(latest.id)
        .update({
          'status': AppConstants.verificationRequestCancelled,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': uid,
        });

    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'verificationStatus': AppConstants.verificationPending,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Uploads using [putData] on web; on IO, [localFilePath] allows [putFile] when the path is valid.
  Future<VerificationRequest> submitVerificationRequest({
    required String documentType,
    required Uint8List fileBytes,
    required String originalFileName,
    String? localFilePath,
    required String communityName,
    required String unitNumber,
    String? notes,
    void Function(double progress)? onUploadProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit verification.');
    }

    if (fileBytes.isEmpty) {
      throw Exception('The selected file is empty.');
    }

    final uid = user.uid;
    final userSnap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get()
        .timeout(_networkTimeout);
    final userData = userSnap.data();
    if (userData == null) {
      throw Exception('User profile not found.');
    }
    final appUser = AppUser.fromMap(userData);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileObjectName = _safeVerificationStorageObjectName(
      timestamp,
      originalFileName,
    );

    final ref = _storage
        .ref()
        .child(AppConstants.storageVerificationDocumentsPath)
        .child(uid)
        .child(fileObjectName);
    final mime = _mimeTypeForStorageName(fileObjectName);

    final metadata = SettableMetadata(contentType: mime);

    final uploadTask = putVerificationObject(
      ref,
      fileBytes,
      localFilePath,
      metadata,
    );

    final progressSub = uploadTask.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total > 0) {
        onUploadProgress?.call(snapshot.bytesTransferred / total);
      }
    });

    try {
      await uploadTask.timeout(
        _uploadTimeout,
        onTimeout: () async {
          await uploadTask.cancel();
          throw TimeoutException(
            'Document upload timed out. Please check your connection and try again.',
          );
        },
      );
    } finally {
      await progressSub.cancel();
    }
    final documentUrl = await ref.getDownloadURL().timeout(_networkTimeout);

    final docRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc();
    final requestId = docRef.id;

    final request = VerificationRequest(
      id: requestId,
      userId: uid,
      fullName: appUser.fullName,
      email: appUser.email,
      phoneNumber: appUser.phoneNumber,
      documentType: documentType,
      documentUrl: documentUrl,
      communityId: appUser.communityId,
      communityName: communityName.trim(),
      unitNumber: unitNumber.trim(),
      notes: notes?.trim() ?? '',
      status: AppConstants.verificationSubmitted,
      rejectionReason: null,
      submittedAt: DateTime.now(),
      reviewedAt: null,
      reviewedBy: null,
      cancelledAt: null,
      cancelledBy: null,
    );

    await docRef
        .set({...request.toMap(), 'submittedAt': FieldValue.serverTimestamp()})
        .timeout(_networkTimeout);

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
          'verificationStatus': AppConstants.verificationSubmitted,
          'communityId': appUser.communityId,
          'communityName': communityName.trim(),
          'unitNumber': unitNumber.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_networkTimeout);

    final saved = await docRef.get().timeout(_networkTimeout);
    final data = saved.data();
    if (data == null) {
      return request;
    }
    return VerificationRequest.fromMap(data);
  }

  /// `{timestamp}_verification_document.{ext}` - ext from [originalFileName] only, sanitized.
  static String _safeVerificationStorageObjectName(
    int timestamp,
    String originalFileName,
  ) {
    final baseName = originalFileName.split(RegExp(r'[/\\]')).last;
    final dot = baseName.lastIndexOf('.');
    var ext = '';
    if (dot != -1 && dot < baseName.length - 1) {
      ext = baseName
          .substring(dot + 1)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    if (ext.isEmpty) {
      throw VerificationUnsupportedFileTypeException(
        'Could not determine file type. Use JPG, PNG, WEBP, HEIC, or PDF.',
      );
    }

    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'};
    if (!allowed.contains(ext)) {
      throw VerificationUnsupportedFileTypeException(
        'Only JPG, PNG, WEBP, HEIC, or PDF files are supported.',
      );
    }

    if (ext == 'jpeg') ext = 'jpg';

    return '${timestamp}_verification_document.$ext';
  }

  /// MIME for Firebase Storage metadata (jpg + jpeg both -> image/jpeg).
  static String _mimeTypeForStorageName(String safeFileName) {
    final lower = safeFileName.toLowerCase();
    if (lower.endsWith('.jpg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
