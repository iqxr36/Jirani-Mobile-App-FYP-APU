import 'package:fyp_flutter_application/data/repositories/verification_repository.dart';

class VerificationService extends VerificationRepository {
  VerificationService({
    super.auth,
    super.firestore,
    super.storage,
  });
}
