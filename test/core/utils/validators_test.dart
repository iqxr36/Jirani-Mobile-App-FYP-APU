// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : validators_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('person names reject numbers and symbols', () {
      expect(Validators.validateFirstName('Faisal'), isNull);
      expect(Validators.validateLastName("O'Neil-Smith"), isNull);
      expect(Validators.validateFirstName('Faisal123'), isNotNull);
      expect(Validators.validateLastName('Doe!'), isNotNull);
    });

    test('phone requires country code and valid digit length', () {
      expect(Validators.validatePhone('+60 12-345 6789'), isNull);
      expect(Validators.validatePhone('0123456789'), isNotNull);
      expect(Validators.validatePhone('+60 ABC'), isNotNull);
      expect(Validators.validatePhone('+601'), isNotNull);
    });

    test('email must look like an email address', () {
      expect(Validators.validateEmail('resident@example.com'), isNull);
      expect(Validators.validateEmail('resident.example.com'), isNotNull);
    });

    test('blank email reports the required-field message', () {
      expect(Validators.validateEmail(''), 'Email is required.');
    });

    test('password confirmation must match', () {
      expect(
        Validators.validateConfirmPassword('jiran123', 'jirani123'),
        'Passwords do not match.',
      );
    });

    test('verification codes require exact digit counts', () {
      expect(Validators.validateFourDigitCode('1234'), isNull);
      expect(Validators.validateFourDigitCode('12345'), isNotNull);
      expect(Validators.validateFourDigitCode('12A4'), isNotNull);
      expect(Validators.validateSixDigitCode('123456'), isNull);
      expect(Validators.validateSixDigitCode('12345'), isNotNull);
    });

    test('item description accepts 12 characters and rejects 11', () {
      expect(Validators.validateDescription('a' * 11), isNotNull);
      expect(Validators.validateDescription('a' * 12), isNull);
    });

    test('item description accepts 1000 characters and rejects 1001', () {
      expect(Validators.validateDescription('a' * 1000), isNull);
      expect(Validators.validateDescription('a' * 1001), isNotNull);
    });

    test('two-character item title is rejected', () {
      expect(Validators.validateItemTitle('TV'), 'Item title is too short.');
    });

    test('amounts must be greater than zero', () {
      expect(Validators.validatePositiveAmount('0'), isNotNull);
      expect(Validators.validatePositiveAmount('0.00'), isNotNull);
      expect(Validators.validatePositiveAmount('-1'), isNotNull);
      expect(Validators.validatePositiveAmount('0.01'), isNull);
    });

    test('review comment is limited to 1000 characters', () {
      expect(Validators.validateReviewComment('a' * 1000), isNull);
      expect(Validators.validateReviewComment('a' * 1001), isNotNull);
    });

    test('service text fields enforce the shared maximum lengths', () {
      expect(Validators.validateServiceTitle('a' * 200), isNull);
      expect(Validators.validateServiceTitle('a' * 201), isNotNull);
      expect(Validators.validateServiceDescription('a' * 1000), isNull);
      expect(Validators.validateServiceDescription('a' * 1001), isNotNull);
      expect(Validators.validateServiceAvailability('a' * 1000), isNull);
      expect(Validators.validateServiceAvailability('a' * 1001), isNotNull);
    });

    test('service name accepts 3 characters and rejects 2', () {
      expect(Validators.validateServiceTitle('ab'), isNotNull);
      expect(Validators.validateServiceTitle('abc'), isNull);
    });

    test('service description accepts 12 characters and rejects 11', () {
      expect(Validators.validateServiceDescription('a' * 11), isNotNull);
      expect(Validators.validateServiceDescription('a' * 12), isNull);
    });
  });
}
