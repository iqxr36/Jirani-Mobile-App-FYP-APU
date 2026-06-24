import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';

class AdminListingCard extends StatelessWidget {
  const AdminListingCard({super.key, required this.listing});

  final AdminListingRow listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: adminSurfaceDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
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
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton.filled(
                    tooltip: 'Remove listing',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AdminColors.accent,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline_rounded),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminListingListTile extends StatelessWidget {
  const AdminListingListTile({super.key, required this.listing});

  final AdminListingRow listing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
            tooltip: 'Remove listing',
            onPressed: () {},
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AdminColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
