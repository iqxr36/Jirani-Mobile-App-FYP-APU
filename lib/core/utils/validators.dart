class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final regex = RegExp(pattern);
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  static String? validateRequiredField(String? value, {String fieldName = 'Field'}) {
    if ((value ?? '').trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    final fullName = value?.trim() ?? '';
    if (fullName.isEmpty) {
      return 'Full name is required.';
    }
    if (fullName.length < 2) {
      return 'Full name is too short.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Phone number is required.';
    }
    final digits = raw.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number (8–15 digits).';
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(digits)) {
      return 'Use digits only, optional leading +.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
