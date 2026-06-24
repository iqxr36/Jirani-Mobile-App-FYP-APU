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

  Future<void> saveCameraPreference({
    required bool enabled,
    required String status,
  }) {
    return _saveUserFields({
      'cameraEnabled': enabled,
      'cameraPermissionStatus': status,
    });
  }

  Future<void> savePhotosDocumentsPreference({
    required bool enabled,
    required String status,
  }) {
    return _saveUserFields({
      'photosDocumentsEnabled': enabled,
      'photosDocumentsPermissionStatus': status,
    });
  }

  Future<void> saveNotificationPreference({
    required bool enabled,
    required String status,
    String? token,
  }) {
    final data = <String, dynamic>{
      'notificationEnabled': enabled,
      'notificationPermissionStatus': status,
    };
    if (token != null && token.isNotEmpty) {
      data['fcmToken'] = token;
    }
    return _saveUserFields(data);
  }

  Future<void> _saveUserFields(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
