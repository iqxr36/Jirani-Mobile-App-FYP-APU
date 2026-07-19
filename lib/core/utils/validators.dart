// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : validators.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,30-April-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:jirani/core/constants/app_constants.dart';

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

  static String? validateMaxLength(
    String? value, {
    required int maxLength,
    String fieldName = 'Field',
  }) {
    final text = value ?? '';
    if (text.length > maxLength) {
      return '$fieldName must be at most $maxLength characters.';
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
    if (name.length > 60) {
      return '$fieldName is too long.';
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
    return validateMaxLength(
      title,
      maxLength: AppConstants.maxItemTitleLength,
      fieldName: 'Item title',
    );
  }

  static String? validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Description is required.';
    }
    if (description.length < AppConstants.minItemDescriptionLength) {
      return 'Description should be at least '
          '${AppConstants.minItemDescriptionLength} characters.';
    }
    return validateMaxLength(
      description,
      maxLength: AppConstants.maxListingDescriptionLength,
      fieldName: 'Description',
    );
  }

  static String? validatePickupInstructions(String? value) {
    return validateMaxLength(
      value,
      maxLength: AppConstants.maxPickupInstructionsLength,
      fieldName: 'Pickup instructions',
    );
  }

  static String? validateServiceTitle(String? value) {
    return _validateRequiredBoundedText(
      value,
      fieldName: 'Service name',
      minLength: AppConstants.minServiceTitleLength,
      maxLength: AppConstants.maxShortTextLength,
    );
  }

  static String? validateServiceDescription(String? value) {
    return _validateRequiredBoundedText(
      value,
      fieldName: 'Service description',
      minLength: AppConstants.minServiceDescriptionLength,
      maxLength: AppConstants.maxListingDescriptionLength,
    );
  }

  static String? validateServiceAvailability(String? value) {
    return _validateRequiredBoundedText(
      value,
      fieldName: 'Service availability',
      maxLength: AppConstants.maxMediumTextLength,
    );
  }

  static String? _validateRequiredBoundedText(
    String? value, {
    required String fieldName,
    int minLength = 1,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName is required.';
    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters.';
    }
    return validateMaxLength(text, maxLength: maxLength, fieldName: fieldName);
  }

  static String? validateOptionalMessage(
    String? value, {
    String fieldName = 'Message',
  }) {
    final message = value?.trim() ?? '';
    if (message.isEmpty) return null;
    return validateMaxLength(
      message,
      maxLength: AppConstants.maxMediumTextLength,
      fieldName: fieldName,
    );
  }

  static String? validateReviewComment(String? value) {
    final comment = value?.trim() ?? '';
    if (comment.isEmpty) return null;
    return validateMaxLength(
      comment,
      maxLength: AppConstants.maxReviewCommentLength,
      fieldName: 'Review comment',
    );
  }

  static String? validateFourDigitCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Code is required.';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      return 'Enter a 4-digit code.';
    }
    return null;
  }

  static String? validateSixDigitCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Verification code is required.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'Enter the 6-digit verification code.';
    }
    return null;
  }
}
