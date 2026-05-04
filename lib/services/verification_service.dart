import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_flutter_application/data/repositories/verification_repository.dart';

class VerificationService extends VerificationRepository {
  VerificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : super(
          auth: auth,
          firestore: firestore,
          storage: storage,
        );
}
