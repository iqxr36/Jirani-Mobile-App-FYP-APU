import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_flutter_application/data/repositories/auth_repository.dart';
import 'package:fyp_flutter_application/services/firebase_auth_service.dart';

class AuthService extends AuthRepository {
  AuthService({
    FirebaseAuthService? authService,
    FirebaseFirestore? firestore,
  }) : super(
          authService: authService,
          firestore: firestore,
        );
}
