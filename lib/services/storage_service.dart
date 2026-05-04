import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference ref() => _storage.ref();
  Reference refFromUrl(String url) => _storage.refFromURL(url);
}
