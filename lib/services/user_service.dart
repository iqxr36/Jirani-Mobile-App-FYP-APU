import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_flutter_application/data/repositories/user_repository.dart';

class UserService extends UserRepository {
  UserService({FirebaseFirestore? firestore}) : super(firestore: firestore);
}
