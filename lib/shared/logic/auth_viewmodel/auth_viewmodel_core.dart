// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_viewmodel_core.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

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
    AdminUser? initialCurrentAdmin,
    bool? surfaceAdminProfileImageHydrationErrors,
  }) : _repository = repository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _connectionRepository = connectionRepository ?? ConnectionRepository(),
       _verificationRepository =
           verificationRepository ?? VerificationRepository(),
       _chatRepository = chatRepository ?? ChatRepository(),
       _surfaceAdminProfileImageHydrationErrors =
           surfaceAdminProfileImageHydrationErrors ?? !kIsWeb {
    _currentUser = initialCurrentUser;
    _currentAdmin = initialCurrentAdmin;
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
  final bool _surfaceAdminProfileImageHydrationErrors;
  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  bool _authBootstrapComplete = false;
  bool _profileLoading = false;
  bool _isLoading = false;
  bool _isEmailVerificationSending = false;
  String? _errorMessage;
  String? _successMessage;
  String? _profileErrorMessage;
  String? _adminProfileImageErrorMessage;
  AppUser? _currentUser;
  AdminUser? _currentAdmin;
  Uint8List? _adminProfileImageBytes;
  String _adminProfileImageBytesUrl = '';
  bool _showEmailVerificationAfterRegister = false;
  bool _showAccountCreatedScreen = false;

  User? get firebaseUser => _firebaseUser;
  bool get isAuthBootstrapComplete => _authBootstrapComplete;
  bool get isProfileLoading => _profileLoading;
  bool get isLoading => _isLoading;
  bool get isEmailVerificationSending => _isEmailVerificationSending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get profileErrorMessage => _profileErrorMessage;
  String? get adminProfileImageErrorMessage => _adminProfileImageErrorMessage;
  AppUser? get currentUser => _currentUser;
  AdminUser? get currentAdmin => _currentAdmin;
  Uint8List? get adminProfileImageBytes {
    final url = _currentAdmin?.profileImageUrl.trim() ?? '';
    if (url.isEmpty || url != _adminProfileImageBytesUrl) {
      return null;
    }
    return _adminProfileImageBytes;
  }

  bool get showEmailVerificationAfterRegister =>
      _showEmailVerificationAfterRegister;
  bool get showAccountCreatedScreen => _showAccountCreatedScreen;

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
    authDebugLog('[AuthProvider._onAuthStateChanged] session=${user != null}');
    _firebaseUser = user;

    if (user == null) {
      _currentUser = null;
      _currentAdmin = null;
      _clearAdminProfileImageCache();
      _profileLoading = false;
      _profileErrorMessage = null;
      _adminProfileImageErrorMessage = null;
      _showEmailVerificationAfterRegister = false;
      _showAccountCreatedScreen = false;
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
      final previousImageUrl = _currentAdmin?.profileImageUrl.trim() ?? '';
      try {
        final loaded = await _repository.getCurrentAdminUser(
          preferServer: true,
        );
        _currentAdmin = _mergeAdminProfileImage(
          previousImageUrl: previousImageUrl,
          loaded: loaded,
        );
        if ((_currentAdmin?.profileImageUrl.trim() ?? '').isNotEmpty) {
          await _hydrateAdminProfileImageIfNeeded();
        }
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

  AdminUser? _mergeAdminProfileImage({
    required String previousImageUrl,
    required AdminUser? loaded,
  }) {
    if (loaded == null) return null;
    final loadedUrl = loaded.profileImageUrl.trim();
    if (loadedUrl.isNotEmpty || previousImageUrl.isEmpty) {
      return loaded;
    }
    return loaded.copyWith(profileImageUrl: previousImageUrl);
  }

  void _setAdminProfileImageBytes(Uint8List bytes, String url) {
    _adminProfileImageBytes = bytes;
    _adminProfileImageBytesUrl = url.trim();
  }

  void _clearAdminProfileImageCache() {
    _adminProfileImageBytes = null;
    _adminProfileImageBytesUrl = '';
  }

  Future<bool> _hydrateAdminProfileImageIfNeeded() async {
    final url = _currentAdmin?.profileImageUrl.trim() ?? '';
    if (url.isEmpty) {
      _clearAdminProfileImageCache();
      _adminProfileImageErrorMessage = null;
      return false;
    }
    if (_adminProfileImageBytesUrl == url &&
        _adminProfileImageBytes != null &&
        _adminProfileImageBytes!.isNotEmpty) {
      _adminProfileImageErrorMessage = null;
      return true;
    }

    try {
      final bytes = await _repository.downloadProfileImageBytes(url);
      if (bytes != null && bytes.isNotEmpty) {
        _setAdminProfileImageBytes(bytes, url);
        _adminProfileImageErrorMessage = null;
        notifyListeners();
        return true;
      }
      _handleAdminProfileImageHydrationFailure(
        'download returned empty bytes',
        url,
      );
    } catch (e) {
      _handleAdminProfileImageHydrationFailure(e, url);
    }
    notifyListeners();
    return false;
  }

  void _handleAdminProfileImageHydrationFailure(Object error, String url) {
    _clearAdminProfileImageCache();
    if (!_surfaceAdminProfileImageHydrationErrors) {
      authDebugLogError(
        '[AuthViewModel._hydrateAdminProfileImageIfNeeded] silent byte hydration failed for ${_profileImageReferenceKind(url)}',
        error,
      );
      _adminProfileImageErrorMessage = null;
      return;
    }
    _adminProfileImageErrorMessage =
        'Could not load your saved profile photo. Please update it again.';
    authDebugLogError(
      '[AuthViewModel._hydrateAdminProfileImageIfNeeded] ${_profileImageReferenceKind(url)}',
      error,
    );
  }

  void _reportAdminProfileImageRenderFailure(Object error) {
    final url = _currentAdmin?.profileImageUrl.trim() ?? '';
    if (url.isEmpty) return;
    const message =
        'Could not load your saved profile photo. Please update it again.';
    if (_adminProfileImageErrorMessage == message) return;
    _adminProfileImageErrorMessage = message;
    authDebugLogError(
      '[AuthViewModel.reportAdminProfileImageRenderFailure] ${_profileImageReferenceKind(url)}',
      error,
    );
    notifyListeners();
  }

  String _profileImageReferenceKind(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'empty-reference';
    if (trimmed.startsWith('profile_images/')) {
      return 'profile-image-storage-path';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return 'invalid-reference';
    if (uri.scheme == 'gs') return 'gs-storage-url';
    if (uri.host.toLowerCase().contains('firebasestorage.googleapis.com')) {
      return 'firebase-download-url';
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return 'external-http-url';
    }
    return 'unsupported-reference';
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
  String _mapAuthError(Object e) => mapAuthErrorMessage(e);

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
