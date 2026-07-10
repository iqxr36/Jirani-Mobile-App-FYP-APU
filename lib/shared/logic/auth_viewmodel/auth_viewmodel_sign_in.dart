part of '../auth_viewmodel.dart';

mixin _AuthViewModelSignInMixin on _AuthViewModelBase {
  /// Auth sign-in: validates credentials, signs in through Firebase, and loads resident/admin Firestore profile data.
  Future<void> login({required String email, required String password}) async {
    authDebugLog('[AuthProvider.login] started');
    final validationError =
        Validators.validateEmail(email) ??
        Validators.validatePassword(password);
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      authDebugLog('[AuthProvider.login] Firebase/Repository sign-in started');
      await _repository.login(email: email, password: password);
      await _loadCurrentProfiles();
      if (_currentUser == null && _currentAdmin == null) {
        throw Exception(_missingProfileMessage());
      }
      authDebugLog('[AuthProvider.login] Repository login success');
      _firebaseUser = _repository.currentFirebaseUser;
      authDebugLog('[AuthProvider.login] firebase session established');
      authDebugLog(
        '[AuthProvider.login] loaded userRole=${_currentUser?.role} adminRole=${_currentAdmin?.role}',
      );
      _showAccountCreatedScreen = false;
    } catch (e) {
      authDebugLogError('[AuthProvider.login]', e);
      _errorMessage = _mapAuthError(e);
    } finally {
      authDebugLog('[AuthProvider.login] isLoading set false');
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
      authDebugLogError('[AuthProvider.signInWithGoogle]', e);
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Auth sign-out: clears Firebase session and local resident/admin state.
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

  /// Auth recovery: validates email and requests Firebase password reset.
  Future<void> sendPasswordResetEmail(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _setValidationError(emailError);
      return;
    }
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
}
