// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : user_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

// User profile data layer: updates shared users/{uid} fields used by auth, admin, and resident profile screens.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // User profile feature: merges selected profile fields and refreshes updatedAt.
  Future<void> updateUserFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
