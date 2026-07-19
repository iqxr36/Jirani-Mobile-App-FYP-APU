// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_error_messages.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String loginCredentialFailureMessage =
    'The email or password is incorrect. Check both and try again. '
    'If you forgot your password, use Forgot Password.';

/// Login UX: explains credential failures without revealing whether an email
/// address is registered. Other authentication flows keep their own messages.
String mapLoginErrorMessage(Object error) {
  if (error is FirebaseAuthException &&
      const {'invalid-credential', 'wrong-password', 'user-not-found'}
          .contains(error.code)) {
    return loginCredentialFailureMessage;
  }
  return mapAuthErrorMessage(error);
}

/// Auth UX: converts Firebase auth and callable errors into readable messages.
///
/// Pass [context] as `phoneUpdate` when the call was `updateResidentPhoneNumber`
/// so undeployed-callable `not-found` is not mistaken for account deletion.
String mapAuthErrorMessage(Object error, {String? context}) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Sign-in failed. Please try again.';
      case 'user-not-found':
        return error.message ?? 'Sign-in failed.';
      case 'email-already-in-use':
        return 'This email is already used by another account.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'requires-recent-login':
        return 'For security, please log out and log in again before changing your email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code (e.g. +60…).';
      case 'missing-phone-number':
        return 'Phone number is missing.';
      case 'too-many-requests':
        return 'Too many verification attempts. Wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later, or use a Firebase test phone number.';
      case 'session-expired':
        return 'This verification code expired. Request a new code and try again.';
      case 'invalid-verification-code':
        return 'That verification code is incorrect. Check the SMS and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Request a new code and try again.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'A phone number is already linked to this account.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
      case 'captcha-check-failed':
        return 'App verification failed. Check Firebase Android SHA fingerprints '
            'and rebuild the app.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      case 'billing-not-enabled':
        return 'This operation requires Firebase billing to be enabled.';
    }
    final message = (error.message ?? '').trim();
    if (message.isNotEmpty) {
      return '${error.code}: $message';
    }
    return error.code;
  }

  if (error is FirebaseFunctionsException) {
    if (error.code == 'not-found') {
      final message = (error.message ?? '').trim();
      if (message.contains('Resident profile was not found')) {
        return 'Your resident profile was not found. Sign out and sign in again, or contact support.';
      }
      if (context == 'phoneUpdate') {
        return 'Phone number update is not available yet. Ask your administrator '
            'to deploy the updateResidentPhoneNumber Cloud Function.';
      }
      return 'Account deletion is not available yet. Ask your administrator to deploy the latest Cloud Functions.';
    }
    if (error.code == 'failed-precondition') {
      final details = error.details;
      if (details is Map && details['reason'] == 'recent-login-required') {
        return 'For security, sign out and sign in again, then retry deletion.';
      }
      return error.message ??
          'Resolve active account obligations before continuing.';
    }
    if (error.code == 'permission-denied') {
      return error.message ?? 'This action is not allowed.';
    }
    if (error.code == 'already-exists') {
      final message = (error.message ?? '').trim();
      if (message.toLowerCase().contains('phone number')) {
        return 'This phone number is already registered to another account.';
      }
      return message.isNotEmpty ? message : 'This record already exists.';
    }
    if (error.code == 'internal') {
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Something went wrong on the server. Please try again.';
    }
    return error.message ?? error.code;
  }

  if (error is FirebaseException) {
    if (error.code == 'failed-precondition') {
      return error.message ??
          'Resolve active account obligations before continuing.';
    }
    if (error.code == 'permission-denied') {
      return error.message ?? 'This action is not allowed.';
    }
    return error.message ?? error.code;
  }

  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.contains('Network error')) {
    return raw;
  }
  return raw;
}
