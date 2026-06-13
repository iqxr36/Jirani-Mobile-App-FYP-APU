import 'package:flutter/material.dart';
import 'package:jirani/admin/widgets/ocr_review_dialog.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:jirani/services/ocr_parser_service.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminProvider>(
      create: (_) => AdminProvider(),
      child: _AdminDashboardView(
        onLogout: onLogout,
        isLoggingOut: isLoggingOut,
      ),
    );
  }
}

enum _AdminSection {
  overview(
    'Overview',
    'Community health at a glance',
    Icons.space_dashboard_rounded,
  ),
  verification(
    'Verification',
    'Review resident proof documents',
    Icons.verified_user_rounded,
  ),
  residents(
    'Residents',
    'Directory and account controls',
    Icons.groups_2_rounded,
  ),
  listings(
    'Listings',
    'Marketplace and task moderation',
    Icons.storefront_rounded,
  ),
  reports(
    'Reports',
    'Complaints and dispute resolution',
    Icons.report_problem_rounded,
  ),
  transactions(
    'Transactions',
    'Deposits and platform ledger',
    Icons.receipt_long_rounded,
  ),
  settings(
    'Settings',
    'Admin profile and platform preferences',
    Icons.tune_rounded,
  );

  const _AdminSection(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class _AdminColors {
  const _AdminColors._();

  static const primary = Color(0xFF006D77);
  static const secondary = Color(0xFF83C5BE);
  static const accent = Color(0xFFE29578);
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF2F855A);
  static const warning = Color(0xFFB7791F);
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView({
    required this.onLogout,
    required this.isLoggingOut,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  _AdminSection _section = _AdminSection.overview;
  String? _selectedRequestId;

  @override
  Widget build(BuildContext context) {
    final currentAdmin = context.watch<AuthViewModel>().currentAdmin;
    if (currentAdmin != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AdminProvider>().configureForAdmin(currentAdmin);
        }
      });
    }

    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final content = _AdminContent(
      section: _section,
      selectedRequestId: _selectedRequestId,
      onSelectRequest: (id) => setState(() => _selectedRequestId = id),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: _AdminColors.background,
        body: Row(
          children: [
            _AdminSidebar(
              section: _section,
              onChanged: (section) => setState(() => _section = section),
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    section: _section,
                    onLogout: widget.onLogout,
                    isLoggingOut: widget.isLoggingOut,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _AdminColors.background,
      drawer: Drawer(
        child: SafeArea(
          child: _AdminSidebar(
            section: _section,
            onChanged: (section) {
              setState(() => _section = section);
              Navigator.of(context).pop();
            },
            compact: true,
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(_section.title),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.isLoggingOut ? null : widget.onLogout,
            icon: widget.isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndexFor(_section),
        onDestinationSelected: (index) {
          setState(() => _section = _sectionForBottomIndex(index));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'Verify',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  int _bottomIndexFor(_AdminSection section) {
    return switch (section) {
      _AdminSection.overview => 0,
      _AdminSection.verification => 1,
      _AdminSection.residents => 2,
      _ => 3,
    };
  }

  _AdminSection _sectionForBottomIndex(int index) {
    return switch (index) {
      0 => _AdminSection.overview,
      1 => _AdminSection.verification,
      2 => _AdminSection.residents,
      _ => _AdminSection.listings,
    };
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.section,
    required this.onChanged,
    this.compact = false,
  });

  final _AdminSection section;
  final ValueChanged<_AdminSection> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : 280,
      decoration: const BoxDecoration(
        color: _AdminColors.surface,
        border: Border(right: BorderSide(color: _AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _AdminColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      'assets/In-app-logo-Jirani.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.apartment_rounded,
                        color: _AdminColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jirani Admin',
                        style: TextStyle(
                          color: _AdminColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Community portal',
                        style: TextStyle(color: _AdminColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _AdminSection.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _AdminSection.values[index];
                final selected = item == section;
                return Semantics(
                  selected: selected,
                  button: true,
                  child: Material(
                    color: selected
                        ? _AdminColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onChanged(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? _AdminColors.primary
                                  : _AdminColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: selected
                                      ? _AdminColors.primary
                                      : _AdminColors.ink,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _StatusNotice(
              icon: Icons.shield_moon_rounded,
              title: 'Secure mode',
              body: 'Admin actions are logged for audit history.',
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.section,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final _AdminSection section;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthViewModel>().currentAdmin;
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _AdminColors.surface,
        border: Border(bottom: BorderSide(color: _AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  section.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _AdminColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search residents, reports, listings',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _AdminColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          _AdminAvatar(name: admin?.fullName ?? 'Admin'),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign out',
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.section,
    required this.selectedRequestId,
    required this.onSelectRequest,
  });

  final _AdminSection section;
  final String? selectedRequestId;
  final ValueChanged<String> onSelectRequest;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _AdminScrollBehavior(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(section),
          child: switch (section) {
            _AdminSection.overview => const _OverviewPage(),
            _AdminSection.verification => _VerificationPage(
              selectedRequestId: selectedRequestId,
              onSelectRequest: onSelectRequest,
            ),
            _AdminSection.residents => const _ResidentDirectoryPage(),
            _AdminSection.listings => const _ListingManagementPage(),
            _AdminSection.reports => const _ReportsPage(),
            _AdminSection.transactions => const _TransactionsPage(),
            _AdminSection.settings => const _SettingsPage(),
          },
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats;
    final requests = admin.verificationRequests;
    final totalUsers = stats['totalUsers'] ?? 0;
    final submitted = stats['submittedRequests'] ?? requests.length;
    final verified = stats['verifiedResidents'] ?? 0;
    final activeListings = stats['activeListings'] ?? admin.listings.length;
    final openReports = stats['openReports'] ?? admin.reports.length;

    return _PageScroll(
      children: [
        const _CommunityScopeBanner(),
        const SizedBox(height: 20),
        _ResponsiveGrid(
          minTileWidth: 220,
          children: [
            _KpiCard(
              title: 'Total Residents',
              value: totalUsers.toString(),
              detail: '$verified verified residents',
              icon: Icons.groups_2_rounded,
              color: _AdminColors.primary,
            ),
            _KpiCard(
              title: 'Pending Verifications',
              value: submitted.toString(),
              detail: 'Awaiting admin review',
              icon: Icons.how_to_reg_rounded,
              color: _AdminColors.secondary,
            ),
            _KpiCard(
              title: 'Active Listings',
              value: activeListings.toString(),
              detail: '${admin.listings.length} total listings',
              icon: Icons.storefront_rounded,
              color: _AdminColors.success,
            ),
            _KpiCard(
              title: 'Open Reports',
              value: openReports.toString(),
              detail: 'Reports requiring review',
              icon: Icons.report_problem_rounded,
              color: _AdminColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final chart = _Panel(
              title: 'User Growth',
              action: 'Last 6 months',
              child: SizedBox(
                height: 280,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    values: const [24, 34, 49, 58, 72, 91],
                  ),
                  child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        'Jan   Feb   Mar   Apr   May   Jun',
                        style: TextStyle(
                          color: _AdminColors.muted,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final activity = _Panel(
              title: 'Recent Activity',
              action: '${requests.length} live requests',
              child: const _RecentActivityList(),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: activity),
                ],
              );
            }
            return Column(
              children: [chart, const SizedBox(height: 20), activity],
            );
          },
        ),
      ],
    );
  }
}

class _VerificationPage extends StatelessWidget {
  const _VerificationPage({
    required this.selectedRequestId,
    required this.onSelectRequest,
  });

  final String? selectedRequestId;
  final ValueChanged<String> onSelectRequest;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final requests = admin.verificationRequests;
    final selected = _selectedRequest(requests);

    if (admin.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _PageScroll(
      children: [
        const _CommunityScopeBanner(),
        const SizedBox(height: 20),
        _ControlBar(
          title: 'Pending Verification Requests',
          subtitle:
              'Approve only when document, resident identity, and community details match.',
          controls: [
            DropdownButton<String>(
              value: admin.selectedStatusFilter,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<AdminProvider>().setStatusFilter(value);
                }
              },
            ),
          ],
        ),
        if (admin.errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineAlert(message: admin.errorMessage!),
        ],
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final list = _VerificationRequestList(
              requests: requests,
              selectedId: selected?.id,
              onSelect: onSelectRequest,
            );
            final detail = _VerificationDetail(request: selected);

            if (wide) {
              return SizedBox(
                height: 650,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 340, child: list),
                    const SizedBox(width: 20),
                    Expanded(child: detail),
                  ],
                ),
              );
            }

            return Column(
              children: [
                SizedBox(height: 360, child: list),
                const SizedBox(height: 20),
                detail,
              ],
            );
          },
        ),
      ],
    );
  }

  VerificationRequest? _selectedRequest(List<VerificationRequest> requests) {
    if (requests.isEmpty) return null;
    if (selectedRequestId == null) return requests.first;
    return requests.cast<VerificationRequest?>().firstWhere(
      (request) => request?.id == selectedRequestId,
      orElse: () => requests.first,
    );
  }
}

class _ResidentDirectoryPage extends StatelessWidget {
  const _ResidentDirectoryPage();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final residents = admin.residents;
    return _PageScroll(
      children: [
        _ControlBar(
          title: 'Resident Directory',
          subtitle:
              'Search, filter, and monitor account health across communities.',
          controls: const [
            _FilterChipButton(label: 'Status'),
            _FilterChipButton(label: 'Community'),
            _TonalActionButton(
              icon: Icons.download_rounded,
              label: 'Export Data',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Panel(
          title: 'All Residents',
          action: '${residents.length} accounts',
          padding: EdgeInsets.zero,
          child: residents.isEmpty
              ? const _EmptyPanelMessage(
                  icon: Icons.groups_2_rounded,
                  title: 'No residents found',
                  body:
                      'Residents in this admin community will appear after registration.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: _AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Community')),
                      DataColumn(label: Text('Verification')),
                      DataColumn(label: Text('Account')),
                      DataColumn(label: Text('')),
                    ],
                    rows: residents
                        .map(
                          (resident) => DataRow(
                            cells: [
                              DataCell(_IdentityCell(name: resident.fullName)),
                              DataCell(Text(resident.email)),
                              DataCell(Text(resident.communityName)),
                              DataCell(
                                _StatusPill(
                                  label: _statusLabel(
                                    resident.verificationStatus,
                                  ),
                                  color: resident.isVerifiedResident
                                      ? _AdminColors.success
                                      : _AdminColors.warning,
                                ),
                              ),
                              const DataCell(
                                _StatusPill(
                                  label: 'Active',
                                  color: _AdminColors.primary,
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'More options',
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_horiz_rounded),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ListingManagementPage extends StatefulWidget {
  const _ListingManagementPage();

  @override
  State<_ListingManagementPage> createState() => _ListingManagementPageState();
}

class _ListingManagementPageState extends State<_ListingManagementPage> {
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final listingRows = [
      ...admin.listings.map(_listingRowFromItem),
      ...admin.services.map(_listingRowFromService),
    ];
    return _PageScroll(
      children: [
        _ControlBar(
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
            const _FilterChipButton(label: 'Category'),
          ],
        ),
        const SizedBox(height: 20),
        if (listingRows.isEmpty)
          const _Panel(
            title: 'Listings',
            child: _EmptyPanelMessage(
              icon: Icons.storefront_rounded,
              title: 'No listings found',
              body: 'Marketplace and task listings will appear here.',
            ),
          )
        else if (_grid)
          _ResponsiveGrid(
            minTileWidth: 260,
            mainAxisExtent: 286,
            children: listingRows
                .map((listing) => _ListingCard(listing: listing))
                .toList(),
          )
        else
          _Panel(
            title: 'Listings',
            padding: EdgeInsets.zero,
            child: Column(
              children: listingRows
                  .map((listing) => _ListingListTile(listing: listing))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AdminProvider>().reports;
    final reportRows = reports.map(_reportRowFromReport).toList();
    final selected = reportRows.isEmpty ? null : reportRows.first;
    return _PageScroll(
      children: [
        _ControlBar(
          title: 'Reports and Complaints',
          subtitle:
              'Inbox-style triage for disputes, misuse, damaged items, and evidence.',
          controls: const [
            _FilterChipButton(label: 'Priority'),
            _FilterChipButton(label: 'Open'),
          ],
        ),
        const SizedBox(height: 20),
        if (selected == null)
          const _Panel(
            title: 'Report Inbox',
            child: _EmptyPanelMessage(
              icon: Icons.report_problem_rounded,
              title: 'No reports found',
              body: 'Resident complaints and report tickets will appear here.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final inbox = _Panel(
                title: 'Report Inbox',
                padding: EdgeInsets.zero,
                child: Column(
                  children: reportRows
                      .map((report) => _ReportInboxTile(report: report))
                      .toList(),
                ),
              );
              final detail = _Panel(
                title: selected.title,
                action: selected.priority,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailSection(
                      title: 'Reporter Details',
                      lines: [selected.reporter, selected.reporterEmail],
                    ),
                    _DetailSection(
                      title: 'Reported Content/User',
                      lines: [selected.target, selected.content],
                    ),
                    _DetailSection(
                      title: 'Reason & Evidence',
                      lines: [
                        selected.description,
                        'Evidence: 3 images attached',
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Dismiss Report'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {},
                          icon: const Icon(Icons.campaign_rounded),
                          label: const Text('Issue Warning'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _AdminColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.block_rounded),
                          label: const Text('Suspend User'),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (wide) {
                return SizedBox(
                  height: 620,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 360, child: inbox),
                      const SizedBox(width: 20),
                      Expanded(child: detail),
                    ],
                  ),
                );
              }
              return Column(
                children: [inbox, const SizedBox(height: 20), detail],
              );
            },
          ),
      ],
    );
  }
}

class _TransactionsPage extends StatelessWidget {
  const _TransactionsPage();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final transactionRows = _transactionRowsFromRequests(
      admin.borrowRequests,
      admin.serviceRequests,
    );

    return _PageScroll(
      children: [
        _ControlBar(
          title: 'Transactions Monitoring',
          subtitle:
              'Audit borrow deposits, task service payments, disputes, and completion status.',
          controls: const [
            _FilterChipButton(label: 'Date Range'),
            _FilterChipButton(label: 'Type'),
            _FilterChipButton(label: 'Status'),
          ],
        ),
        const SizedBox(height: 20),
        _Panel(
          title: 'Platform Ledger',
          action: '${transactionRows.length} records',
          padding: EdgeInsets.zero,
          child: transactionRows.isEmpty
              ? const _EmptyPanelMessage(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions found',
                  body: 'Borrow and task service requests will appear here.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: _AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('Transaction ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Provider')),
                      DataColumn(label: Text('Requester')),
                      DataColumn(label: Text('Deposit')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: transactionRows
                        .map(
                          (tx) => DataRow(
                            cells: [
                              DataCell(Text(tx.id)),
                              DataCell(Text(tx.date)),
                              DataCell(Text(tx.type)),
                              DataCell(Text(tx.provider)),
                              DataCell(Text(tx.requester)),
                              DataCell(Text(tx.deposit)),
                              DataCell(
                                _StatusPill(label: tx.status, color: tx.color),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  bool _verificationAlerts = true;
  bool _weeklyDigest = true;
  bool _reportEscalations = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthViewModel>().currentAdmin;
    return _PageScroll(
      children: [
        _Panel(
          title: 'Admin Profile & Platform Settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSection(
                title: 'Personal Information',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 320
                        ? constraints.maxWidth
                        : 320.0;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _AdminAvatar(
                          name: admin?.fullName ?? 'Admin',
                          large: true,
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            initialValue: admin?.fullName ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            initialValue: admin?.email ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _SettingsSection(
                title: 'Security',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 320
                        ? constraints.maxWidth
                        : 320.0;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: const TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: const TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _SettingsSection(
                title: 'Notification Preferences',
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _verificationAlerts,
                      onChanged: (value) =>
                          setState(() => _verificationAlerts = value),
                      title: const Text('Verification request alerts'),
                      subtitle: const Text(
                        'Notify me when residents submit documents.',
                      ),
                    ),
                    SwitchListTile(
                      value: _weeklyDigest,
                      onChanged: (value) =>
                          setState(() => _weeklyDigest = value),
                      title: const Text('Weekly community digest'),
                      subtitle: const Text(
                        'Receive resident, listing, and report summaries.',
                      ),
                    ),
                    SwitchListTile(
                      value: _reportEscalations,
                      onChanged: (value) =>
                          setState(() => _reportEscalations = value),
                      title: const Text('Report escalations'),
                      subtitle: const Text(
                        'Flag high-risk complaints immediately.',
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}

class _CommunityScopeBanner extends StatelessWidget {
  const _CommunityScopeBanner();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final authUser = context.watch<AuthViewModel>().currentAdmin;
    final isSystemAdmin = admin.includeAllCommunities;
    final communityName = admin.communityName.isNotEmpty
        ? admin.communityName
        : authUser?.communityName.trim() ?? '';
    final communityId = admin.communityId.isNotEmpty
        ? admin.communityId
        : authUser?.communityId.trim() ?? '';
    final hasScope =
        isSystemAdmin ||
        communityId.trim().isNotEmpty ||
        communityName.trim().isNotEmpty;

    final title = isSystemAdmin
        ? 'System admin access'
        : hasScope
        ? 'Community admin scope'
        : 'Community assignment required';
    final body = isSystemAdmin
        ? 'You are viewing admin records across all communities.'
        : hasScope
        ? 'Showing residents and verification requests for ${communityName.isEmpty ? communityId : communityName}.'
        : 'This admin account has no communityId or communityName in Firestore, so community-scoped admin records are hidden.';
    final color = hasScope ? _AdminColors.primary : _AdminColors.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSystemAdmin
                ? Icons.admin_panel_settings_rounded
                : hasScope
                ? Icons.home_work_rounded
                : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AdminColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: _AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.minTileWidth = 240,
    this.mainAxisExtent = 188,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(20),
    this.fillChild = false,
  });

  final String title;
  final String? action;
  final Widget child;
  final EdgeInsets padding;
  final bool fillChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _AdminColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (action != null)
                  Text(
                    action!,
                    style: const TextStyle(
                      color: _AdminColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _AdminColors.border),
          if (fillChild)
            Expanded(
              child: Padding(padding: padding, child: child),
            )
          else
            Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.title,
    required this.subtitle,
    required this.controls,
  });

  final String title;
  final String subtitle;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidth = constraints.maxWidth < 420
              ? constraints.maxWidth
              : 420.0;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: titleWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _AdminColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _AdminColors.muted),
                    ),
                  ],
                ),
              ),
              Wrap(spacing: 10, runSpacing: 10, children: controls),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: _AdminColors.ink,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _AdminColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = <_ActivityRow>[
      ...admin.verificationRequests.take(4).map((request) {
        return _ActivityRow(
          icon: Icons.verified_user_rounded,
          title: 'Verification ${_statusLabel(request.status)}',
          body: '${request.fullName} from ${request.communityName}',
          time: _formatDate(request.submittedAt),
        );
      }),
      ...admin.listings.take(3).map((listing) {
        return _ActivityRow(
          icon: Icons.storefront_rounded,
          title: 'Listing ${_statusLabel(listing.status)}',
          body: '${listing.title} by ${listing.ownerName}',
          time: _formatDate(listing.createdAt),
        );
      }),
      ...admin.reports.take(3).map((report) {
        return _ActivityRow(
          icon: Icons.report_problem_rounded,
          title: report.title.isEmpty ? 'Report opened' : report.title,
          body: report.description,
          time: _formatDate(report.createdAt),
        );
      }),
    ].take(6).toList();

    if (items.isEmpty) {
      return const _EmptyPanelMessage(
        icon: Icons.history_rounded,
        title: 'No recent activity',
        body: 'Verification requests, listings, and reports will appear here.',
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _AdminColors.secondary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: _AdminColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: _AdminColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: const TextStyle(color: _AdminColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VerificationRequestList extends StatelessWidget {
  const _VerificationRequestList({
    required this.requests,
    required this.selectedId,
    required this.onSelect,
  });

  final List<VerificationRequest> requests;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Requests',
      action: requests.length.toString(),
      padding: EdgeInsets.zero,
      fillChild: true,
      child: requests.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.mark_email_read_rounded,
              title: 'No requests in this queue',
              body: 'New resident verification submissions will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = requests[index];
                final selected = request.id == selectedId;
                return Material(
                  color: selected
                      ? _AdminColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelect(request.id),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _AdminAvatar(name: request.fullName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.fullName.isEmpty
                                      ? 'Resident request'
                                      : request.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _AdminColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDate(request.submittedAt),
                                  style: const TextStyle(
                                    color: _AdminColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _VerificationDetail extends StatelessWidget {
  const _VerificationDetail({required this.request});

  final VerificationRequest? request;

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return const _Panel(
        title: 'Detail View',
        child: _EmptyPanelMessage(
          icon: Icons.description_rounded,
          title: 'Select a request',
          body:
              'Resident identity, community details, and uploaded documents show here.',
        ),
      );
    }

    final r = request!;
    final canReview =
        r.status == AppConstants.verificationSubmitted ||
        r.status == AppConstants.verificationRequestPending;
    return _Panel(
      title: r.fullName.isEmpty ? 'Resident Details' : r.fullName,
      action: r.status,
      fillChild: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _InfoTile(label: 'Email Address', value: r.email),
                _InfoTile(label: 'Phone Number', value: r.phoneNumber),
                _InfoTile(label: 'Community Name', value: r.communityName),
                _InfoTile(label: 'Unit Number', value: r.unitNumber),
              ],
            ),
            const SizedBox(height: 20),
            _ExtractedTextPanel(request: r),
            if (r.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _StatusNotice(
                icon: Icons.sticky_note_2_rounded,
                title: 'Resident Notes',
                body: r.notes,
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: canReview ? () => _approve(context, r) : null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve Verification'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _AdminColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: canReview ? () => _reject(context, r) : null,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Reject Request'),
                ),
                if (r.documentUrl.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openDocument(context, r.documentUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Document'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    VerificationRequest request,
  ) async {
    final reviewedOcrData = await _reviewOcrData(context, request);
    if (reviewedOcrData == null || !context.mounted) return;

    final adminUid = context.read<AuthViewModel>().currentAdmin?.uid ?? '';
    await context.read<AdminProvider>().approveRequest(
      request: request,
      adminUid: adminUid,
      reviewedOcrData: reviewedOcrData,
    );
    if (!context.mounted) return;
    final error = context.read<AdminProvider>().errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Verification approved.')));
  }

  Future<ExtractedDocumentData?> _reviewOcrData(
    BuildContext context,
    VerificationRequest request,
  ) {
    final structuredData = _structuredDataFromRequest(request);
    if (structuredData != null) {
      return showDialog<ExtractedDocumentData>(
        context: context,
        builder: (context) => OcrReviewDialog(initialData: structuredData),
      );
    }

    final parser = OcrParserService();
    final documentType = documentTypeFromValue(request.documentType);
    final parsedData = documentType == DocumentType.unknown
        ? parser.processOcrText(request.ocrText)
        : parser.extractByDocumentType(request.ocrText, documentType);
    return showDialog<ExtractedDocumentData>(
      context: context,
      builder: (context) => OcrReviewDialog(initialData: parsedData),
    );
  }

  ExtractedDocumentData? _structuredDataFromRequest(
    VerificationRequest request,
  ) {
    final fields = request.extractedFields;
    if (fields.isEmpty) return null;
    String? value(String key) {
      final trimmed = fields[key]?.value.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    return ExtractedDocumentData(
      type: DocumentType.tenancyAgreement,
      tenantName: value('tenant_name'),
      landlordName: value('landlord_name'),
      propertyAddress: value('property_address'),
      unitNumber: value('unit_number'),
      agreementDate: value('agreement_date'),
      fullText: request.ocrText,
    );
  }

  Future<void> _reject(
    BuildContext context,
    VerificationRequest request,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    final adminUid = context.read<AuthViewModel>().currentAdmin?.uid ?? '';
    await context.read<AdminProvider>().rejectRequest(
      request: request,
      adminUid: adminUid,
      rejectionReason: reason,
    );
    if (!context.mounted) return;
    final error = context.read<AdminProvider>().errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Verification rejected.')));
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open document link.')),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject verification'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Explain what the resident needs to fix.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _AdminColors.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Reject Request'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ExtractedTextPanel — replaces the old _DocumentViewer skeleton
// ---------------------------------------------------------------------------

class _ExtractedTextPanel extends StatelessWidget {
  const _ExtractedTextPanel({required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.ocrStatus.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AdminColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_snippet_rounded,
                color: _AdminColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _documentTypeLabel(request.documentType),
                  style: const TextStyle(
                    color: _AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(
                label: 'Text extraction',
                color: _AdminColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          switch (status) {
            AppConstants.ocrStatusPending => const _OcrStatusView(
              icon: Icons.schedule_rounded,
              message: 'OCR queued. Waiting for backend processing.',
            ),
            AppConstants.ocrStatusProcessing => const _OcrStatusView(
              icon: Icons.sync_rounded,
              message: 'OCR is processing this document.',
              showProgress: true,
            ),
            AppConstants.ocrStatusCompleted => _OcrResultView(request: request),
            AppConstants.ocrStatusFailed => _OcrStatusView(
              icon: Icons.info_outline_rounded,
              message: request.ocrError?.trim().isNotEmpty == true
                  ? request.ocrError!
                  : 'OCR failed. Open the document and review it manually.',
            ),
            _ => const _OcrStatusView(
              icon: Icons.hourglass_empty_rounded,
              message: 'OCR has not started for this request yet.',
            ),
          },
        ],
      ),
    );
  }
}

class _OcrStatusView extends StatelessWidget {
  const _OcrStatusView({
    required this.icon,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Icon(icon, color: _AdminColors.muted, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _AdminColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrResultView extends StatelessWidget {
  const _OcrResultView({required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final text = request.ocrText.trim();
    final fullTextOnly = _usesFullTextOnly(request.documentType);
    final structuredFields = _structuredFieldEntries(request);
    final Map<String, String> parsedFields;
    if (structuredFields.isNotEmpty) {
      parsedFields = const <String, String>{};
    } else if (fullTextOnly) {
      parsedFields = const <String, String>{};
    } else if (_shouldParseDisplayFields(request)) {
      parsedFields = _parseDisplayFields(request);
    } else {
      parsedFields = request.ocrFields;
    }
    final visibleFields = Map<String, String>.from(parsedFields)
      ..remove('type')
      ..remove('fullText');
    final showFullText =
        fullTextOnly || (visibleFields.isEmpty && structuredFields.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (structuredFields.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: structuredFields
                .map(
                  (e) => _OcrFieldChip(
                    label: e.label,
                    value: e.field.value,
                    confidence: e.field.confidence,
                    highlight: e.field.confidence < 0.75,
                  ),
                )
                .toList(),
          ),
        ] else if (visibleFields.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleFields.entries
                .map((e) => _OcrFieldChip(label: e.key, value: e.value))
                .toList(),
          ),
        ],
        if (showFullText) ...[
          if (visibleFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: _AdminColors.border),
            const SizedBox(height: 12),
          ],
          const Text(
            'FULL EXTRACTED TEXT',
            style: TextStyle(
              color: _AdminColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _AdminColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text.isEmpty ? 'No text was saved by OCR.' : text,
                style: const TextStyle(
                  color: _AdminColors.ink,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldParseDisplayFields(VerificationRequest request) {
    if (request.ocrText.trim().isEmpty) return false;
    return request.documentType == AppConstants.documentTypeTenancyAgreement ||
        request.documentType == AppConstants.documentTypeUtilityBill;
  }

  bool _usesFullTextOnly(String documentType) {
    return documentType == AppConstants.documentTypeAccessCard ||
        documentType == AppConstants.documentTypeOtherProof;
  }

  Map<String, String> _parseDisplayFields(VerificationRequest request) {
    final text = request.ocrText.trim();
    if (text.isEmpty) return const {};
    final parser = OcrParserService();
    final parsed = switch (request.documentType) {
      AppConstants.documentTypeTenancyAgreement =>
        parser.extractTenancyAgreement(text),
      AppConstants.documentTypeUtilityBill => parser.extractUtilityBill(text),
      AppConstants.documentTypeOtherProof => parser.extractOtherProof(text),
      _ => parser.processOcrText(text),
    };
    return parsed.toFieldMap();
  }

  List<_StructuredFieldEntry> _structuredFieldEntries(
    VerificationRequest request,
  ) {
    const labels = <String, String>{
      'tenant_name': 'Tenant Name',
      'landlord_name': 'Landlord/Owner Name',
      'unit_number': 'Unit Number',
      'agreement_date': 'Agreement Date',
      'property_address': 'Property Address',
    };
    return labels.entries
        .map((entry) {
          final field = request.extractedFields[entry.key];
          if (field == null || field.value.trim().isEmpty) return null;
          return _StructuredFieldEntry(label: entry.value, field: field);
        })
        .whereType<_StructuredFieldEntry>()
        .toList();
  }
}

class _OcrFieldChip extends StatelessWidget {
  const _OcrFieldChip({
    required this.label,
    required this.value,
    this.confidence,
    this.highlight = false,
  });

  final String label;
  final String value;
  final double? confidence;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? _AdminColors.warning : _AdminColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_ocrFieldLabel(label)}: ',
                  style: const TextStyle(
                    color: _AdminColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _AdminColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(height: 3),
            Text(
              'Confidence ${(confidence! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _AdminColors.muted,
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StructuredFieldEntry {
  const _StructuredFieldEntry({required this.label, required this.field});

  final String label;
  final ExtractedVerificationField field;
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final _ListingRow listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _surfaceDecoration(),
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
                          _AdminColors.secondary.withValues(alpha: 0.65),
                          _AdminColors.primary.withValues(alpha: 0.9),
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
                      foregroundColor: _AdminColors.accent,
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
                          color: _AdminColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(label: listing.status, color: listing.color),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${listing.category} by ${listing.owner}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _AdminColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingListTile extends StatelessWidget {
  const _ListingListTile({required this.listing});

  final _ListingRow listing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _AdminColors.secondary.withValues(alpha: 0.25),
        foregroundColor: _AdminColors.primary,
        child: Icon(listing.icon),
      ),
      title: Text(listing.title),
      subtitle: Text('${listing.category} by ${listing.owner}'),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusPill(label: listing.status, color: listing.color),
          IconButton(
            tooltip: 'Remove listing',
            onPressed: () {},
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _AdminColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportInboxTile extends StatelessWidget {
  const _ReportInboxTile({required this.report});

  final _ReportRow report;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 14,
      leading: _PriorityDot(priority: report.priority),
      title: Text(
        report.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${report.reporter} - ${report.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(color: _AdminColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AdminColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 24),
          const Divider(color: _AdminColors.border),
        ],
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _AdminColors.secondary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _AdminColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: _AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AdminColors.accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _AdminColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: _AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCell extends StatelessWidget {
  const _IdentityCell({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AdminAvatar(name: name),
        const SizedBox(width: 10),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.name, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: large ? 34 : 18,
      backgroundColor: _AdminColors.primary,
      foregroundColor: Colors.white,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: large ? 24 : 14,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_list_rounded),
      label: Text(label),
    );
  }
}

class _TonalActionButton extends StatelessWidget {
  const _TonalActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _AdminColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AdminColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _AdminColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priority == 'High'
        ? _AdminColors.accent
        : priority == 'Med'
        ? _AdminColors.warning
        : _AdminColors.success;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(priority, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = _AdminColors.border
      ..strokeWidth = 1;
    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          _AdminColors.secondary.withValues(alpha: 0.28),
          _AdminColors.secondary.withValues(alpha: 0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    final paintLine = Paint()
      ..color = _AdminColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = _AdminColors.primary;

    final chartHeight = size.height - 28;
    for (var i = 0; i < 5; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1 : max - min;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y =
          chartHeight - ((values[i] - min) / range * (chartHeight - 18)) - 8;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _AdminScrollBehavior extends ScrollBehavior {
  const _AdminScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

BoxDecoration _surfaceDecoration() {
  return BoxDecoration(
    color: _AdminColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _AdminColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _documentTypeLabel(String value) {
  return switch (value) {
    AppConstants.documentTypeUtilityBill => 'Utility bill',
    AppConstants.documentTypeTenancyAgreement => 'Tenancy agreement',
    AppConstants.documentTypeAccessCard => 'Access card',
    AppConstants.documentTypeOtherProof => 'Other proof',
    _ => value.trim().isEmpty ? 'Residency document' : value,
  };
}

String _ocrFieldLabel(String value) {
  return switch (value) {
    'type' => 'Document Type',
    'tenantName' => 'Tenant Name',
    'landlordName' => 'Landlord Name',
    'propertyAddress' => 'Property Address',
    'unitNumber' => 'Unit Number',
    'agreementDate' => 'Agreement Date',
    'billType' => 'Bill Type',
    'amount' => 'Amount',
    'billDate' => 'Bill Date',
    'cardNumber' => 'Card Number',
    'fullText' => 'Full OCR Text',
    _ => value,
  };
}

String _statusLabel(String value) {
  if (value.trim().isEmpty) return 'Unknown';
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

_ListingRow _listingRowFromItem(ItemModel item) {
  return _ListingRow(
    title: item.title.isEmpty ? 'Untitled listing' : item.title,
    category: _statusLabel(item.category),
    owner: item.ownerName.isEmpty ? item.ownerEmail : item.ownerName,
    status: _statusLabel(item.status),
    icon: _categoryIcon(item.category),
    color: _statusColor(item.status),
  );
}

_ListingRow _listingRowFromService(ServiceModel service) {
  return _ListingRow(
    title: service.title.isEmpty ? 'Untitled service' : service.title,
    category: 'Task service',
    owner: service.providerName.isEmpty
        ? service.providerEmail
        : service.providerName,
    status: _statusLabel(service.status),
    icon: _categoryIcon(service.category),
    color: _statusColor(service.status),
  );
}

_ReportRow _reportRowFromReport(ReportModel report) {
  final priority = switch (report.type) {
    AppConstants.reportTypeDamagedItem ||
    AppConstants.reportTypeLostItem ||
    AppConstants.reportTypeDepositDispute => 'High',
    AppConstants.reportTypeUserMisconduct => 'Med',
    _ => 'Low',
  };
  return _ReportRow(
    title: report.title.isEmpty ? _statusLabel(report.type) : report.title,
    priority: priority,
    reporter: report.reporterName.isEmpty
        ? report.reporterId
        : report.reporterName,
    reporterEmail: report.reporterId,
    target: report.reportedUserName.isEmpty
        ? report.reportedUserId
        : report.reportedUserName,
    content: report.itemId.isEmpty
        ? report.relatedBorrowRequestId
        : 'Item ${report.itemId}',
    description: report.description.isEmpty
        ? 'No description provided.'
        : report.description,
  );
}

List<_TransactionRow> _transactionRowsFromRequests(
  List<BorrowRequest> borrowRequests,
  List<ServiceRequestModel> serviceRequests,
) {
  final rows = <_TransactionRow>[
    ...borrowRequests.map((request) {
      final depositAmount = request.hasDeposit ? request.depositAmount ?? 0 : 0;
      return _TransactionRow(
        id: _shortRecordId('BR', request.id),
        date: _formatDate(request.createdAt),
        type: 'Borrow',
        provider: request.ownerName.isEmpty ? 'Owner' : request.ownerName,
        requester: request.borrowerName.isEmpty
            ? 'Requester'
            : request.borrowerName,
        deposit: 'RM ${depositAmount.toStringAsFixed(0)}',
        status: _statusLabel(request.status),
        color: _statusColor(request.status),
        createdAt: request.createdAt,
      );
    }),
    ...serviceRequests.map((request) {
      return _TransactionRow(
        id: _shortRecordId('SR', request.id),
        date: _formatDate(request.createdAt),
        type: 'Task Service',
        provider: request.providerName.isEmpty
            ? 'Provider'
            : request.providerName,
        requester: request.requesterName.isEmpty
            ? 'Requester'
            : request.requesterName,
        deposit: 'RM 0',
        status: _statusLabel(request.status),
        color: _statusColor(request.status),
        createdAt: request.createdAt,
      );
    }),
  ];

  rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
}

String _shortRecordId(String prefix, String id) {
  if (id.isEmpty) return '$prefix-NEW';
  final compact = id.length > 6 ? id.substring(0, 6) : id;
  return '$prefix-${compact.toUpperCase()}';
}

IconData _categoryIcon(String category) {
  return switch (category) {
    AppConstants.itemCategoryTools => Icons.handyman_rounded,
    AppConstants.itemCategoryKitchen => Icons.blender_rounded,
    AppConstants.itemCategoryElectronics => Icons.devices_rounded,
    AppConstants.itemCategoryCleaning => Icons.cleaning_services_rounded,
    AppConstants.itemCategoryStudy => Icons.menu_book_rounded,
    AppConstants.serviceCategoryTutoring => Icons.school_rounded,
    AppConstants.serviceCategoryRepair => Icons.build_rounded,
    AppConstants.serviceCategoryDelivery => Icons.local_shipping_rounded,
    AppConstants.serviceCategoryPetCare => Icons.pets_rounded,
    _ => Icons.inventory_2_rounded,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    AppConstants.itemStatusAvailable ||
    AppConstants.serviceStatusActive ||
    AppConstants.reportStatusResolved ||
    AppConstants.borrowStatusCompleted ||
    AppConstants.serviceRequestStatusCompleted => _AdminColors.success,
    AppConstants.reportStatusOpen ||
    AppConstants.reportStatusUnderReview ||
    AppConstants.borrowStatusPending ||
    AppConstants.serviceRequestStatusPending => _AdminColors.warning,
    AppConstants.itemStatusArchived ||
    AppConstants.reportStatusDismissed ||
    AppConstants.borrowStatusRejected ||
    AppConstants.serviceRequestStatusRejected => _AdminColors.accent,
    _ => _AdminColors.primary,
  };
}

class _ActivityRow {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
}

class _ListingRow {
  const _ListingRow({
    required this.title,
    required this.category,
    required this.owner,
    required this.status,
    required this.icon,
    required this.color,
  });

  final String title;
  final String category;
  final String owner;
  final String status;
  final IconData icon;
  final Color color;
}

class _ReportRow {
  const _ReportRow({
    required this.title,
    required this.priority,
    required this.reporter,
    required this.reporterEmail,
    required this.target,
    required this.content,
    required this.description,
  });

  final String title;
  final String priority;
  final String reporter;
  final String reporterEmail;
  final String target;
  final String content;
  final String description;
}

class _TransactionRow {
  const _TransactionRow({
    required this.id,
    required this.date,
    required this.type,
    required this.provider,
    required this.requester,
    required this.deposit,
    required this.status,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String date;
  final String type;
  final String provider;
  final String requester;
  final String deposit;
  final String status;
  final Color color;
  final DateTime createdAt;
}
