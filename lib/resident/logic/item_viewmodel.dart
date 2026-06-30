import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/data/repositories/item_repository.dart';

// Marketplace listing feature: stores resident listing state and calls ItemRepository for item CRUD and image uploads.
class ItemViewModel extends ChangeNotifier {
  ItemViewModel({ItemRepository? repository})
    : _repository = repository ?? ItemRepository();

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

  // Marketplace listing feature: streams available items using the current search/category/community filters.
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

  // Marketplace listing feature: streams listings owned by the signed-in lender.
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

  // Marketplace listing feature: loads one listing for detail, borrow, or edit screens.
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

  // Marketplace listing feature: creates a new lendable item with optional fee, deposit, and images.
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

  // Marketplace listing feature: updates listing details and refreshes the selected item after saving.
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

  // Marketplace listing feature: hides a listing from borrowers without deleting its transaction history.
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

  // Marketplace listing feature: restores an archived listing back to available status.
  Future<void> unarchiveItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.unarchiveItem(itemId);
      if (_selectedItem?.id == itemId) {
        _selectedItem = _selectedItem?.copyWith(
          isArchived: false,
          status: AppConstants.itemStatusAvailable,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace listing feature: updates the search filter and restarts the available-item stream.
  void setSearchQuery(String value) {
    _searchQuery = value;
    watchAvailableItems(communityId: _communityIdFilter);
  }

  // Marketplace listing feature: updates the category filter and restarts the available-item stream.
  void setCategoryFilter(String value) {
    _selectedCategoryFilter = value;
    watchAvailableItems(communityId: _communityIdFilter);
  }

  // Marketplace UI state: remembers the listing currently opened by the resident.
  void selectItem(ItemModel item) {
    _selectedItem = item;
    notifyListeners();
  }

  // Marketplace UI state: clears the latest listing error after the UI shows it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Marketplace UI state: clears stale listing detail data when leaving detail/edit flows.
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
