import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuthService? authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? FirebaseAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<AppUser?> getCurrentAppUser() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return null;

    return AppUser.fromMap(data);
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to create user account.');
    }

    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    await userDoc.set({
      'uid': firebaseUser.uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'role': AppConstants.roleResident,
      'verificationStatus': AppConstants.verificationPending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final createdDoc = await userDoc.get();
    final data = createdDoc.data();
    if (data == null) {
      final now = DateTime.now();
      return AppUser(
        uid: firebaseUser.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: AppConstants.roleResident,
        verificationStatus: AppConstants.verificationPending,
        createdAt: now,
        updatedAt: now,
      );
    }

    return AppUser.fromMap(data);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to login user.');
    }

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    final data = doc.data();
    if (data == null) {
      throw Exception('User profile not found in Firestore.');
    }

    return AppUser.fromMap(data);
  }

  Future<void> logout() {
    return _authService.signOut();
  }
}
