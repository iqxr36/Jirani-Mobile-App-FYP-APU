import 'package:fyp_flutter_application/data/repositories/item_repository.dart';

class ItemService extends ItemRepository {
  ItemService({
    super.auth,
    super.firestore,
    super.storage,
  });
}
