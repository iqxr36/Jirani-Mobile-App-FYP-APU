import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/item_model.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/item_viewmodel.dart';
import 'package:fyp_flutter_application/views/marketplace/edit_item_view.dart';
import 'package:fyp_flutter_application/views/marketplace/report_listing_view.dart';
import 'package:fyp_flutter_application/widgets/status_chip.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';
import 'package:provider/provider.dart';

class ItemDetailsView extends StatefulWidget {
  const ItemDetailsView({super.key, required this.itemId});
  final String itemId;

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemViewModel>().loadItemById(widget.itemId);
    });
  }

  Future<void> _archive(ItemViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive item?'),
        content: const Text('This listing will be hidden from the marketplace.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (ok != true) return;
    await vm.archiveItem(widget.itemId);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item archived.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemVm = context.watch<ItemViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final item = itemVm.selectedItem;

    if (itemVm.isLoading && item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item details')),
        body: Center(child: Text(itemVm.errorMessage ?? 'Item not found.')),
      );
    }
    final isOwner = authVm.currentUser?.uid == item.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => EditItemView(itemId: item.id)),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (item.imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: item.imageUrls.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.imageUrls[i], fit: BoxFit.cover),
                  ),
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: const Icon(Icons.image_outlined, size: 48),
              ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusChip(status: item.status),
            const SizedBox(height: 10),
            Text('Category: ${_categoryLabel(item.category)}'),
            Text('Condition: ${_conditionLabel(item.condition)}'),
            const SizedBox(height: 12),
            Text(item.description),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: item.ownerPhotoUrl.isEmpty
                      ? const Icon(Icons.person_outline)
                      : ClipOval(child: Image.network(item.ownerPhotoUrl, fit: BoxFit.cover)),
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(item.ownerName)),
                    if (item.ownerVerified) ...[
                      const SizedBox(width: 6),
                      const VerifiedBadge(compact: true),
                    ],
                  ],
                ),
                subtitle: Text('Reputation: ${item.ownerReputationScore.toStringAsFixed(1)}'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_lendingLabel(item)),
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Usage Fee'),
                    subtitle: Text(item.hasUsageFee && (item.feeAmount ?? 0) > 0
                        ? 'RM ${_formatAmount(item.feeAmount!)}'
                        : 'Not required'),
                  ),
                  ListTile(
                    title: const Text('Refundable Deposit'),
                    subtitle: Text(item.hasDeposit && (item.depositAmount ?? 0) > 0
                        ? 'RM ${_formatAmount(item.depositAmount!)}'
                        : 'Not required'),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Deposit may be withheld if the item is damaged, lost, or returned late.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Pickup instructions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.pickupInstructions),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Borrow request flow will be implemented in Phase 4.')),
                );
              },
              child: const Text('Request to Borrow'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat will be implemented in Phase 6.')),
                );
              },
              child: const Text('Chat with Owner'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ReportListingView(itemId: item.id)),
                );
              },
              child: const Text('Report Listing'),
            ),
            if (isOwner) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _archive(itemVm),
                child: const Text('Archive Item'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(String value) {
    if (value.isEmpty) return 'Unknown';
    if (value == AppConstants.itemCategoryEventItems) return 'Event Items';
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _conditionLabel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _lendingLabel(ItemModel item) {
    final hasFee = item.hasUsageFee && (item.feeAmount ?? 0) > 0;
    final hasDeposit = item.hasDeposit && (item.depositAmount ?? 0) > 0;
    if (!hasFee && !hasDeposit) return 'Lending terms: Free';
    if (hasFee && hasDeposit) {
      return 'Lending terms: Fee RM ${_formatAmount(item.feeAmount!)} + Deposit RM ${_formatAmount(item.depositAmount!)}';
    }
    if (hasFee) return 'Lending terms: Fee RM ${_formatAmount(item.feeAmount!)}';
    return 'Lending terms: Deposit RM ${_formatAmount(item.depositAmount!)}';
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
    return amount.toStringAsFixed(2);
  }
}
