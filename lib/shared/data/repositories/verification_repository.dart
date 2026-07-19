// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'verification_upload_platform_stub.dart'
    if (dart.library.io) 'verification_upload_platform_io.dart';

// Residency verification feature: thrown when the picked filename does not resolve to an allowed extension.
class VerificationUnsupportedFileTypeException implements Exception {
  VerificationUnsupportedFileTypeException(this.message);
  final String message;

  @override
  String toString() => message;
}

// Residency verification data layer: uploads proof documents and creates verificationRequests for admin review.
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
  static const Set<String> _verificationDocumentExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'pdf',
  };

  User? get currentFirebaseUser => _auth.currentUser;

  static Set<String> get supportedVerificationDocumentExtensions =>
      Set.unmodifiable(_verificationDocumentExtensions);

  // Residency verification feature: checks whether a selected proof filename has an allowed extension.
  static bool isSupportedVerificationFileName(String originalFileName) {
    final extension = _normalizedExtension(originalFileName);
    return extension != null &&
        _verificationDocumentExtensions.contains(extension);
  }

  // Residency verification feature: fetches the latest request for the signed-in resident.
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

    final latest = sorted.first;
    return VerificationRequest.fromMap({...latest.data(), 'id': latest.id});
  }

  // Residency verification feature: cancels the latest pending/submitted request; Cloud Functions resets user status.
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
    // User verification status is reset server-side by Cloud Functions.
  }

  // Residency verification feature: cancels an active request when the resident changes community.
  Future<void> cancelActiveVerificationRequestIfAny() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final latest = await getCurrentUserLatestRequest();
    if (latest == null) return;

    final status = latest.status;
    if (status != AppConstants.verificationSubmitted &&
        status != AppConstants.verificationRequestPending) {
      return;
    }

    await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(latest.id)
        .update({
          'status': AppConstants.verificationRequestCancelled,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': user.uid,
        });
  }

  // Residency verification feature: uploads the proof file and creates the admin-review request document.
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

    final docRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc();
    final requestId = docRef.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileObjectName = _safeVerificationStorageObjectName(
      timestamp,
      originalFileName,
      documentType: documentType,
    );

    final ref = _storage
        .ref()
        .child(AppConstants.storageResidentDocumentsPath)
        .child(uid)
        .child(requestId)
        .child(fileObjectName);
    final mime = _mimeTypeForStorageName(fileObjectName, fileBytes);
    final storageBucket = ref.bucket;

    final metadata = SettableMetadata(
      contentType: mime,
      customMetadata: {
        'documentId': requestId,
        'residentId': uid,
        'documentType': _storageMetadataDocumentType(documentType),
        'storageBucket': storageBucket,
      },
    );

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
    } catch (_) {
      rethrow;
    } finally {
      await progressSub.cancel();
    }
    final documentUrl = await ref.getDownloadURL().timeout(_networkTimeout);

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
      ocrStatus: AppConstants.ocrStatusPending,
      ocrText: '',
      ocrFields: const {},
      ocrError: null,
      ocrProcessedAt: null,
      storagePath: ref.fullPath,
      adminStatus: AppConstants.adminStatusProcessing,
    );

    try {
      await docRef
          .set({
            ...request.toMap(),
            'fileName': fileObjectName,
            'filePath': ref.fullPath,
            'fileUrl': documentUrl,
            'storageBucket': storageBucket,
            'residentId': uid,
            'residentEmail': appUser.email,
            'createdAt': FieldValue.serverTimestamp(),
            'uploadedAt': FieldValue.serverTimestamp(),
            'submittedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'processedAt': null,
            'extractedFields': const <String, dynamic>{},
          })
          .timeout(_networkTimeout);
    } catch (_) {
      await _deleteUploadedVerificationObject(ref);
      rethrow;
    }

    final saved = await docRef.get().timeout(_networkTimeout);
    final data = saved.data();
    if (data == null) {
      return request;
    }
    return VerificationRequest.fromMap({...data, 'id': saved.id});
  }

  // Residency verification feature: removes uploaded Storage proof if Firestore request creation fails.
  static Future<void> _deleteUploadedVerificationObject(
    Reference ref,
  ) async {
    try {
      await ref.delete().timeout(_networkTimeout);
    } catch (_) {
      // Best effort cleanup only. The original Firestore error should surface.
    }
  }

  // Residency verification feature: creates a safe Storage object name from the original uploaded filename.
  static String _safeVerificationStorageObjectName(
    int timestamp,
    String originalFileName, {
    required String documentType,
  }) {
    final tenancyAgreement =
        documentType == AppConstants.documentTypeTenancyAgreement;
    final baseName = path.basename(originalFileName);
    final dot = baseName.lastIndexOf('.');
    final normalizedExtension = _normalizedExtension(baseName);
    if (normalizedExtension == null) {
      throw VerificationUnsupportedFileTypeException(
        'Could not determine file type. Use JPG, PNG, WEBP, HEIC, HEIF, or PDF.',
      );
    }

    final allowed = _allowedExtensionsForDocumentType();
    if (!allowed.contains(normalizedExtension)) {
      throw VerificationUnsupportedFileTypeException(
        _unsupportedFileTypeMessage(),
      );
    }

    final ext = normalizedExtension == 'jpeg' ? 'jpg' : normalizedExtension;

    if (!tenancyAgreement) {
      return '${timestamp}_verification_document.$ext';
    }

    final stem = dot == -1 ? baseName : baseName.substring(0, dot);
    final safeStem = stem
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${safeStem.isEmpty ? 'tenancy_agreement' : safeStem}.$ext';
  }

  // Residency verification feature: extracts and sanitizes the selected document file extension.
  static String? _normalizedExtension(String fileName) {
    final baseName = path.basename(fileName);
    final dot = baseName.lastIndexOf('.');
    if (dot == -1 || dot >= baseName.length - 1) return null;
    final ext = baseName
        .substring(dot + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return ext.isEmpty ? null : ext;
  }

  // Residency verification feature: returns the accepted proof document extensions.
  static Set<String> _allowedExtensionsForDocumentType() {
    return _verificationDocumentExtensions;
  }

  // Residency verification feature: keeps the unsupported-file message consistent across upload validation.
  static String _unsupportedFileTypeMessage() {
    return 'Only JPG, PNG, WEBP, HEIC, HEIF, or PDF files are supported.';
  }

  // Residency verification feature: normalizes document type for Firebase Storage metadata and OCR functions.
  static String _storageMetadataDocumentType(String documentType) {
    return switch (documentType) {
      AppConstants.documentTypeTenancyAgreement => 'tenancy_agreement',
      AppConstants.documentTypeUtilityBill => 'utility_bill',
      _ => documentType,
    };
  }

  // Residency verification feature: detects MIME type for Firebase Storage metadata.
  static String _mimeTypeForStorageName(
    String safeFileName,
    Uint8List fileBytes,
  ) {
    final detected = lookupMimeType(safeFileName, headerBytes: fileBytes);
    if (detected != null) return detected;
    final lower = safeFileName.toLowerCase();
    if (lower.endsWith('.jpg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
