// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_viewmodel_sign_in.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../auth_viewmodel.dart';

mixin _AuthViewModelSignInMixin on _AuthViewModelBase {
  /// Auth sign-in: validates credentials, signs in through Firebase, and loads resident/admin Firestore profile data.
  Future<void> login({
    required String email,
    required String password,
    bool requireAdmin = false,
  }) async {
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
      if (requireAdmin && _currentAdmin == null) {
        final message = _adminPortalAccessMessage();
        await _rejectNonAdminPortalSession();
        throw Exception(message);
      }
      if (_currentUser == null && _currentAdmin == null) {
        throw Exception(_missingProfileMessage());
      }
      authDebugLog('[AuthProvider.login] Repository login success');
      _firebaseUser = _repository.currentFirebaseUser;
      _needsGoogleRegistration = false;
      authDebugLog('[AuthProvider.login] firebase session established');
      authDebugLog(
        '[AuthProvider.login] loaded userRole=${_currentUser?.role} adminRole=${_currentAdmin?.role}',
      );
      _showAccountCreatedScreen = false;
    } catch (e) {
      authDebugLogError('[AuthProvider.login]', e);
      _errorMessage = mapLoginErrorMessage(e);
    } finally {
      authDebugLog('[AuthProvider.login] isLoading set false');
      _setLoading(false);
    }
  }

  String _adminPortalAccessMessage() {
    final user = _currentUser;
    if (user?.role == AppConstants.roleResident) {
      return 'This account is a resident account. Please sign in through the Resident Mobile App.';
    }
    if (user?.role == AppConstants.roleCommunityAdmin ||
        user?.role == AppConstants.roleSystemAdmin) {
      return 'This account has an old admin role in users. Create an admins/${user?.uid} document and assign its community there.';
    }
    return 'Admin access is required. This account is not registered as an active administrator.';
  }

  Future<void> _rejectNonAdminPortalSession() async {
    try {
      await _repository.logout();
    } catch (error) {
      authDebugLogError('[AuthProvider.login] rejected-session logout', error);
    } finally {
      _currentUser = null;
      _currentAdmin = null;
      _firebaseUser = null;
      _showAccountCreatedScreen = false;
      _profileErrorMessage = null;
      _clearAdminProfileImageCache();
    }
  }

  /// Returns without error if the user cancelled the Google account picker.
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;
    _profileErrorMessage = null;

    try {
      final result = await _repository.signInWithGoogle();
      if (result.status == GoogleSignInStatus.cancelled) return;

      _currentUser = result.user;
      _currentAdmin = null;
      _firebaseUser = _repository.currentFirebaseUser;
      _needsGoogleRegistration =
          result.status == GoogleSignInStatus.registrationRequired;
      _profileErrorMessage = null;
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
      _needsGoogleRegistration = false;
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
