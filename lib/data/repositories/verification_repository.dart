import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';

class VerificationRepository {
  VerificationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
      ..sort((a, b) => submitted(b.data()['submittedAt']).compareTo(submitted(a.data()['submittedAt'])));

    return VerificationRequest.fromMap(sorted.first.data());
  }

  Future<VerificationRequest> submitVerificationRequest({
    required String documentType,
    required String filePath,
    required String communityName,
    required String unitNumber,
    String? notes,
    void Function(double progress)? onUploadProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit verification.');
    }

    final uid = user.uid;
    final userSnap = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    final userData = userSnap.data();
    if (userData == null) {
      throw Exception('User profile not found.');
    }
    final appUser = AppUser.fromMap(userData);

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected file is no longer available.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawName = filePath.split(RegExp(r'[/\\]')).last;
    final safeName = rawName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final fileObjectName = '${timestamp}_$safeName';

    final ref = _storage
        .ref()
        .child(AppConstants.storageVerificationDocumentsPath)
        .child(uid)
        .child(fileObjectName);
    final mime = _guessMimeType(safeName);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: mime),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total > 0) {
        onUploadProgress?.call(snapshot.bytesTransferred / total);
      }
    });

    await uploadTask;
    final documentUrl = await ref.getDownloadURL();

    final docRef = _firestore.collection(AppConstants.verificationRequestsCollection).doc();
    final requestId = docRef.id;

    final request = VerificationRequest(
      id: requestId,
      userId: uid,
      fullName: appUser.fullName,
      email: appUser.email,
      phoneNumber: appUser.phoneNumber,
      documentType: documentType,
      documentUrl: documentUrl,
      communityName: communityName.trim(),
      unitNumber: unitNumber.trim(),
      notes: notes?.trim() ?? '',
      status: AppConstants.verificationSubmitted,
      rejectionReason: null,
      submittedAt: DateTime.now(),
      reviewedAt: null,
      reviewedBy: null,
    );

    await docRef.set({
      ...request.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'verificationStatus': AppConstants.verificationSubmitted,
      'communityName': communityName.trim(),
      'unitNumber': unitNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final saved = await docRef.get();
    final data = saved.data();
    if (data == null) {
      return request;
    }
    return VerificationRequest.fromMap(data);
  }

  static String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }
}
