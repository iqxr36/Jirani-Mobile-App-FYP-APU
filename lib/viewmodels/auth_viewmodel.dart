import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException, User;
import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
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
  bool _isEmailVerificationSending = false;
  String? _errorMessage;
  String? _successMessage;
  String? _profileErrorMessage;
  AppUser? _currentUser;
  bool _showAccountCreatedScreen = false;

  User? get firebaseUser => _firebaseUser;
  bool get isAuthBootstrapComplete => _authBootstrapComplete;
  bool get isProfileLoading => _profileLoading;
  bool get isLoading => _isLoading;
  bool get isEmailVerificationSending => _isEmailVerificationSending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
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
    _successMessage = null;
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
      _successMessage = 'Account created. A verification email has been sent to your email address.';
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
    debugPrint('[AuthProvider.login] started');
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      debugPrint('[AuthProvider.login] Firebase/Repository sign-in started');
      _currentUser = await _repository.login(
        email: email,
        password: password,
      );
      debugPrint('[AuthProvider.login] Repository login success, uid=${_currentUser?.uid}');
      _firebaseUser = _repository.currentFirebaseUser;
      debugPrint('[AuthProvider.login] firebase user uid=${_firebaseUser?.uid}');
      debugPrint('[AuthProvider.login] loaded role=${_currentUser?.role}');
      _showAccountCreatedScreen = false;
    } catch (e) {
      debugPrint('[AuthProvider.login] error: $e');
      _errorMessage = _mapAuthError(e);
    } finally {
      debugPrint('[AuthProvider.login] isLoading set false');
      _setLoading(false);
    }
  }

  /// Returns without error if the user cancelled the Google account picker.
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      final user = await _repository.signInWithGoogle();
      if (user == null) {
        return;
      }
      _currentUser = user;
      _firebaseUser = _repository.currentFirebaseUser;
      _showAccountCreatedScreen = false;
    } catch (e) {
      debugPrint('[AuthProvider.signInWithGoogle] error: $e');
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Returns without error if the user cancelled Apple sign-in.
  Future<void> signInWithApple() async {
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      final user = await _repository.signInWithApple();
      if (user == null) {
        return;
      }
      _currentUser = user;
      _firebaseUser = _repository.currentFirebaseUser;
      _showAccountCreatedScreen = false;
    } catch (e) {
      debugPrint('[AuthProvider.signInWithApple] error: $e');
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
      _successMessage = null;
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
    _successMessage = null;

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

  Future<void> resendEmailVerification() async {
    if (_isEmailVerificationSending) return;
    _isEmailVerificationSending = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.resendEmailVerification();
      _successMessage = 'Verification email sent.';
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _isEmailVerificationSending = false;
      notifyListeners();
    }
  }

  Future<void> refreshEmailVerificationStatus() async {
    await refreshCurrentUser();
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
      final normalizedPhone = Validators.normalizePhoneNumber(phoneNumber);
      final previousPhone = _currentUser?.phoneNumber ?? '';
      final phoneChanged = normalizedPhone != previousPhone;
      final fields = <String, dynamic>{
        'fullName': fullName.trim(),
        'phoneNumber': normalizedPhone,
        'communityName': communityName.trim(),
        'unitNumber': unitNumber.trim(),
      };
      if (phoneChanged) {
        fields['phoneVerified'] = false;
      }
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

  void clearSuccessMessage({bool notify = true}) {
    _successMessage = null;
    if (notify) notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    debugPrint('[AuthProvider._onAuthStateChanged] user=${user?.uid}');
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
      debugPrint('[AuthProvider._onAuthStateChanged] Firestore profile fetch started');
      _currentUser = await _repository.getCurrentAppUser();
      debugPrint('[AuthProvider._onAuthStateChanged] Firestore profile fetch done role=${_currentUser?.role}');
      _profileErrorMessage = _currentUser == null ? 'User profile not found in Firestore.' : null;
    } catch (e) {
      debugPrint('[AuthProvider._onAuthStateChanged] error: $e');
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
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'This email is already linked to another sign-in method.';
        case 'network-request-failed':
          return 'Network error. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'invalid-credential':
          return 'Sign-in failed. Please try again.';
        case 'user-not-found':
        case 'wrong-password':
          return e.message ?? 'Sign-in failed.';
      }
      return e.message ?? e.code;
    }
    final raw = e.toString().replaceFirst('Exception: ', '').trim();
    if (raw.contains('Apple sign-in is not available')) {
      return 'Apple sign-in is not available on this device.';
    }
    if (raw.contains('Network error')) {
      return raw;
    }
    return raw;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
