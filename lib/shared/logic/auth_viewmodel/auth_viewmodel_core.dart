part of '../auth_viewmodel.dart';

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

  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  void _setValidationError(String message) {
    _errorMessage = message;
    notifyListeners();
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
