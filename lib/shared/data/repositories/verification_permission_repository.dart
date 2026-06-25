import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';

class VerificationPermissionRepository {
  VerificationPermissionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> saveNotificationPreference({
    required bool enabled,
    required String status,
    String? token,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Missing signed-in user.');
    }
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'notificationEnabled': enabled,
      'notificationPermissionStatus': status,
      if (token != null && token.isNotEmpty) 'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationEnabled({
    required bool enabled,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Missing signed-in user.');
    }
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'notificationEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token.trim().isEmpty) return;
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'fcmToken': token.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveCameraPreference({
    required bool enabled,
    required String status,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Missing signed-in user.');
    }
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'cameraEnabled': enabled,
      'cameraPermissionStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePhotosDocumentsPreference({
    required bool enabled,
    required String status,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Missing signed-in user.');
    }
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'photosDocumentsEnabled': enabled,
      'photosDocumentsPermissionStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
