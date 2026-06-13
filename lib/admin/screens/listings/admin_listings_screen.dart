import 'package:flutter/material.dart';
import 'package:jirani/admin/models/admin_display_rows.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/widgets/admin_listing_widgets.dart';
import 'package:jirani/admin/widgets/admin_status_widgets.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final listingRows = [
      ...admin.listings.map(adminListingRowFromItem),
      ...admin.services.map(adminListingRowFromService),
    ];
    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Marketplace & Task Listings',
          subtitle:
              'Moderate shared items, services, reported posts, and disabled content.',
          controls: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Grid'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_list_rounded),
                  label: Text('List'),
                ),
              ],
              selected: {_grid},
              onSelectionChanged: (value) =>
                  setState(() => _grid = value.first),
            ),
            const AdminFilterChipButton(label: 'Category'),
          ],
        ),
        const SizedBox(height: 20),
        if (listingRows.isEmpty)
          const AdminPanel(
            title: 'Listings',
            child: AdminEmptyPanelMessage(
              icon: Icons.storefront_rounded,
              title: 'No listings found',
              body: 'Marketplace and task listings will appear here.',
            ),
          )
        else if (_grid)
          AdminResponsiveGrid(
            minTileWidth: 260,
            mainAxisExtent: 286,
            children: listingRows
                .map((listing) => AdminListingCard(listing: listing))
                .toList(),
          )
        else
          AdminPanel(
            title: 'Listings',
            padding: EdgeInsets.zero,
            child: Column(
              children: listingRows
                  .map((listing) => AdminListingListTile(listing: listing))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
