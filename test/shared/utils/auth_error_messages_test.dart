import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/utils/auth_error_messages.dart';

void main() {
  group('mapAuthErrorMessage', () {
    test('maps undeployed delete callable not-found', () {
      final message = mapAuthErrorMessage(
        FirebaseFunctionsException(
          code: 'not-found',
          message: 'NOT_FOUND',
          details: null,
        ),
      );

      expect(
        message,
        'Account deletion is not available yet. Ask your administrator to deploy the latest Cloud Functions.',
      );
    });

    test('maps undeployed phone update callable not-found', () {
      final message = mapAuthErrorMessage(
        FirebaseFunctionsException(
          code: 'not-found',
          message: 'NOT_FOUND',
          details: null,
        ),
        context: 'phoneUpdate',
      );

      expect(
        message,
        contains('updateResidentPhoneNumber'),
      );
    });

    test('maps missing resident profile not-found', () {
      final message = mapAuthErrorMessage(
        FirebaseFunctionsException(
          code: 'not-found',
          message: 'Resident profile was not found.',
          details: null,
        ),
      );

      expect(
        message,
        'Your resident profile was not found. Sign out and sign in again, or contact support.',
      );
    });

    test('maps recent-login-required failed-precondition', () {
      final message = mapAuthErrorMessage(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Please sign in again before deleting your account.',
          details: {'reason': 'recent-login-required'},
        ),
      );

      expect(
        message,
        'For security, sign out and sign in again, then retry deletion.',
      );
    });

    test('maps wrong-password auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'wrong-password'),
      );

      expect(message, 'The password is incorrect.');
    });

    test('maps phone already-exists callable errors', () {
      final message = mapAuthErrorMessage(
        FirebaseFunctionsException(
          code: 'already-exists',
          message:
              'This phone number is already registered to another account.',
          details: null,
        ),
      );

      expect(
        message,
        'This phone number is already registered to another account.',
      );
    });

    test('maps invalid phone number auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'invalid-phone-number'),
      );

      expect(
        message,
        'Enter a valid phone number with country code (e.g. +60…).',
      );
    });

    test('maps invalid verification code auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );

      expect(
        message,
        'That verification code is incorrect. Check the SMS and try again.',
      );
    });

    test('maps reCAPTCHA / missing client identifier auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'missing-client-identifier'),
      );

      expect(
        message,
        contains('SHA fingerprints'),
      );
    });

    test('maps captcha-check-failed auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'captcha-check-failed'),
      );

      expect(message, contains('App verification failed'));
    });

    test('maps billing-not-enabled auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'billing-not-enabled'),
      );

      expect(message, contains('billing'));
    });

    test('maps credential-already-in-use auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(code: 'credential-already-in-use'),
      );

      expect(
        message,
        'This phone number is already linked to another account.',
      );
    });

    test('falls back to code and message for unknown auth errors', () {
      final message = mapAuthErrorMessage(
        FirebaseAuthException(
          code: 'some-unknown-code',
          message: 'Something went wrong.',
        ),
      );

      expect(message, 'some-unknown-code: Something went wrong.');
    });
  });
}
