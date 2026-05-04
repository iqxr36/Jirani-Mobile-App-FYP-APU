import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_flutter_application/data/repositories/item_repository.dart';

class ItemService extends ItemRepository {
  ItemService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : super(
          auth: auth,
          firestore: firestore,
          storage: storage,
        );
}
