import 'package:jirani/data/repositories/item_repository.dart';

class ItemService extends ItemRepository {
  ItemService({
    super.auth,
    super.firestore,
    super.storage,
  });
}
