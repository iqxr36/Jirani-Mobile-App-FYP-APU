import 'package:fyp_flutter_application/data/repositories/auth_repository.dart';

class AuthService extends AuthRepository {
  AuthService({
    super.authService,
    super.firestore,
  });
}
