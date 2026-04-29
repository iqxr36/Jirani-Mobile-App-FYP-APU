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
}
