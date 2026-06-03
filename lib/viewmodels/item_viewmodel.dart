import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/data/models/app_user.dart';
import 'package:jirani/data/models/item_model.dart';
import 'package:jirani/data/repositories/item_repository.dart';

class ItemViewModel extends ChangeNotifier {
  ItemViewModel({ItemRepository? repository}) : _repository = repository ?? ItemRepository();

  final ItemRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<ItemModel> _availableItems = const <ItemModel>[];
  List<ItemModel> _myItems = const <ItemModel>[];
  ItemModel? _selectedItem;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';
  String? _communityIdFilter;

  StreamSubscription<List<ItemModel>>? _availableItemsSub;
  StreamSubscription<List<ItemModel>>? _myItemsSub;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ItemModel> get availableItems => _availableItems;
  List<ItemModel> get myItems => _myItems;
  ItemModel? get selectedItem => _selectedItem;
  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  void watchAvailableItems({String? communityId}) {
    _communityIdFilter = communityId;
    _availableItemsSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _availableItemsSub = _repository
        .watchAvailableItems(
          searchQuery: _searchQuery,
          category: _selectedCategoryFilter,
          communityId: _communityIdFilter,
        )
        .listen(
      (items) {
        _availableItems = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  void watchMyItems() {
    _myItemsSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _myItemsSub = _repository.watchMyItems().listen(
      (items) {
        _myItems = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> loadItemById(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedItem = await _repository.getItemById(itemId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required List<String> imagePaths,
    required bool hasUsageFee,
    double? feeAmount,
    required bool hasDeposit,
    double? depositAmount,
    required String pickupInstructions,
    required AppUser currentUser,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.addItem(
        title: title,
        description: description,
        category: category,
        condition: condition,
        imagePaths: imagePaths,
        hasUsageFee: hasUsageFee,
        feeAmount: feeAmount,
        hasDeposit: hasDeposit,
        depositAmount: depositAmount,
        pickupInstructions: pickupInstructions,
        currentUser: currentUser,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateItem({
    required String itemId,
    required String title,
    required String description,
    required String category,
    required String condition,
    required bool hasUsageFee,
    double? feeAmount,
    required bool hasDeposit,
    double? depositAmount,
    required String pickupInstructions,
    List<String>? newImagePaths,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateItem(
        itemId: itemId,
        title: title,
        description: description,
        category: category,
        condition: condition,
        hasUsageFee: hasUsageFee,
        feeAmount: feeAmount,
        hasDeposit: hasDeposit,
        depositAmount: depositAmount,
        pickupInstructions: pickupInstructions,
        newImagePaths: newImagePaths,
      );
      await loadItemById(itemId);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> archiveItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.archiveItem(itemId);
      if (_selectedItem?.id == itemId) {
        _selectedItem = _selectedItem?.copyWith(isArchived: true);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    watchAvailableItems(communityId: _communityIdFilter);
  }

  void setCategoryFilter(String value) {
    _selectedCategoryFilter = value;
    watchAvailableItems(communityId: _communityIdFilter);
  }

  void selectItem(ItemModel item) {
    _selectedItem = item;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedItem() {
    _selectedItem = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _availableItemsSub?.cancel();
    _myItemsSub?.cancel();
    super.dispose();
  }
}
