// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_viewmodel_registration.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../auth_viewmodel.dart';

mixin _AuthViewModelRegistrationMixin on _AuthViewModelBase {
  /// Auth registration: validates resident signup input, creates Firebase/Auth profile data, and starts onboarding.
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
      _showAccountCreatedScreen = true;
      _successMessage =
          'Account created. You can verify your email later from your profile.';
    } catch (e) {
      _errorMessage = _mapAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Auth onboarding: hides the account-created confirmation after the resident continues.
  void dismissAccountCreatedScreen() {
    _showAccountCreatedScreen = false;
    notifyListeners();
  }

  /// After email verification succeeds (or is skipped), continue to the main resident flow.
  void exitEmailVerificationRegistrationFlow() {
    _showEmailVerificationAfterRegister = false;
    _showAccountCreatedScreen = false;
    notifyListeners();
  }

  /// Lets new residents postpone email verification and continue onboarding.
  void skipEmailVerificationRegistrationFlow() {
    exitEmailVerificationRegistrationFlow();
  }
}
