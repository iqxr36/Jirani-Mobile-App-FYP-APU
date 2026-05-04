import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException, User;
import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/data/repositories/auth_repository.dart';
import 'package:fyp_flutter_application/data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    AuthRepository? repository,
    UserRepository? userRepository,
  })  : _repository = repository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository() {
    _authSubscription = _repository.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _repository;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  bool _authBootstrapComplete = false;
  bool _profileLoading = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _profileErrorMessage;
  AppUser? _currentUser;
  bool _showAccountCreatedScreen = false;

  User? get firebaseUser => _firebaseUser;
  bool get isAuthBootstrapComplete => _authBootstrapComplete;
  bool get isProfileLoading => _profileLoading;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get profileErrorMessage => _profileErrorMessage;
  AppUser? get currentUser => _currentUser;
  bool get showAccountCreatedScreen => _showAccountCreatedScreen;

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool termsAccepted,
  }) async {
    _setLoading(true);
    clearError(notify: false);
    _profileErrorMessage = null;

    try {
      _currentUser = await _repository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        termsAccepted: termsAccepted,
      );
      _firebaseUser = _repository.currentFirebaseUser;
      _showAccountCreatedScreen = true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError(notify: false);
    _profileErrorMessage = null;

    try {
      _currentUser = await _repository.login(
        email: email,
        password: password,
      );
      _firebaseUser = _repository.currentFirebaseUser;
      _showAccountCreatedScreen = false;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    clearError(notify: false);

    try {
      await _repository.logout();
      _currentUser = null;
      _firebaseUser = null;
      _showAccountCreatedScreen = false;
      _profileErrorMessage = null;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    clearError(notify: false);

    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  void dismissAccountCreatedScreen() {
    _showAccountCreatedScreen = false;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_firebaseUser == null) return;
    try {
      _currentUser = await _repository.getCurrentAppUser();
      _profileErrorMessage = null;
      notifyListeners();
    } catch (e) {
      _profileErrorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required String fullName,
    required String phoneNumber,
    required String communityName,
    required String unitNumber,
    String? profileImageUrl,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) return;

    _setLoading(true);
    clearError(notify: false);

    try {
      final fields = <String, dynamic>{
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'communityName': communityName.trim(),
        'unitNumber': unitNumber.trim(),
      };
      if (profileImageUrl != null) {
        fields['profileImageUrl'] = profileImageUrl.trim();
      }

      await _userRepository.updateUserFields(uid: uid, fields: fields);
      await refreshCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _currentUser = null;
      _profileLoading = false;
      _profileErrorMessage = null;
      _showAccountCreatedScreen = false;
      _authBootstrapComplete = true;
      notifyListeners();
      return;
    }

    _profileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.getCurrentAppUser();
      _profileErrorMessage = _currentUser == null ? 'User profile not found in Firestore.' : null;
    } catch (e) {
      _currentUser = null;
      _profileErrorMessage = e.toString();
    } finally {
      _profileLoading = false;
      _authBootstrapComplete = true;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(Object e) {
    if (e is FirebaseAuthException) {
      return e.message ?? e.code;
    }
    return e.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
