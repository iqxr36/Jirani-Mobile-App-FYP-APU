part of '../auth_viewmodel.dart';

/// Auth state base: stores shared session/profile state used by all AuthViewModel feature mixins.
abstract class _AuthViewModelBase extends ChangeNotifier {
  _AuthViewModelBase({
    AuthRepository? repository,
    UserRepository? userRepository,
    ConnectionRepository? connectionRepository,
    VerificationRepository? verificationRepository,
    ChatRepository? chatRepository,
    bool listenToAuthChanges = true,
    AppUser? initialCurrentUser,
  }) : _repository = repository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _connectionRepository = connectionRepository ?? ConnectionRepository(),
       _verificationRepository =
           verificationRepository ?? VerificationRepository(),
       _chatRepository = chatRepository ?? ChatRepository() {
    _currentUser = initialCurrentUser;
    if (listenToAuthChanges) {
      _authSubscription = _repository.authStateChanges.listen(
        _onAuthStateChanged,
      );
    } else {
      _authBootstrapComplete = true;
    }
  }

  final AuthRepository _repository;
  final UserRepository _userRepository;
  final ConnectionRepository _connectionRepository;
  final VerificationRepository _verificationRepository;
  final ChatRepository _chatRepository;
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

  /// Auth/profile feature: reloads resident/admin Firestore profiles while preserving the last good profile on failure.
  Future<void> refreshCurrentUser() async {
    if (_firebaseUser == null) return;

    final previousUser = _currentUser;
    final previousAdmin = _currentAdmin;

    try {
      await _loadCurrentProfiles();
      if (_currentUser == null && _currentAdmin == null) {
        _currentUser = previousUser;
        _currentAdmin = previousAdmin;
        _profileErrorMessage ??= _missingProfileMessage();
      } else {
        _profileErrorMessage = null;
      }
      notifyListeners();
    } catch (e) {
      _currentUser = previousUser;
      _currentAdmin = previousAdmin;
      _profileErrorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Auth UI: clears the current user-facing auth error.
  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  /// Auth validation: stores form validation errors before hitting Firebase.
  void _setValidationError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Auth UI: clears success messages such as email verification sent.
  void clearSuccessMessage({bool notify = true}) {
    _successMessage = null;
    if (notify) notifyListeners();
  }

  /// Geofence onboarding: determines whether a resident should see location verification after account creation.
  bool _needsLocationVerificationPrompt(AppUser? user) {
    if (user == null || !user.isResident) return false;
    return !user.locationVerified;
  }

  /// Auth bootstrap: reacts to Firebase session changes and loads the matching resident or admin profile.
  Future<void> _onAuthStateChanged(User? user) async {
    authDebugLog(
      '[AuthProvider._onAuthStateChanged] session=${user != null}',
    );
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
      authDebugLog(
        '[AuthProvider._onAuthStateChanged] Firestore profile fetch started',
      );
      await _loadCurrentProfiles();
      authDebugLog(
        '[AuthProvider._onAuthStateChanged] Firestore profile fetch done userRole=${_currentUser?.role} adminRole=${_currentAdmin?.role}',
      );
      _profileErrorMessage = _currentUser == null && _currentAdmin == null
          ? _missingProfileMessage()
          : null;
      _showAccountCreatedScreen =
          _showAccountCreatedScreen &&
          _needsLocationVerificationPrompt(_currentUser);
    } catch (e) {
      authDebugLogError('[AuthProvider._onAuthStateChanged]', e);
      _currentUser = null;
      _currentAdmin = null;
      _profileErrorMessage = e.toString();
    } finally {
      _profileLoading = false;
      _authBootstrapComplete = true;
      notifyListeners();
    }
  }

  /// Auth UI: toggles loading state and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Auth/profile feature: loads admin profile on web and resident profile on mobile.
  Future<void> _loadCurrentProfiles() async {
    if (kIsWeb) {
      _currentUser = null;
      try {
        _currentAdmin = await _repository.getCurrentAdminUser();
      } catch (adminError) {
        authDebugLogError(
          '[AuthProvider._loadCurrentProfiles] admin profile lookup',
          adminError,
        );
        _currentAdmin = null;
        _currentUser = await _repository.getCurrentAppUser();
      }
      return;
    }

    _currentAdmin = null;
    _currentUser = await _repository.getCurrentAppUser();
  }

  /// Auth diagnostics: builds a helpful missing-profile message with the Firebase UID to create in Firestore.
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

  /// Auth UX: converts Firebase/social sign-in exceptions into readable messages.
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
        case 'email-already-in-use':
          return 'This email is already used by another account.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'requires-recent-login':
          return 'For security, please log out and log in again before changing your email.';
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
