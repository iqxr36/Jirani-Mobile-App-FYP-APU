part of '../auth_viewmodel.dart';

mixin _AuthViewModelRegistrationMixin on _AuthViewModelBase {
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
    final validationError =
        Validators.validateFirstName(firstName) ??
        Validators.validateLastName(lastName) ??
        Validators.validateEmail(email) ??
        Validators.validatePhone(phoneNumber) ??
        Validators.validatePassword(password);
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }
    if (!termsAccepted) {
      _setValidationError('Accept the terms and conditions to continue.');
      return;
    }

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
      _showEmailVerificationAfterRegister = false;
      _showPhoneVerificationAfterRegister = false;
      _showAccountCreatedScreen = true;
      _successMessage =
          'Account created. You can verify your email and phone later from your profile.';
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

  /// After OTP step (success, back, or skip), continue to the geofence gate.
  void exitPhoneVerificationRegistrationFlow() {
    _showEmailVerificationAfterRegister = false;
    _showPhoneVerificationAfterRegister = false;
    _showAccountCreatedScreen = false;
    notifyListeners();
  }
}
