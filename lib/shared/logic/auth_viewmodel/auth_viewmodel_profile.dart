part of '../auth_viewmodel.dart';

mixin _AuthViewModelProfileMixin on _AuthViewModelBase {
  /// Profile feature: saves editable resident profile fields and resets phone verification when phone changes.
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

    final validationError =
        Validators.validateFirstName(firstName) ??
        Validators.validateLastName(lastName) ??
        Validators.validatePhone(phoneNumber);
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }

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

  /// Profile feature: updates resident name/email/phone and starts Firebase email-change verification when needed.
  Future<bool> updateResidentProfileBasics({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      _errorMessage = 'You must be signed in to update your profile.';
      notifyListeners();
      return false;
    }

    final validationError =
        Validators.validateFirstName(firstName) ??
        Validators.validateLastName(lastName) ??
        Validators.validateEmail(email) ??
        Validators.validatePhone(phoneNumber);
    if (validationError != null) {
      _setValidationError(validationError);
      return false;
    }
    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();

    _setLoading(true);
    clearError(notify: false);

    try {
      final trimmedEmail = email.trim();
      final authEmail =
          (_firebaseUser?.email ?? _repository.currentFirebaseUser?.email ?? '')
              .trim();
      final storedEmail = _currentUser?.email.trim() ?? '';
      final previousEmail = authEmail.isNotEmpty ? authEmail : storedEmail;
      final emailChangeRequested =
          trimmedEmail.toLowerCase() != previousEmail.toLowerCase();
      if (emailChangeRequested) {
        await _repository.updateResidentEmail(trimmedEmail);
      }
      final normalizedPhone = Validators.normalizePhoneNumber(phoneNumber);
      final previousPhone = _currentUser?.phoneNumber ?? '';
      final phoneChanged = normalizedPhone != previousPhone;
      final fields = <String, dynamic>{
        'firstName': trimmedFirstName,
        'lastName': trimmedLastName,
        'fullName': '$trimmedFirstName $trimmedLastName'.trim(),
        'phoneNumber': normalizedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (phoneChanged) {
        fields['phoneVerified'] = false;
      }

      await _userRepository.updateUserFields(uid: uid, fields: fields);
      await refreshCurrentUser();
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Profile feature: uploads a resident avatar and saves the public image URL on users/{uid}.
  Future<bool> updateResidentProfileImage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      _errorMessage = 'You must be signed in to update your profile image.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    clearError(notify: false);

    try {
      final url = await _repository.uploadProfileImage(
        uid: uid,
        bytes: bytes,
        originalFileName: originalFileName,
        accountFolder: 'residents',
      );
      await _userRepository.updateUserFields(
        uid: uid,
        fields: {'profileImageUrl': url},
      );
      _currentUser = _currentUser?.copyWith(profileImageUrl: url);
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Admin profile feature: uploads an admin avatar and saves the URL on admins/{uid}.
  Future<bool> updateAdminProfileImage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentAdmin?.uid;
    if (uid == null) {
      _errorMessage = 'You must be signed in to update your profile image.';
      notifyListeners();
      return false;
    }

    clearError(notify: false);

    try {
      final url = await _repository.uploadProfileImage(
        uid: uid,
        bytes: bytes,
        originalFileName: originalFileName,
        accountFolder: 'admins',
      );
      await _repository.updateAdminProfileImageUrl(
        uid: uid,
        profileImageUrl: url,
      );
      final refreshed = await _repository.getCurrentAdminUser(
        reloadAuthUser: false,
        preferServer: true,
      );
      final savedUrl = refreshed?.profileImageUrl.trim() ?? '';
      if (savedUrl.isEmpty || savedUrl != url.trim()) {
        throw Exception(
          'Profile photo uploaded, but could not be saved to your admin profile. Please try again.',
        );
      }

      _setAdminProfileImageBytes(bytes, savedUrl);
      _adminProfileImageErrorMessage = null;
      _currentAdmin = refreshed;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Admin settings feature: saves display name, optional phone, and notification prefs.
  Future<bool> updateAdminProfileSettings({
    required String fullName,
    required String phoneNumber,
    required AdminNotificationPreferences notificationPreferences,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentAdmin?.uid;
    if (uid == null) {
      _errorMessage = 'You must be signed in to update your profile.';
      notifyListeners();
      return false;
    }

    final trimmedPhone = phoneNumber.trim();
    final validationError =
        Validators.validateFullName(fullName) ??
        (trimmedPhone.isEmpty ? null : Validators.validatePhone(phoneNumber));
    if (validationError != null) {
      _setValidationError(validationError);
      return false;
    }

    _setLoading(true);
    clearError(notify: false);

    try {
      await _repository.updateAdminProfile(
        uid: uid,
        fullName: fullName,
        phoneNumber: phoneNumber,
        notificationPreferences: notificationPreferences,
      );
      _currentAdmin = await _repository.getCurrentAdminUser(
        reloadAuthUser: false,
      );
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
