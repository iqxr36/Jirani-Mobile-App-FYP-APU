import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';

class AdminListingCard extends StatelessWidget {
  const AdminListingCard({
    super.key,
    required this.listing,
    required this.onOpen,
    required this.onArchive,
    required this.onRestore,
  });

  final AdminListingRow listing;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: adminSurfaceDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _ListingHero(listing: listing)),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton.filled(
                          tooltip: listing.canRestore
                              ? 'Restore listing'
                              : 'Remove listing',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: listing.canRestore
                                ? AdminColors.primary
                                : AdminColors.accent,
                          ),
                          onPressed: listing.canRestore
                              ? onRestore
                              : onArchive,
                          icon: Icon(
                            listing.canRestore
                                ? Icons.restore_rounded
                                : Icons.delete_outline_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AdminStatusPill(
                            label: listing.status,
                            color: listing.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${listing.category} by ${listing.owner}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.isItem
                            ? '${listing.priceLabel} - ${listing.depositLabel}'
                            : '${listing.priceLabel} - ${listing.availabilityLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminListingListTile extends StatelessWidget {
  const AdminListingListTile({
    super.key,
    required this.listing,
    required this.onOpen,
    required this.onArchive,
    required this.onRestore,
  });

  final AdminListingRow listing;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpen,
      leading: CircleAvatar(
        backgroundColor: AdminColors.secondary.withValues(alpha: 0.25),
        foregroundColor: AdminColors.primary,
        child: Icon(listing.icon),
      ),
      title: Text(listing.title),
      subtitle: Text('${listing.category} by ${listing.owner}'),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AdminStatusPill(label: listing.status, color: listing.color),
          IconButton(
            tooltip: listing.canRestore ? 'Restore listing' : 'Remove listing',
            onPressed: listing.canRestore ? onRestore : onArchive,
            icon: Icon(
              listing.canRestore
                  ? Icons.restore_rounded
                  : Icons.delete_outline_rounded,
              color: listing.canRestore
                  ? AdminColors.primary
                  : AdminColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminListingDetailDialog extends StatelessWidget {
  const AdminListingDetailDialog({
    super.key,
    required this.listing,
    required this.onArchive,
    required this.onRestore,
  });

  final AdminListingRow listing;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${listing.isItem ? 'Marketplace item' : 'Task service'} - ${listing.category}',
                            style: const TextStyle(color: AdminColors.muted),
                          ),
                        ],
                      ),
                    ),
                    AdminStatusPill(
                      label: listing.status,
                      color: listing.color,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _ListingHero(listing: listing),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AdminInfoTile(label: 'Owner/provider', value: listing.owner),
                    AdminInfoTile(label: 'Owner ID', value: listing.ownerId),
                    AdminInfoTile(label: 'Price', value: listing.priceLabel),
                    if (listing.isItem)
                      AdminInfoTile(
                        label: 'Deposit',
                        value: listing.depositLabel,
                      ),
                    if (listing.conditionLabel.isNotEmpty)
                      AdminInfoTile(
                        label: 'Condition',
                        value: listing.conditionLabel,
                      ),
                    if (listing.availabilityLabel.isNotEmpty)
                      AdminInfoTile(
                        label: 'Availability',
                        value: listing.availabilityLabel,
                      ),
                    AdminInfoTile(
                      label: 'Community',
                      value: listing.communityName,
                    ),
                    AdminInfoTile(
                      label: 'Created',
                      value: adminFormatDate(listing.createdAt),
                    ),
                    AdminInfoTile(
                      label: 'Updated',
                      value: adminFormatDate(listing.updatedAt),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description.trim().isEmpty
                      ? 'No description provided.'
                      : listing.description,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: listing.canRestore ? onRestore : onArchive,
                      icon: Icon(
                        listing.canRestore
                            ? Icons.restore_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      label: Text(
                        listing.canRestore
                            ? 'Restore listing'
                            : 'Remove from residents',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingHero extends StatelessWidget {
  const _ListingHero({required this.listing});

  final AdminListingRow listing;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrls.isEmpty ? '' : listing.imageUrls.first;
    if (imageUrl.trim().isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _ListingFallbackHero(listing: listing),
      );
    }
    return _ListingFallbackHero(listing: listing);
  }
}

class _ListingFallbackHero extends StatelessWidget {
  const _ListingFallbackHero({required this.listing});

  final AdminListingRow listing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminColors.secondary.withValues(alpha: 0.65),
            AdminColors.primary.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        listing.icon,
        color: Colors.white.withValues(alpha: 0.8),
        size: 72,
      ),
    );
  }
}
