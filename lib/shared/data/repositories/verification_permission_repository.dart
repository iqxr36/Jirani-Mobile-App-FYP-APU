// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_permission_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';

// Residency verification permissions feature: stores device permission choices and FCM token on users/{uid}.
class VerificationPermissionRepository {
  VerificationPermissionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Notification permission feature: saves notification permission status and optional FCM token.
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

  // Notification permission feature: toggles notification preference after onboarding.
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

  // Neighbor activity notification feature: toggles updates from connected neighbors.
  Future<void> updateNeighborUpdatesEnabled({
    required bool enabled,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Missing signed-in user.');
    }
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      AppConstants.userNeighborUpdatesEnabledField: enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Notification permission feature: stores the latest FCM token for push notification delivery.
  Future<void> saveFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token.trim().isEmpty) return;
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'fcmToken': token.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Verification permission feature: stores camera permission state needed for document capture.
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

  // Verification permission feature: stores photo/document picker permission state for uploads.
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
