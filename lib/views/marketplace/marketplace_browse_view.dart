import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/item_viewmodel.dart';
import 'package:fyp_flutter_application/views/marketplace/add_item_view.dart';
import 'package:fyp_flutter_application/views/marketplace/item_details_view.dart';
import 'package:fyp_flutter_application/views/marketplace/my_listed_items_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_status_view.dart';
import 'package:fyp_flutter_application/widgets/category_chip.dart';
import 'package:fyp_flutter_application/widgets/item_card.dart';
import 'package:fyp_flutter_application/widgets/verification_required_widget.dart';
import 'package:provider/provider.dart';

class MarketplaceBrowseView extends StatefulWidget {
  const MarketplaceBrowseView({super.key});

  @override
  State<MarketplaceBrowseView> createState() => _MarketplaceBrowseViewState();
}

class _MarketplaceBrowseViewState extends State<MarketplaceBrowseView> {
  final _searchController = TextEditingController();

  static const _categories = <(String, String)>[
    ('all', 'All'),
    (AppConstants.itemCategoryTools, 'Tools'),
    (AppConstants.itemCategoryKitchen, 'Kitchen'),
    (AppConstants.itemCategoryElectronics, 'Electronics'),
    (AppConstants.itemCategoryCleaning, 'Cleaning'),
    (AppConstants.itemCategoryStudy, 'Study'),
    (AppConstants.itemCategoryEventItems, 'Event Items'),
    (AppConstants.itemCategoryOther, 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      context.read<ItemViewModel>().watchAvailableItems(communityId: auth.currentUser?.communityId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final itemVm = context.watch<ItemViewModel>();
    final user = authVm.currentUser;
    final displayedItems = itemVm.availableItems
        .where((item) => user == null || item.ownerId != user.uid)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyListedItemsView()),
              );
            },
            child: const Text('My Listed Items'),
          ),
        ],
      ),
      body: user == null || !user.isVerifiedResident
          ? VerificationRequiredWidget(
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
                );
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by title, category, description',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: itemVm.setSearchQuery,
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final (value, label) = _categories[i];
                      return CategoryChip(
                        label: label,
                        selected: itemVm.selectedCategoryFilter == value,
                        onTap: () => itemVm.setCategoryFilter(value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (itemVm.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (itemVm.errorMessage != null) {
                        return Center(child: Text(itemVm.errorMessage!));
                      }
                      if (displayedItems.isEmpty) {
                        return const Center(child: Text('No available items yet.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedItems.length,
                        itemBuilder: (context, i) {
                          final item = displayedItems[i];
                          return ItemCard(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ItemDetailsView(itemId: item.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: user != null && user.isVerifiedResident
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AddItemView()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }
}
