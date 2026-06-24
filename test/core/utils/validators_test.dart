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

    test('verification codes require exact digit counts', () {
      expect(Validators.validateFourDigitCode('1234'), isNull);
      expect(Validators.validateFourDigitCode('12345'), isNotNull);
      expect(Validators.validateFourDigitCode('12A4'), isNotNull);
      expect(Validators.validateSixDigitCode('123456'), isNull);
      expect(Validators.validateSixDigitCode('12345'), isNotNull);
    });
  });
}
