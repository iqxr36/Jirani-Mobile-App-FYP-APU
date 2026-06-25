part of '../auth_viewmodel.dart';

mixin _AuthViewModelVerificationMixin on _AuthViewModelBase {
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

  Future<bool> refreshEmailVerificationStatus() async {
    _setLoading(true);
    clearError(notify: false);
    _successMessage = null;

    try {
      await _repository.currentFirebaseUser?.reload();
      _firebaseUser = _repository.currentFirebaseUser;
      await _loadCurrentProfiles();
      final verified =
          _firebaseUser?.emailVerified ?? _currentUser?.emailVerified ?? false;
      if (!verified) {
        _errorMessage = 'Please verify your email before continuing.';
      }
      return verified;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
