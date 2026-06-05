import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, PhoneAuthCredential, User;
import 'package:flutter/foundation.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/data/models/admin_user.dart';
import 'package:jirani/data/models/app_user.dart';
import 'package:jirani/data/repositories/auth_repository.dart';
import 'package:jirani/data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository, UserRepository? userRepository})
    : _repository = repository ?? AuthRepository(),
      _userRepository = userRepository ?? UserRepository() {
    _authSubscription = _repository.authStateChanges.listen(
      _onAuthStateChanged,
    );
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
  AdminUser? _currentAdmin;
  bool _showEmailVerificationAfterRegister = false;
  bool _showAccountCreatedScreen = false;
  bool _showPhoneVerificationAfterRegister = false;

  User? get firebaseUser => _firebaseUser;
  bool get isAuthBootstrapComplete => _authBootstrapComplete;
  bool get isProfileLoading => _profileLoading;
  bool get isLoading => _isLoading;
  bool get isEmailVerificationSending => _isEmailVerificationSending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get profileErrorMessage => _profileErrorMessage;
  AppUser? get currentUser => _currentUser;
  AdminUser? get currentAdmin => _currentAdmin;
  bool get showEmailVerificationAfterRegister =>
      _showEmailVerificationAfterRegister;
  bool get showAccountCreatedScreen => _showAccountCreatedScreen;
  bool get showPhoneVerificationAfterRegister =>
      _showPhoneVerificationAfterRegister;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool termsAccepted,
    String communityId = '',
    String communityName = '',
  }) async {
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      _currentUser = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        termsAccepted: termsAccepted,
        communityId: communityId,
        communityName: communityName,
      );
      _firebaseUser = _repository.currentFirebaseUser;
      _currentAdmin = null;
      _showEmailVerificationAfterRegister = true;
      _showPhoneVerificationAfterRegister = false;
      _showAccountCreatedScreen = false;
      _successMessage =
          'Account created. A verification email has been sent to your email address.';
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    debugPrint('[AuthProvider.login] started');
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      debugPrint('[AuthProvider.login] Firebase/Repository sign-in started');
      await _repository.login(email: email, password: password);
      await _loadCurrentProfiles();
      if (_currentUser == null && _currentAdmin == null) {
        throw Exception(_missingProfileMessage());
      }
      debugPrint(
        '[AuthProvider.login] Repository login success, userUid=${_currentUser?.uid} adminUid=${_currentAdmin?.uid}',
      );
      _firebaseUser = _repository.currentFirebaseUser;
      debugPrint(
        '[AuthProvider.login] firebase user uid=${_firebaseUser?.uid}',
      );
      debugPrint(
        '[AuthProvider.login] loaded userRole=${_currentUser?.role} adminRole=${_currentAdmin?.role}',
      );
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
      _currentAdmin = null;
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
      _currentAdmin = null;
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
      _currentAdmin = null;
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

  /// After email verification succeeds, continue to the phone verification step.
  void exitEmailVerificationRegistrationFlow() {
    _showEmailVerificationAfterRegister = false;
    _showPhoneVerificationAfterRegister = true;
    _showAccountCreatedScreen = false;
    notifyListeners();
  }

  /// Lets new residents postpone email verification and continue onboarding.
  void skipEmailVerificationRegistrationFlow() {
    exitEmailVerificationRegistrationFlow();
  }

  /// After OTP step (success, back, or skip), show [AccountCreatedView].
  void exitPhoneVerificationRegistrationFlow() {
    _showEmailVerificationAfterRegister = false;
    _showPhoneVerificationAfterRegister = false;
    _showAccountCreatedScreen = true;
    notifyListeners();
  }

  /// Returns `null` on success, or an error message string.
  Future<String?> tryLinkPhoneWithSmsCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      await _repository.linkRegisteredUserWithPhoneSms(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      await refreshCurrentUser();
      return null;
    } catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<String?> tryLinkPhoneWithCredential({
    required PhoneAuthCredential credential,
    required String phoneNumber,
  }) async {
    try {
      await _repository.linkRegisteredUserWithPhoneCredential(
        credential: credential,
        phoneNumber: phoneNumber,
      );
      await refreshCurrentUser();
      return null;
    } catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_firebaseUser == null) return;
    try {
      await _loadCurrentProfiles();
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
    required String firstName,
    required String lastName,
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
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final fields = <String, dynamic>{
        'firstName': trimmedFirstName,
        'lastName': trimmedLastName,
        'fullName': '$trimmedFirstName $trimmedLastName'.trim(),
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

  Future<void> updateSelectedCommunity({
    required String communityId,
    required String communityName,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to select a community.');
    }

    await _userRepository.updateUserFields(
      uid: uid,
      fields: {
        'communityId': communityId.trim(),
        'communityName': communityName.trim(),
      },
    );
    _currentUser = _currentUser?.copyWith(
      communityId: communityId.trim(),
      communityName: communityName.trim(),
    );
    notifyListeners();
  }

  Future<void> markLocationVerified() async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to verify your location.');
    }

    await _userRepository.updateUserFields(
      uid: uid,
      fields: {
        'locationVerified': true,
        'locationVerificationStatus': 'passed',
        'locationVerifiedCommunityName':
            _currentUser?.communityName.trim() ?? '',
      },
    );
    _currentUser = _currentUser?.copyWith(locationVerified: true);
    _showAccountCreatedScreen = false;
    notifyListeners();
  }

  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  void clearSuccessMessage({bool notify = true}) {
    _successMessage = null;
    if (notify) notifyListeners();
  }

  bool _needsLocationVerificationPrompt(AppUser? user) {
    if (user == null || !user.isResident) return false;
    return !user.locationVerified;
  }

  Future<void> _onAuthStateChanged(User? user) async {
    debugPrint('[AuthProvider._onAuthStateChanged] user=${user?.uid}');
    _firebaseUser = user;

    if (user == null) {
      _currentUser = null;
      _currentAdmin = null;
      _profileLoading = false;
      _profileErrorMessage = null;
      _showEmailVerificationAfterRegister = false;
      _showAccountCreatedScreen = false;
      _showPhoneVerificationAfterRegister = false;
      _authBootstrapComplete = true;
      notifyListeners();
      return;
    }

    _profileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      debugPrint(
        '[AuthProvider._onAuthStateChanged] Firestore profile fetch started',
      );
      await _loadCurrentProfiles();
      debugPrint(
        '[AuthProvider._onAuthStateChanged] Firestore profile fetch done userRole=${_currentUser?.role} adminRole=${_currentAdmin?.role}',
      );
      _profileErrorMessage = _currentUser == null && _currentAdmin == null
          ? _missingProfileMessage()
          : null;
      _showAccountCreatedScreen =
          _showAccountCreatedScreen &&
          _needsLocationVerificationPrompt(_currentUser);
    } catch (e) {
      debugPrint('[AuthProvider._onAuthStateChanged] error: $e');
      _currentUser = null;
      _currentAdmin = null;
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

  Future<void> _loadCurrentProfiles() async {
    if (kIsWeb) {
      _currentUser = null;
      try {
        _currentAdmin = await _repository.getCurrentAdminUser();
      } catch (adminError) {
        debugPrint(
          '[AuthProvider._loadCurrentProfiles] admin profile lookup failed: $adminError',
        );
        _currentAdmin = null;
        _currentUser = await _repository.getCurrentAppUser();
      }
      return;
    }

    _currentAdmin = null;
    _currentUser = await _repository.getCurrentAppUser();
  }

  String _missingProfileMessage() {
    final uid =
        _firebaseUser?.uid ?? _repository.currentFirebaseUser?.uid ?? '';
    final email =
        _firebaseUser?.email ?? _repository.currentFirebaseUser?.email ?? '';
    final uidText = uid.isEmpty ? 'unknown Firebase Auth UID' : uid;
    final emailText = email.isEmpty ? '' : ' for $email';
    return kIsWeb
        ? 'Admin profile not found in Firestore$emailText. Create admins/$uidText for this admin account.'
        : 'Resident profile not found in Firestore$emailText. Create users/$uidText for this resident account.';
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
