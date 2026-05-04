import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/item_model.dart';
import 'package:fyp_flutter_application/widgets/status_chip.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.trailing,
  });

  final ItemModel item;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = _lendingSubtitle(item);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemImage(url: item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_labelCategory(item.category)} • ${_labelCondition(item.condition)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.ownerName.isEmpty ? 'Unknown owner' : item.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.ownerVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    StatusChip(status: item.status),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  static String _labelCategory(String value) {
    switch (value) {
      case AppConstants.itemCategoryTools:
        return 'Tools';
      case AppConstants.itemCategoryKitchen:
        return 'Kitchen';
      case AppConstants.itemCategoryElectronics:
        return 'Electronics';
      case AppConstants.itemCategoryCleaning:
        return 'Cleaning';
      case AppConstants.itemCategoryStudy:
        return 'Study';
      case AppConstants.itemCategoryEventItems:
        return 'Event Items';
      case AppConstants.itemCategoryOther:
        return 'Other';
      default:
        return value;
    }
  }

  static String _labelCondition(String value) {
    switch (value) {
      case AppConstants.itemConditionNew:
        return 'New';
      case AppConstants.itemConditionGood:
        return 'Good';
      case AppConstants.itemConditionUsed:
        return 'Used';
      default:
        return value;
    }
  }

  static String _lendingSubtitle(ItemModel item) {
    switch (item.lendingType) {
      case AppConstants.lendingTypeSmallFee:
        return 'Small fee: RM ${item.feeAmount?.toStringAsFixed(0) ?? '0'}';
      case AppConstants.lendingTypeDepositRequired:
        return 'Deposit: RM ${item.depositAmount?.toStringAsFixed(0) ?? '0'}';
      default:
        return 'Free lending';
    }
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 84,
        height: 84,
        child: (url == null || url!.isEmpty)
            ? Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_outlined),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
      ),
    );
  }
}
