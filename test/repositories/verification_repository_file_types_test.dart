// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_repository_file_types_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Sunday,28-June-2026
// Last Edited on  : Saturday,18-July-2026

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
