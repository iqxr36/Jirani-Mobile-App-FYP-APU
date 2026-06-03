import 'package:jirani/data/repositories/verification_repository.dart';

class VerificationService extends VerificationRepository {
  VerificationService({
    super.auth,
    super.firestore,
    super.storage,
  });
}
