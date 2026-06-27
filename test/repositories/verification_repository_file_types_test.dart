import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';

void main() {
  group('VerificationRepository file validation', () {
    test('allows image and PDF formats for server OCR uploads', () {
      expect(
        VerificationRepository.supportedVerificationDocumentExtensions,
        containsAll(['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']),
      );
      expect(
        VerificationRepository.isSupportedVerificationFileName('bill.pdf'),
        isTrue,
      );
      expect(
        VerificationRepository.isSupportedVerificationFileName('card.HEIF'),
        isTrue,
      );
      expect(
        VerificationRepository.isSupportedVerificationFileName('proof.docx'),
        isFalse,
      );
    });
  });
}
