import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_listing_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:provider/provider.dart';

// Admin listings UI feature: shows and moderates marketplace and service listings visible to the current admin scope.
class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _grid = true;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allRows = [
      ...admin.listings.map(adminListingRowFromItem),
      ...admin.services.map(adminListingRowFromService),
    ];
    final listingRows = _filteredRows(allRows);
    final statuses = _uniqueValues(allRows.map((row) => row.status));
    final categories = _uniqueValues(allRows.map((row) => row.category));

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Marketplace & Task Listings',
          subtitle:
              'Moderate shared items, services, reported posts, and disabled content.',
          controls: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search listings',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _AdminListingDropdown(
              value: _typeFilter,
              values: const {
                'all': 'All types',
                'items': 'Marketplace',
                'services': 'Services',
              },
              onChanged: (value) => setState(() => _typeFilter = value),
            ),
            _AdminListingDropdown(
              value: _statusFilter,
              values: {'all': 'All statuses', for (final v in statuses) v: v},
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
            _AdminListingDropdown(
              value: _categoryFilter,
              values: {
                'all': 'All categories',
                for (final v in categories) v: v,
              },
              onChanged: (value) => setState(() => _categoryFilter = value),
            ),
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
            minTileWidth: 280,
            mainAxisExtent: 320,
            children: listingRows
                .map(
                  (listing) => AdminListingCard(
                    listing: listing,
                    onOpen: () => _openListing(listing),
                    onArchive: () => _confirmModeration(listing, restore: false),
                    onRestore: () => _confirmModeration(listing, restore: true),
                  ),
                )
                .toList(),
          )
        else
          AdminPanel(
            title: 'Listings',
            padding: EdgeInsets.zero,
            child: Column(
              children: listingRows
                  .map(
                    (listing) => AdminListingListTile(
                      listing: listing,
                      onOpen: () => _openListing(listing),
                      onArchive: () =>
                          _confirmModeration(listing, restore: false),
                      onRestore: () =>
                          _confirmModeration(listing, restore: true),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  List<AdminListingRow> _filteredRows(List<AdminListingRow> rows) {
    final query = _searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final matchesType = _typeFilter == 'all' ||
          (_typeFilter == 'items' && row.isItem) ||
          (_typeFilter == 'services' && row.isService);
      final matchesStatus =
          _statusFilter == 'all' || row.status == _statusFilter;
      final matchesCategory =
          _categoryFilter == 'all' || row.category == _categoryFilter;
      final matchesSearch = query.isEmpty ||
          row.title.toLowerCase().contains(query) ||
          row.owner.toLowerCase().contains(query) ||
          row.category.toLowerCase().contains(query) ||
          row.description.toLowerCase().contains(query);
      return matchesType && matchesStatus && matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> _uniqueValues(Iterable<String> values) {
    final set = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  void _openListing(AdminListingRow listing) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AdminListingDetailDialog(
        listing: listing,
        onArchive: () {
          Navigator.of(dialogContext).pop();
          _confirmModeration(listing, restore: false);
        },
        onRestore: () {
          Navigator.of(dialogContext).pop();
          _confirmModeration(listing, restore: true);
        },
      ),
    );
  }

  Future<void> _confirmModeration(
    AdminListingRow listing, {
    required bool restore,
  }) async {
    final admin = context.read<AdminProvider>();
    final adminUid = admin.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) {
      _showSnack('Admin session is missing. Please sign in again.');
      return;
    }

    final reason = await _askForReason(
      title: restore ? 'Restore listing' : 'Remove listing',
      message: restore
          ? 'Explain why this listing should be visible again.'
          : 'Explain why this listing should be hidden from residents.',
    );
    if (reason == null) return;

    final ok = switch (listing.type) {
      AdminListingType.marketplaceItem when restore =>
        listing.item == null
            ? false
            : await admin.restoreMarketplaceItem(
                item: listing.item!,
                adminUid: adminUid,
                reason: reason,
              ),
      AdminListingType.marketplaceItem =>
        listing.item == null
            ? false
            : await admin.archiveMarketplaceItem(
                item: listing.item!,
                adminUid: adminUid,
                reason: reason,
              ),
      AdminListingType.taskService when restore =>
        listing.service == null
            ? false
            : await admin.restoreTaskService(
                service: listing.service!,
                adminUid: adminUid,
                reason: reason,
              ),
      AdminListingType.taskService =>
        listing.service == null
            ? false
            : await admin.archiveTaskService(
                service: listing.service!,
                adminUid: adminUid,
                reason: reason,
              ),
    };

    if (!mounted) return;
    _showSnack(
      ok
          ? restore
              ? 'Listing restored.'
              : 'Listing removed from residents.'
          : admin.errorMessage ?? 'Listing moderation failed.',
    );
  }

  Future<String?> _askForReason({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Admin reason',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Reason is required.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AdminListingDropdown extends StatelessWidget {
  const _AdminListingDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        initialValue: values.containsKey(value) ? value : values.keys.first,
        isDense: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        items: [
          for (final entry in values.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
