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
  static const Set<String> _pdfOnlyExtensions = {'pdf'};
  static const Set<String> _imageAndPdfExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'pdf',
  };

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

    final docRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc();
    final requestId = docRef.id;
    final isTenancyAgreement =
        documentType == AppConstants.documentTypeTenancyAgreement;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileObjectName = _safeVerificationStorageObjectName(
      timestamp,
      originalFileName,
      documentType: documentType,
    );

    final ref = isTenancyAgreement
        ? _storage
              .ref()
              .child(AppConstants.storageResidentDocumentsPath)
              .child(uid)
              .child(requestId)
              .child(fileObjectName)
        : _storage
              .ref()
              .child(AppConstants.storageVerificationDocumentsPath)
              .child(uid)
              .child(fileObjectName);
    final mime = _mimeTypeForStorageName(fileObjectName, fileBytes);

    final request = VerificationRequest(
      id: requestId,
      userId: uid,
      fullName: appUser.fullName,
      email: appUser.email,
      phoneNumber: appUser.phoneNumber,
      documentType: documentType,
      documentUrl: '',
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
      ocrStatus: isTenancyAgreement
          ? AppConstants.ocrStatusProcessing
          : AppConstants.ocrStatusPending,
      ocrText: '',
      ocrFields: const {},
      ocrError: null,
      ocrProcessedAt: null,
      storagePath: ref.fullPath,
      adminStatus: isTenancyAgreement
          ? AppConstants.adminStatusProcessing
          : AppConstants.adminStatusPendingReview,
    );

    if (isTenancyAgreement) {
      await docRef
          .set({
            ...request.toMap(),
            'fileName': fileObjectName,
            'filePath': ref.fullPath,
            'residentId': uid,
            'residentEmail': appUser.email,
            'uploadedAt': FieldValue.serverTimestamp(),
            'submittedAt': FieldValue.serverTimestamp(),
            'processedAt': null,
            'extractedFields': const <String, dynamic>{},
          })
          .timeout(_networkTimeout);
    }

    final metadata = SettableMetadata(
      contentType: mime,
      customMetadata: {
        'documentId': requestId,
        'residentId': uid,
        'documentType': isTenancyAgreement ? 'tenancy_agreement' : documentType,
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

    if (isTenancyAgreement) {
      await docRef
          .update({
            'documentUrl': documentUrl,
            'fileUrl': documentUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_networkTimeout);
    } else {
      await docRef
          .set({
            ...request.copyWith(documentUrl: documentUrl).toMap(),
            'submittedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_networkTimeout);
    }

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
    String originalFileName, {
    required String documentType,
  }) {
    final tenancyAgreement =
        documentType == AppConstants.documentTypeTenancyAgreement;
    final baseName = path.basename(originalFileName);
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

    final allowed = _allowedExtensionsForDocumentType(documentType);
    if (!allowed.contains(ext)) {
      throw VerificationUnsupportedFileTypeException(
        _unsupportedFileTypeMessage(documentType),
      );
    }

    if (ext == 'jpeg') ext = 'jpg';

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

  static Set<String> _allowedExtensionsForDocumentType(String documentType) {
    return switch (documentType) {
      AppConstants.documentTypeTenancyAgreement ||
      AppConstants.documentTypeUtilityBill => _pdfOnlyExtensions,
      AppConstants.documentTypeAccessCard ||
      AppConstants.documentTypeOtherProof => _imageAndPdfExtensions,
      _ => _imageAndPdfExtensions,
    };
  }

  static String _unsupportedFileTypeMessage(String documentType) {
    return switch (documentType) {
      AppConstants.documentTypeTenancyAgreement =>
        'Only PDF tenancy agreements are supported.',
      AppConstants.documentTypeUtilityBill =>
        'Only PDF utility bills are supported.',
      AppConstants.documentTypeAccessCard =>
        'Only JPG, PNG, WEBP, HEIC, or PDF access cards are supported.',
      AppConstants.documentTypeOtherProof =>
        'Only JPG, PNG, WEBP, HEIC, or PDF other proof documents are supported.',
      _ => 'Only JPG, PNG, WEBP, HEIC, or PDF files are supported.',
    };
  }

  /// MIME for Firebase Storage metadata (jpg + jpeg both -> image/jpeg).
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
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
