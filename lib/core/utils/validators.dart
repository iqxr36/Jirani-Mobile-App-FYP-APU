class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  );

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!_emailRegex.hasMatch(email)) {
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

  static String? validateRequiredField(
    String? value, {
    String fieldName = 'Field',
  }) {
    if ((value ?? '').trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static final RegExp _personNameRegex = RegExp(r"^[A-Za-z][A-Za-z\s'-]*$");

  static String? validateFirstName(String? value) {
    return _validatePersonName(value, fieldName: 'First name');
  }

  static String? validateLastName(String? value) {
    return _validatePersonName(value, fieldName: 'Last name');
  }

  static String? validateFullName(String? value) {
    return _validatePersonName(value, fieldName: 'Full name');
  }

  static String? _validatePersonName(
    String? value, {
    required String fieldName,
  }) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return '$fieldName is required.';
    }
    if (name.length < 2) {
      return '$fieldName is too short.';
    }
    if (!_personNameRegex.hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, apostrophes, and hyphens.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    return validatePhoneNumberWithCountryCode(value);
  }

  static String? validatePhoneNumberWithCountryCode(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Phone number is required.';
    }

    if (!raw.startsWith('+')) {
      return 'Include country code starting with + (e.g. +60).';
    }

    if (RegExp(r'[^0-9+\s-]').hasMatch(raw)) {
      return 'Phone number can only contain +, digits, spaces, and dashes.';
    }

    final normalized = normalizePhoneNumber(raw);
    if (!RegExp(r'^\+[0-9]+$').hasMatch(normalized)) {
      return 'Phone number must contain only digits after +.';
    }

    final digits = normalized.substring(1);
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number with country code (8-15 digits).';
    }

    return null;
  }

  static String normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.startsWith('+')) {
      return '+${cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    return cleaned.replaceAll(RegExp(r'[^0-9]'), '');
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

  static String? validatePositiveAmount(
    String? value, {
    String fieldName = 'Amount',
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return '$fieldName is required.';
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return '$fieldName must be greater than 0.';
    }
    return null;
  }

  static String? validateItemTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Item title is required.';
    }
    if (title.length < 3) {
      return 'Item title is too short.';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Description is required.';
    }
    if (description.length < 10) {
      return 'Description should be at least 10 characters.';
    }
    return null;
  }
}
