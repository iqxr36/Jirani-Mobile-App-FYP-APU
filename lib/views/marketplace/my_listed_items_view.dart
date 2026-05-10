import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/item_viewmodel.dart';
import 'package:fyp_flutter_application/views/marketplace/add_item_view.dart';
import 'package:fyp_flutter_application/views/marketplace/edit_item_view.dart';
import 'package:fyp_flutter_application/views/marketplace/item_details_view.dart';
import 'package:fyp_flutter_application/resident/screens/borrowing/incoming_borrow_requests_screen.dart';
import 'package:fyp_flutter_application/views/verification/verification_status_view.dart';
import 'package:fyp_flutter_application/widgets/category_chip.dart';
import 'package:fyp_flutter_application/widgets/item_card.dart';
import 'package:fyp_flutter_application/widgets/verification_required_widget.dart';
import 'package:provider/provider.dart';

class MyListedItemsView extends StatefulWidget {
  const MyListedItemsView({super.key});

  @override
  State<MyListedItemsView> createState() => _MyListedItemsViewState();
}

class _MyListedItemsViewState extends State<MyListedItemsView> {
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemViewModel>().watchMyItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<ItemViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Listed Items')),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    CategoryChip(
                      label: 'Active',
                      selected: _statusFilter == 'active',
                      onTap: () => setState(() => _statusFilter = 'active'),
                    ),
                    CategoryChip(
                      label: 'Unavailable',
                      selected: _statusFilter == AppConstants.itemStatusUnavailable,
                      onTap: () => setState(() => _statusFilter = AppConstants.itemStatusUnavailable),
                    ),
                    CategoryChip(
                      label: 'Archived',
                      selected: _statusFilter == AppConstants.itemStatusArchived,
                      onTap: () => setState(() => _statusFilter = AppConstants.itemStatusArchived),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const IncomingBorrowRequestsScreen()),
                      );
                    },
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Incoming Requests'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (vm.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (vm.errorMessage != null) {
                        return Center(child: Text(vm.errorMessage!));
                      }
                      final filtered = vm.myItems.where((item) {
                        if (_statusFilter == 'active') {
                          return item.status == AppConstants.itemStatusAvailable && !item.isArchived;
                        }
                        return item.status == _statusFilter;
                      }).toList(growable: false);

                      if (filtered.isEmpty) {
                        return const Center(child: Text('You have not listed any items yet.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return ItemCard(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ItemDetailsView(itemId: item.id),
                                ),
                              );
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => EditItemView(itemId: item.id),
                                    ),
                                  );
                                } else if (v == 'archive') {
                                  await vm.archiveItem(item.id);
                                  if (!context.mounted) return;
                                  if (vm.errorMessage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item archived.')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'archive', child: Text('Archive')),
                              ],
                            ),
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
