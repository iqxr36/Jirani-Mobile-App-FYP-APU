import 'package:jirani/shared/data/repositories/item_repository.dart';

class ItemService extends ItemRepository {
  ItemService({super.auth, super.firestore, super.storage});
}
