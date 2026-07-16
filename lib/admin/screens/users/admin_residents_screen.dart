import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/export/resident_directory_exporter.dart';
import 'package:jirani/admin/logic/suspension_duration.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/file_download.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/utils/display_labels.dart';
import 'package:provider/provider.dart';

// Admin residents UI feature: manages resident accounts, verification overrides, notices, and exports.
class AdminResidentsScreen extends StatefulWidget {
  const AdminResidentsScreen({super.key});

  @override
  State<AdminResidentsScreen> createState() => _AdminResidentsScreenState();
}

class _AdminResidentsScreenState extends State<AdminResidentsScreen> {
  late final TextEditingController _searchController;
  String _verificationFilter = 'all';
  String _accountFilter = 'all';
  String _searchQuery = '';
  _ResidentSortMode _sortMode = _ResidentSortMode.nameAsc;
  bool _exportInProgress = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allResidents = admin.residents;
    final stats = _ResidentDirectoryStats.from(allResidents);
    final residents = _sortedResidents(_filteredResidents(allResidents));

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Resident Directory',
          subtitle:
              'Search, filter, and manage resident account health in your assigned community.',
          controls: [
            _ResidentSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            _ResidentFilterMenu(
              icon: Icons.verified_user_outlined,
              label: _verificationFilter == 'all'
                  ? 'Verification'
                  : adminStatusLabel(_verificationFilter),
              value: _verificationFilter,
              values: const {
                'all': 'All verification',
                AppConstants.verificationVerified: 'Verified',
                AppConstants.verificationRejected: 'Rejected',
                AppConstants.verificationPending: 'Pending',
                AppConstants.verificationSubmitted: 'Submitted',
              },
              onSelected: (value) =>
                  setState(() => _verificationFilter = value),
            ),
            _ResidentFilterMenu(
              icon: Icons.manage_accounts_outlined,
              label: _accountFilter == 'all'
                  ? 'Account'
                  : _accountStatusLabel(_accountFilter),
              value: _accountFilter,
              values: const {
                'all': 'All accounts',
                AppConstants.accountStatusActive: 'Active',
                AppConstants.accountStatusSuspended: 'Suspended',
                AppConstants.accountStatusArchived: 'Archived',
                AppConstants.accountStatusDeleted: 'Deleted',
              },
              onSelected: (value) => setState(() => _accountFilter = value),
            ),
            _ResidentSortMenu(
              value: _sortMode,
              onSelected: (value) => setState(() => _sortMode = value),
            ),
            TextButton.icon(
              onPressed: _hasActiveControls ? _clearControls : null,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: Text(_activeControlLabel),
            ),
            FilledButton.tonalIcon(
              onPressed: residents.isEmpty || _exportInProgress
                  ? null
                  : () => _showExportFormatPicker(residents, admin),
              icon: _exportInProgress
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_exportInProgress ? 'Exporting...' : 'Export Data'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ResidentKpiGrid(stats: stats),
        const SizedBox(height: 20),
        _ResidentChartGallery(stats: stats),
        const SizedBox(height: 20),
        AdminPanel(
          title: _directoryTitle,
          action:
              '${residents.length} of ${allResidents.length} accounts visible',
          padding: EdgeInsets.zero,
          child: _ResidentTableShell(
            isFiltering: _hasActiveControls,
            hasResidents: allResidents.isNotEmpty,
            child: residents.isEmpty
                ? AdminEmptyPanelMessage(
                    icon: _hasActiveControls
                        ? Icons.manage_search_rounded
                        : Icons.groups_2_rounded,
                    title: _hasActiveControls
                        ? 'No residents match these filters'
                        : 'No residents found',
                    body: _hasActiveControls
                        ? 'Clear the search or filters to show the full resident directory.'
                        : 'Residents in this admin community will appear after registration.',
                  )
                : _ResidentDataTable(
                    residents: residents,
                    sortMode: _sortMode,
                    onSortChanged: (value) => setState(() => _sortMode = value),
                    rowBuilder: (resident) =>
                        _residentRow(context, admin, resident),
                  ),
          ),
        ),
      ],
    );
  }

  bool get _hasActiveControls =>
      _searchQuery.trim().isNotEmpty ||
      _verificationFilter != 'all' ||
      _accountFilter != 'all';

  String get _activeControlLabel {
    final count = [
      _searchQuery.trim().isNotEmpty,
      _verificationFilter != 'all',
      _accountFilter != 'all',
    ].where((active) => active).length;
    return count == 0 ? 'Clear' : 'Clear $count';
  }

  String get _directoryTitle =>
      _hasActiveControls ? 'Filtered Residents' : 'All Residents';

  void _clearControls() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _verificationFilter = 'all';
      _accountFilter = 'all';
    });
  }

  List<AppUser> _filteredResidents(List<AppUser> residents) {
    final query = _searchQuery.trim().toLowerCase();
    return residents.where((resident) {
      if (_verificationFilter != 'all' &&
          resident.verificationStatus != _verificationFilter) {
        return false;
      }
      if (_accountFilter != 'all' && resident.accountStatus != _accountFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final searchable = [
        resident.fullName,
        resident.email,
        resident.phoneNumber,
        resident.communityName,
        resident.unitNumber,
        adminStatusLabel(resident.verificationStatus),
        _accountStatusLabel(resident.accountStatus),
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  List<AppUser> _sortedResidents(List<AppUser> residents) {
    final sorted = [...residents];
    sorted.sort((a, b) {
      return switch (_sortMode) {
        _ResidentSortMode.nameAsc => a.fullName.compareTo(b.fullName),
        _ResidentSortMode.nameDesc => b.fullName.compareTo(a.fullName),
        _ResidentSortMode.verification => _verificationRank(
          a,
        ).compareTo(_verificationRank(b)),
        _ResidentSortMode.account => _accountRank(a).compareTo(_accountRank(b)),
        _ResidentSortMode.trustDesc => b.communityTrustScore.compareTo(
          a.communityTrustScore,
        ),
        _ResidentSortMode.updatedDesc => b.updatedAt.compareTo(a.updatedAt),
      };
    });
    return sorted;
  }

  int _verificationRank(AppUser resident) {
    return switch (resident.verificationStatus) {
      AppConstants.verificationSubmitted => 0,
      AppConstants.verificationPending => 1,
      AppConstants.verificationRejected => 2,
      AppConstants.verificationVerified => 3,
      _ => 4,
    };
  }

  int _accountRank(AppUser resident) {
    return switch (resident.accountStatus) {
      AppConstants.accountStatusSuspended => 0,
      AppConstants.accountStatusArchived => 1,
      AppConstants.accountStatusActive || '' => 2,
      _ => 3,
    };
  }

  DataRow _residentRow(
    BuildContext context,
    AdminProvider admin,
    AppUser resident,
  ) {
    final accountColor = _accountStatusColor(resident.accountStatus);
    final accountLabel = _accountStatusLabel(resident.accountStatus);
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AdminColors.primary.withValues(alpha: 0.04);
        }
        return null;
      }),
      onSelectChanged: (_) => _showResidentProfile(context, resident),
      cells: [
        DataCell(
          AdminIdentityCell(
            name: resident.fullName,
            imageUrl: resident.profileImageUrl,
          ),
        ),
        DataCell(
          _TableTextStack(
            primary: resident.email,
            secondary: resident.phoneNumber.isEmpty
                ? 'No phone number'
                : resident.phoneNumber,
          ),
        ),
        DataCell(
          _TableTextStack(
            primary: resident.communityName.isEmpty
                ? 'No community'
                : resident.communityName,
            secondary: resident.unitNumber.isEmpty
                ? 'No unit'
                : resident.unitNumber,
          ),
        ),
        DataCell(
          AdminStatusPill(
            label: adminStatusLabel(resident.verificationStatus),
            color: _verificationStatusColor(resident.verificationStatus),
          ),
        ),
        DataCell(AdminStatusPill(label: accountLabel, color: accountColor)),
        DataCell(_TrustScoreCell(score: resident.communityTrustScore)),
        DataCell(
          _TableTextStack(
            primary: adminFormatDate(resident.updatedAt),
            secondary: 'Joined ${adminFormatDate(resident.createdAt)}',
          ),
        ),
        DataCell(
          PopupMenuButton<_ResidentAction>(
            tooltip: 'Resident actions',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (action) =>
                _handleResidentAction(context, admin, resident, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ResidentAction.view,
                child: _ResidentActionLabel(
                  icon: Icons.account_circle_outlined,
                  label: 'View profile',
                ),
              ),
              const PopupMenuItem(
                value: _ResidentAction.edit,
                child: _ResidentActionLabel(
                  icon: Icons.edit_outlined,
                  label: 'Edit details',
                ),
              ),
              const PopupMenuItem(
                value: _ResidentAction.notice,
                child: _ResidentActionLabel(
                  icon: Icons.campaign_outlined,
                  label: 'Send notice',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ResidentAction.resetVerification,
                child: _ResidentActionLabel(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset verification',
                ),
              ),
              const PopupMenuItem(
                value: _ResidentAction.overrideVerification,
                child: _ResidentActionLabel(
                  icon: Icons.fact_check_outlined,
                  label: 'Manual verify/reject',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: resident.isSuspended
                    ? _ResidentAction.reactivate
                    : _ResidentAction.suspend,
                child: _ResidentActionLabel(
                  icon: resident.isSuspended
                      ? Icons.lock_open_outlined
                      : Icons.block_outlined,
                  label: resident.isSuspended
                      ? 'Reactivate account'
                      : 'Suspend account',
                ),
              ),
              PopupMenuItem(
                value: resident.isArchived
                    ? _ResidentAction.unarchive
                    : _ResidentAction.archive,
                child: _ResidentActionLabel(
                  icon: resident.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  label: resident.isArchived
                      ? 'Unarchive resident'
                      : 'Archive resident',
                ),
              ),
              if (resident.isDeleted) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _ResidentAction.allowNewSignup,
                  child: _ResidentActionLabel(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Allow new signup',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Admin residents UI feature: dispatches edit/suspend/archive/reset/notice actions for one resident.
  Future<void> _handleResidentAction(
    BuildContext context,
    AdminProvider admin,
    AppUser resident,
    _ResidentAction action,
  ) async {
    final adminUid = admin.currentAdminUid ?? '';
    if (adminUid.isEmpty && action != _ResidentAction.view) {
      _showSnack(context, 'Admin account is not ready yet.');
      return;
    }

    switch (action) {
      case _ResidentAction.view:
        await _showResidentProfile(context, resident);
        return;
      case _ResidentAction.edit:
        final result = await showDialog<_ResidentEditResult>(
          context: context,
          builder: (context) => _EditResidentDialog(resident: resident),
        );
        if (result == null) return;
        final ok = await admin.updateResidentDetails(
          resident: resident,
          adminUid: adminUid,
          firstName: result.firstName,
          lastName: result.lastName,
          phoneNumber: result.phoneNumber,
          unitNumber: result.unitNumber,
          communityId: result.communityId,
          communityName: result.communityName,
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          ok ? 'Resident details updated.' : admin.errorMessage,
        );
        return;
      case _ResidentAction.notice:
        final result = await showDialog<_ResidentNoticeResult>(
          context: context,
          builder: (context) => _ResidentNoticeDialog(resident: resident),
        );
        if (result == null) return;
        final ok = await admin.sendResidentNotice(
          resident: resident,
          adminUid: adminUid,
          title: result.title,
          message: result.message,
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          ok ? 'Notice sent to resident.' : admin.errorMessage,
        );
        return;
      case _ResidentAction.resetVerification:
        final reason = await _askReason(
          context,
          title: 'Reset verification',
          label: 'Reason',
          confirmLabel: 'Reset',
        );
        if (reason == null) return;
        final ok = await admin.resetResidentVerification(
          resident: resident,
          adminUid: adminUid,
          reason: reason,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Verification reset.' : admin.errorMessage);
        return;
      case _ResidentAction.overrideVerification:
        final result = await showDialog<_VerificationOverrideResult>(
          context: context,
          builder: (context) => _VerificationOverrideDialog(resident: resident),
        );
        if (result == null) return;
        final ok = await admin.overrideResidentVerification(
          resident: resident,
          adminUid: adminUid,
          status: result.status,
          reason: result.reason,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Verification updated.' : admin.errorMessage);
        return;
      case _ResidentAction.suspend:
        final result = await showDialog<AdminSuspensionResult>(
          context: context,
          builder: (context) => AdminSuspensionDialog(resident: resident),
        );
        if (result == null) return;
        final ok = await admin.suspendResident(
          resident: resident,
          adminUid: adminUid,
          reason: result.reason,
          suspensionEndsAt: result.duration.endsAt(DateTime.now()),
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          ok
              ? 'Resident suspended: ${result.duration.label.toLowerCase()}.'
              : admin.errorMessage,
        );
        return;
      case _ResidentAction.reactivate:
        final confirmed = await _confirm(
          context,
          title: 'Reactivate account',
          body:
              'Reactivate ${resident.fullName} and remove the suspension flag?',
          confirmLabel: 'Reactivate',
        );
        if (!confirmed) return;
        final ok = await admin.reactivateResident(
          resident: resident,
          adminUid: adminUid,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Resident reactivated.' : admin.errorMessage);
        return;
      case _ResidentAction.allowNewSignup:
        final confirmed = await _confirm(
          context,
          title: 'Allow new signup',
          body:
              'Remove the suspended-email restriction for this deleted account? The person may create a completely new account.',
          confirmLabel: 'Allow Signup',
        );
        if (!confirmed) return;
        final ok = await admin.allowDeletedResidentSignup(resident: resident);
        if (!context.mounted) return;
        _showSnack(
          context,
          ok ? 'This identity may register again.' : admin.errorMessage,
        );
        return;
      case _ResidentAction.archive:
        final reason = await _askReason(
          context,
          title: 'Archive resident',
          label: 'Archive reason',
          confirmLabel: 'Archive',
        );
        if (reason == null) return;
        final ok = await admin.archiveResident(
          resident: resident,
          adminUid: adminUid,
          reason: reason,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Resident archived.' : admin.errorMessage);
        return;
      case _ResidentAction.unarchive:
        final confirmed = await _confirm(
          context,
          title: 'Unarchive resident',
          body: 'Move ${resident.fullName} back to active account status?',
          confirmLabel: 'Unarchive',
        );
        if (!confirmed) return;
        final ok = await admin.unarchiveResident(
          resident: resident,
          adminUid: adminUid,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Resident unarchived.' : admin.errorMessage);
        return;
    }
  }

  // Admin residents UI feature: opens a full resident profile summary dialog.
  Future<void> _showResidentProfile(BuildContext context, AppUser resident) {
    return showDialog<void>(
      context: context,
      builder: (context) => _ResidentProfileDialog(
        resident: resident,
        accountStatusLabel: _accountStatusLabel,
        accountStatusColor: _accountStatusColor,
        verificationStatusColor: _verificationStatusColor,
      ),
    );
  }

  // Admin residents UI feature: asks for required admin reason before account or verification actions.
  Future<String?> _askReason(
    BuildContext context, {
    required String title,
    required String label,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: label,
                errorText: errorText,
                helperText: 'Required for the admin audit trail.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) {
                    setDialogState(
                      () => errorText = 'Enter a reason before continuing.',
                    );
                    return;
                  }
                  Navigator.of(context).pop(reason);
                },
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  // Admin residents UI feature: shows confirmation dialogs before sensitive account actions.
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showExportFormatPicker(
    List<AppUser> residents,
    AdminProvider admin,
  ) async {
    final format = await showModalBottomSheet<ResidentExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Export resident data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Download the currently filtered list (${residents.length} residents).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AdminColors.muted),
                ),
                const SizedBox(height: 16),
                _ExportFormatTile(
                  icon: Icons.table_chart_rounded,
                  title: 'Excel workbook',
                  subtitle: 'Spreadsheet (.xlsx) for reporting and analysis',
                  onTap: () =>
                      Navigator.of(context).pop(ResidentExportFormat.xlsx),
                ),
                const SizedBox(height: 10),
                _ExportFormatTile(
                  icon: Icons.data_object_rounded,
                  title: 'JSON data',
                  subtitle: 'Structured export (.json) for integrations',
                  onTap: () =>
                      Navigator.of(context).pop(ResidentExportFormat.json),
                ),
                const SizedBox(height: 10),
                _ExportFormatTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF report',
                  subtitle: 'Printable table (.pdf) for records',
                  onTap: () =>
                      Navigator.of(context).pop(ResidentExportFormat.pdf),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || format == null) return;
    await _exportResidents(residents: residents, format: format, admin: admin);
  }

  // Admin residents UI feature: exports the currently filtered resident list for admin reporting.
  Future<void> _exportResidents({
    required List<AppUser> residents,
    required ResidentExportFormat format,
    required AdminProvider admin,
  }) async {
    if (_exportInProgress) return;
    setState(() => _exportInProgress = true);
    try {
      final exporter = ResidentDirectoryExporter(
        communityName: admin.communityName,
        filterSummary: _exportFilterSummary(),
      );
      final bytes = await exporter.exportBytes(
        format: format,
        residents: residents,
      );
      await saveExportedFile(
        filename: exporter.filenameFor(format),
        bytes: bytes,
      );
      if (!mounted) return;
      _showSnack(
        context,
        'Exported ${residents.length} residents as ${exporter.formatLabel(format)}.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        context,
        'Could not export residents: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _exportInProgress = false);
      }
    }
  }

  String? _exportFilterSummary() {
    final parts = <String>[];
    final query = _searchQuery.trim();
    if (query.isNotEmpty) parts.add('search="$query"');
    if (_verificationFilter != 'all') {
      parts.add('verification=${adminStatusLabel(_verificationFilter)}');
    }
    if (_accountFilter != 'all') {
      parts.add('account=${accountStatusLabel(_accountFilter)}');
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  void _showSnack(BuildContext context, String? message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Action failed.')));
  }

  String _accountStatusLabel(String status) => accountStatusLabel(status);

  Color _accountStatusColor(String status) {
    return switch (status) {
      AppConstants.accountStatusSuspended => AdminColors.danger,
      AppConstants.accountStatusArchived => AdminColors.muted,
      _ => AdminColors.primary,
    };
  }

  Color _verificationStatusColor(String status) {
    return switch (status) {
      AppConstants.verificationVerified => AdminColors.success,
      AppConstants.verificationRejected => AdminColors.danger,
      AppConstants.verificationSubmitted => const Color(0xFF7C3AED),
      AppConstants.verificationPending => AdminColors.warning,
      _ => AdminColors.muted,
    };
  }
}

enum _ResidentAction {
  view,
  edit,
  notice,
  resetVerification,
  overrideVerification,
  suspend,
  reactivate,
  archive,
  unarchive,
  allowNewSignup,
}

enum _ResidentSortMode {
  nameAsc('Name A-Z', Icons.sort_by_alpha_rounded),
  nameDesc('Name Z-A', Icons.sort_by_alpha_rounded),
  verification('Verification queue', Icons.verified_user_outlined),
  account('Account risk', Icons.manage_accounts_outlined),
  trustDesc('Trust score', Icons.speed_rounded),
  updatedDesc('Recently updated', Icons.update_rounded);

  const _ResidentSortMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _ResidentDirectoryStats {
  const _ResidentDirectoryStats({
    required this.total,
    required this.verified,
    required this.pending,
    required this.submitted,
    required this.rejected,
    required this.active,
    required this.suspended,
    required this.archived,
    required this.flagged,
    required this.profileGaps,
    required this.activeContributors,
    required this.highTrust,
    required this.lowTrust,
    required this.averageTrustScore,
  });

  factory _ResidentDirectoryStats.from(List<AppUser> residents) {
    var verified = 0;
    var pending = 0;
    var submitted = 0;
    var rejected = 0;
    var active = 0;
    var suspended = 0;
    var archived = 0;
    var flagged = 0;
    var profileGaps = 0;
    var activeContributors = 0;
    var highTrust = 0;
    var lowTrust = 0;
    var totalTrust = 0.0;

    for (final resident in residents) {
      switch (resident.verificationStatus) {
        case AppConstants.verificationVerified:
          verified++;
        case AppConstants.verificationPending:
          pending++;
        case AppConstants.verificationSubmitted:
          submitted++;
        case AppConstants.verificationRejected:
          rejected++;
      }

      switch (resident.accountStatus) {
        case AppConstants.accountStatusSuspended:
          suspended++;
        case AppConstants.accountStatusArchived:
        case AppConstants.accountStatusDeleted:
          archived++;
        default:
          active++;
      }

      if (resident.accountFlagged) flagged++;
      if (resident.phoneNumber.trim().isEmpty ||
          resident.unitNumber.trim().isEmpty ||
          resident.communityName.trim().isEmpty ||
          !resident.locationVerified) {
        profileGaps++;
      }

      final activity =
          resident.completedBorrowings +
          resident.completedLendings +
          resident.completedServices;
      if (activity > 0) activeContributors++;
      if (resident.communityTrustScore >= 4) highTrust++;
      if (resident.communityTrustScore > 0 &&
          resident.communityTrustScore < 2.5) {
        lowTrust++;
      }
      totalTrust += resident.communityTrustScore;
    }

    return _ResidentDirectoryStats(
      total: residents.length,
      verified: verified,
      pending: pending,
      submitted: submitted,
      rejected: rejected,
      active: active,
      suspended: suspended,
      archived: archived,
      flagged: flagged,
      profileGaps: profileGaps,
      activeContributors: activeContributors,
      highTrust: highTrust,
      lowTrust: lowTrust,
      averageTrustScore: residents.isEmpty ? 0 : totalTrust / residents.length,
    );
  }

  final int total;
  final int verified;
  final int pending;
  final int submitted;
  final int rejected;
  final int active;
  final int suspended;
  final int archived;
  final int flagged;
  final int profileGaps;
  final int activeContributors;
  final int highTrust;
  final int lowTrust;
  final double averageTrustScore;

  int get verificationQueue => pending + submitted;
  int get accountRisk => suspended + archived + flagged;
  int get attentionQueue => verificationQueue + accountRisk + profileGaps;
  int get verifiedRate => total == 0 ? 0 : ((verified / total) * 100).round();
  int get activeRate => total == 0 ? 0 : ((active / total) * 100).round();
}

class _ResidentKpiGrid extends StatelessWidget {
  const _ResidentKpiGrid({required this.stats});

  final _ResidentDirectoryStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminResponsiveGrid(
      minTileWidth: 220,
      children: [
        AdminKpiCard(
          title: 'Total Residents',
          value: stats.total.toString(),
          detail: '${stats.active} active accounts',
          icon: Icons.groups_2_rounded,
          color: AdminColors.primary,
        ),
        AdminKpiCard(
          title: 'Verified Rate',
          value: '${stats.verifiedRate}%',
          detail: '${stats.verified} residents verified',
          icon: Icons.verified_rounded,
          color: AdminColors.success,
        ),
        AdminKpiCard(
          title: 'Verification Queue',
          value: stats.verificationQueue.toString(),
          detail: '${stats.submitted} submitted, ${stats.pending} pending',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF7C3AED),
        ),
        AdminKpiCard(
          title: 'Account Risk',
          value: stats.accountRisk.toString(),
          detail: '${stats.flagged} flagged profiles',
          icon: Icons.shield_rounded,
          color: stats.accountRisk == 0
              ? const Color(0xFF2563EB)
              : AdminColors.danger,
        ),
      ],
    );
  }
}

class _ResidentChartGallery extends StatelessWidget {
  const _ResidentChartGallery({required this.stats});

  final _ResidentDirectoryStats stats;

  @override
  Widget build(BuildContext context) {
    return AdminResponsiveGrid(
      minTileWidth: 280,
      mainAxisExtent: 292,
      children: [
        _ResidentChartCard(
          title: 'Verification Mix',
          subtitle: '${stats.verifiedRate}% verified',
          child: _ResidentDonutChart(
            centerValue: stats.total.toString(),
            centerLabel: 'residents',
            slices: [
              _ResidentChartSlice(
                label: 'Verified',
                value: stats.verified,
                color: AdminColors.success,
              ),
              _ResidentChartSlice(
                label: 'Submitted',
                value: stats.submitted,
                color: const Color(0xFF7C3AED),
              ),
              _ResidentChartSlice(
                label: 'Pending',
                value: stats.pending,
                color: AdminColors.warning,
              ),
              _ResidentChartSlice(
                label: 'Rejected',
                value: stats.rejected,
                color: AdminColors.danger,
              ),
            ],
          ),
        ),
        _ResidentChartCard(
          title: 'Account Status',
          subtitle: '${stats.activeRate}% active',
          child: _ResidentDistributionBars(
            total: stats.total,
            entries: [
              _ResidentChartSlice(
                label: 'Active',
                value: stats.active,
                color: AdminColors.primary,
              ),
              _ResidentChartSlice(
                label: 'Suspended',
                value: stats.suspended,
                color: AdminColors.danger,
              ),
              _ResidentChartSlice(
                label: 'Archived',
                value: stats.archived,
                color: AdminColors.muted,
              ),
            ],
          ),
        ),
        _ResidentChartCard(
          title: 'Resident Health',
          subtitle: 'Avg trust ${stats.averageTrustScore.toStringAsFixed(1)}',
          child: _ResidentDistributionBars(
            total: stats.total,
            entries: [
              _ResidentChartSlice(
                label: 'High trust',
                value: stats.highTrust,
                color: AdminColors.success,
              ),
              _ResidentChartSlice(
                label: 'Active users',
                value: stats.activeContributors,
                color: const Color(0xFF2563EB),
              ),
              _ResidentChartSlice(
                label: 'Profile gaps',
                value: stats.profileGaps,
                color: AdminColors.warning,
              ),
              _ResidentChartSlice(
                label: 'Low trust',
                value: stats.lowTrust,
                color: AdminColors.danger,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResidentChartCard extends StatelessWidget {
  const _ResidentChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ResidentDonutChart extends StatelessWidget {
  const _ResidentDonutChart({
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
  });

  final List<_ResidentChartSlice> slices;
  final String centerValue;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(124),
                    painter: _ResidentDonutPainter(slices: slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerValue,
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        centerLabel,
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(width: 106, child: _ResidentLegend(entries: slices)),
      ],
    );
  }
}

class _ResidentDistributionBars extends StatelessWidget {
  const _ResidentDistributionBars({required this.total, required this.entries});

  final int total;
  final List<_ResidentChartSlice> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in entries) ...[
          _ResidentBarRow(entry: entry, total: total),
          if (entry != entries.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ResidentBarRow extends StatelessWidget {
  const _ResidentBarRow({required this.entry, required this.total});

  final _ResidentChartSlice entry;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (entry.value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              entry.value.toString(),
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 9,
            backgroundColor: AdminColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(entry.color),
          ),
        ),
      ],
    );
  }
}

class _ResidentLegend extends StatelessWidget {
  const _ResidentLegend({required this.entries});

  final List<_ResidentChartSlice> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in entries) ...[
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (entry != entries.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ResidentChartSlice {
  const _ResidentChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ResidentDonutPainter extends CustomPainter {
  const _ResidentDonutPainter({required this.slices});

  final List<_ResidentChartSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total == 0) {
      paint.color = AdminColors.border;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        0,
        math.pi * 2,
        false,
        paint,
      );
      return;
    }

    var start = -math.pi / 2;
    for (final slice in slices.where((slice) => slice.value > 0)) {
      final sweep = (slice.value / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        math.max(0.02, sweep - 0.035),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ResidentDonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _ResidentTableShell extends StatelessWidget {
  const _ResidentTableShell({
    required this.isFiltering,
    required this.hasResidents,
    required this.child,
  });

  final bool isFiltering;
  final bool hasResidents;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasResidents)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            color: AdminColors.background,
            child: Row(
              children: [
                Icon(
                  isFiltering
                      ? Icons.filter_alt_rounded
                      : Icons.table_rows_rounded,
                  size: 18,
                  color: AdminColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFiltering
                        ? 'Showing residents matching the active search and filters.'
                        : 'Showing every resident in the current admin scope.',
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        child,
      ],
    );
  }
}

class _ResidentDataTable extends StatelessWidget {
  const _ResidentDataTable({
    required this.residents,
    required this.sortMode,
    required this.onSortChanged,
    required this.rowBuilder,
  });

  final List<AppUser> residents;
  final _ResidentSortMode sortMode;
  final ValueChanged<_ResidentSortMode> onSortChanged;
  final DataRow Function(AppUser resident) rowBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingTextStyle: const TextStyle(
                color: AdminColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w500,
              ),
              headingRowColor: WidgetStateProperty.all(AdminColors.background),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 30,
              horizontalMargin: 20,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 74,
              columns: [
                DataColumn(
                  label: const Text('User'),
                  onSort: (columnIndex, ascending) => _toggleSort(
                    _ResidentSortMode.nameAsc,
                    _ResidentSortMode.nameDesc,
                  ),
                ),
                const DataColumn(label: Text('Contact')),
                const DataColumn(label: Text('Community / Unit')),
                DataColumn(
                  label: const Text('Verification'),
                  onSort: (columnIndex, ascending) =>
                      onSortChanged(_ResidentSortMode.verification),
                ),
                DataColumn(
                  label: const Text('Account'),
                  onSort: (columnIndex, ascending) =>
                      onSortChanged(_ResidentSortMode.account),
                ),
                DataColumn(
                  label: const Text('Trust'),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      onSortChanged(_ResidentSortMode.trustDesc),
                ),
                DataColumn(
                  label: const Text('Updated'),
                  onSort: (columnIndex, ascending) =>
                      onSortChanged(_ResidentSortMode.updatedDesc),
                ),
                const DataColumn(label: Text('')),
              ],
              rows: residents.map(rowBuilder).toList(),
            ),
          ),
        );
      },
    );
  }

  int? get _sortColumnIndex {
    return switch (sortMode) {
      _ResidentSortMode.nameAsc || _ResidentSortMode.nameDesc => 0,
      _ResidentSortMode.verification => 3,
      _ResidentSortMode.account => 4,
      _ResidentSortMode.trustDesc => 5,
      _ResidentSortMode.updatedDesc => 6,
    };
  }

  bool get _sortAscending {
    return switch (sortMode) {
      _ResidentSortMode.nameDesc ||
      _ResidentSortMode.trustDesc ||
      _ResidentSortMode.updatedDesc => false,
      _ => true,
    };
  }

  void _toggleSort(_ResidentSortMode ascending, _ResidentSortMode descending) {
    onSortChanged(sortMode == ascending ? descending : ascending);
  }
}

class _ResidentSearchField extends StatelessWidget {
  const _ResidentSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 312,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search residents, unit, email',
          filled: true,
          fillColor: AdminColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

class _ResidentFilterMenu extends StatelessWidget {
  const _ResidentFilterMenu({
    required this.icon,
    required this.label,
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '$label filter',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => values.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  Icon(
                    entry.key == value
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: entry.key == value
                        ? AdminColors.primary
                        : AdminColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Text(entry.value),
                ],
              ),
            ),
          )
          .toList(),
      child: _ResidentToolbarButton(
        icon: icon,
        label: label,
        selected: value != 'all',
      ),
    );
  }
}

class _ResidentSortMenu extends StatelessWidget {
  const _ResidentSortMenu({required this.value, required this.onSelected});

  final _ResidentSortMode value;
  final ValueChanged<_ResidentSortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ResidentSortMode>(
      tooltip: 'Sort residents',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => _ResidentSortMode.values
          .map(
            (entry) => PopupMenuItem<_ResidentSortMode>(
              value: entry,
              child: Row(
                children: [
                  Icon(entry.icon, size: 18, color: AdminColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.label)),
                  if (entry == value)
                    Icon(
                      Icons.check_rounded,
                      color: AdminColors.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: _ResidentToolbarButton(
        icon: Icons.sort_rounded,
        label: value.label,
        selected: true,
      ),
    );
  }
}

class _ResidentToolbarButton extends StatelessWidget {
  const _ResidentToolbarButton({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminColors.primary : AdminColors.muted;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected
            ? AdminColors.primary.withValues(alpha: 0.1)
            : AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AdminColors.primary : AdminColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: color),
        ],
      ),
    );
  }
}

class _TableTextStack extends StatelessWidget {
  const _TableTextStack({required this.primary, required this.secondary});

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrustScoreCell extends StatelessWidget {
  const _TrustScoreCell({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final normalized = (score / 5).clamp(0.0, 1.0);
    final color = score >= 4
        ? AdminColors.success
        : score > 0 && score < 2.5
        ? AdminColors.danger
        : AdminColors.primary;
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 7,
              backgroundColor: AdminColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentActionLabel extends StatelessWidget {
  const _ResidentActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(label)],
    );
  }
}

class _ResidentProfileDialog extends StatelessWidget {
  const _ResidentProfileDialog({
    required this.resident,
    required this.accountStatusLabel,
    required this.accountStatusColor,
    required this.verificationStatusColor,
  });

  final AppUser resident;
  final String Function(String status) accountStatusLabel;
  final Color Function(String status) accountStatusColor;
  final Color Function(String status) verificationStatusColor;

  @override
  Widget build(BuildContext context) {
    final activity =
        resident.completedBorrowings +
        resident.completedLendings +
        resident.completedServices;
    final warnings = <String>[
      if (resident.accountFlagged)
        resident.trustFlagReason.trim().isEmpty
            ? 'Account flagged for admin review.'
            : resident.trustFlagReason.trim(),
      if (resident.isSuspended && resident.suspendedReason.trim().isNotEmpty)
        resident.suspendedReason.trim(),
      if (resident.isSuspended)
        resident.suspensionEndsAt == null
            ? 'Suspension continues until an administrator reactivates the account.'
            : 'Suspended until ${adminFormatDate(resident.suspensionEndsAt!)}.',
      if (resident.unitNumber.trim().isEmpty) 'Unit number is missing.',
      if (!resident.locationVerified) 'Location verification is incomplete.',
    ];

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AdminColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            AdminAvatar(
              name: resident.fullName,
              imageUrl: resident.profileImageUrl,
              large: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident.fullName,
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    resident.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminStatusPill(
                    label: adminStatusLabel(resident.verificationStatus),
                    color: verificationStatusColor(resident.verificationStatus),
                  ),
                  AdminStatusPill(
                    label: accountStatusLabel(resident.accountStatus),
                    color: accountStatusColor(resident.accountStatus),
                  ),
                  AdminStatusPill(
                    label:
                        'Trust ${resident.communityTrustScore.toStringAsFixed(1)}',
                    color: resident.communityTrustScore >= 4
                        ? AdminColors.success
                        : AdminColors.primary,
                  ),
                ],
              ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ResidentWarningPanel(warnings: warnings),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AdminInfoTile(
                    label: 'Phone',
                    value: _dash(resident.phoneNumber),
                  ),
                  AdminInfoTile(
                    label: 'Community',
                    value: _dash(resident.communityName),
                  ),
                  AdminInfoTile(
                    label: 'Unit',
                    value: _dash(resident.unitNumber),
                  ),
                  AdminInfoTile(
                    label: 'Last updated',
                    value: adminFormatDate(resident.updatedAt),
                  ),
                  AdminInfoTile(
                    label: 'Borrowings',
                    value: resident.completedBorrowings.toString(),
                  ),
                  AdminInfoTile(
                    label: 'Lendings',
                    value: resident.completedLendings.toString(),
                  ),
                  AdminInfoTile(
                    label: 'Services',
                    value: resident.completedServices.toString(),
                  ),
                  AdminInfoTile(
                    label: 'Activity total',
                    value: activity.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _dash(String value) => value.trim().isEmpty ? '-' : value.trim();
}

class _ResidentWarningPanel extends StatelessWidget {
  const _ResidentWarningPanel({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AdminColors.warning),
              SizedBox(width: 8),
              Text(
                'Attention needed',
                style: TextStyle(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                warning,
                style: const TextStyle(color: AdminColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResidentEditResult {
  const _ResidentEditResult({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.unitNumber,
    required this.communityId,
    required this.communityName,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String unitNumber;
  final String communityId;
  final String communityName;
}

class _EditResidentDialog extends StatefulWidget {
  const _EditResidentDialog({required this.resident});

  final AppUser resident;

  @override
  State<_EditResidentDialog> createState() => _EditResidentDialogState();
}

class _EditResidentDialogState extends State<_EditResidentDialog> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _unit;
  late final TextEditingController _communityId;
  late final TextEditingController _communityName;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final resident = widget.resident;
    _firstName = TextEditingController(text: resident.firstName);
    _lastName = TextEditingController(text: resident.lastName);
    _phone = TextEditingController(text: resident.phoneNumber);
    _unit = TextEditingController(text: resident.unitNumber);
    _communityId = TextEditingController(text: resident.communityId);
    _communityName = TextEditingController(text: resident.communityName);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _unit.dispose();
    _communityId.dispose();
    _communityName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.resident.fullName}'),
      content: SizedBox(
        width: 580,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorText != null) ...[
              AdminInlineAlert(message: _errorText!),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dialogField(_firstName, 'First name'),
                _dialogField(_lastName, 'Last name'),
                _dialogField(_phone, 'Phone number'),
                _dialogField(_unit, 'Unit number'),
                _dialogField(_communityId, 'Community ID'),
                _dialogField(_communityName, 'Community name'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save changes')),
      ],
    );
  }

  void _save() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      setState(() => _errorText = 'First and last name are required.');
      return;
    }
    Navigator.of(context).pop(
      _ResidentEditResult(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phoneNumber: _phone.text.trim(),
        unitNumber: _unit.text.trim(),
        communityId: _communityId.text.trim(),
        communityName: _communityName.text.trim(),
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return SizedBox(
      width: 274,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class AdminSuspensionResult {
  const AdminSuspensionResult({required this.reason, required this.duration});

  final String reason;
  final SuspensionDuration duration;
}

class AdminSuspensionDialog extends StatefulWidget {
  const AdminSuspensionDialog({super.key, required this.resident});

  final AppUser resident;

  @override
  State<AdminSuspensionDialog> createState() => _AdminSuspensionDialogState();
}

class _AdminSuspensionDialogState extends State<AdminSuspensionDialog> {
  final _reason = TextEditingController();
  SuspensionDuration _duration = SuspensionDuration.sevenDays;
  String? _errorText;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Suspend ${widget.resident.fullName}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The resident will be blocked from Jirani until the selected period ends or an administrator reactivates the account.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SuspensionDuration>(
              initialValue: _duration,
              decoration: const InputDecoration(
                labelText: 'Suspension duration',
                helperText: 'Choose how long access should remain blocked.',
              ),
              items: SuspensionDuration.values
                  .map(
                    (duration) => DropdownMenuItem(
                      value: duration,
                      child: Text(duration.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _duration = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Suspension reason',
                helperText:
                    'Shown to the resident and saved in the audit trail.',
                errorText: _errorText,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.block_outlined),
          label: const Text('Suspend account'),
        ),
      ],
    );
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Enter a reason before continuing.');
      return;
    }
    Navigator.of(
      context,
    ).pop(AdminSuspensionResult(reason: reason, duration: _duration));
  }
}

class _ResidentNoticeResult {
  const _ResidentNoticeResult({required this.title, required this.message});

  final String title;
  final String message;
}

class _ResidentNoticeDialog extends StatefulWidget {
  const _ResidentNoticeDialog({required this.resident});

  final AppUser resident;

  @override
  State<_ResidentNoticeDialog> createState() => _ResidentNoticeDialogState();
}

class _ResidentNoticeDialogState extends State<_ResidentNoticeDialog> {
  final _title = TextEditingController(text: 'Message from community admin');
  final _message = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Send notice to ${widget.resident.fullName}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorText != null) ...[
              AdminInlineAlert(message: _errorText!),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send notice')),
      ],
    );
  }

  void _send() {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _errorText = 'Notice title and message are required.');
      return;
    }
    Navigator.of(context).pop(
      _ResidentNoticeResult(
        title: _title.text.trim(),
        message: _message.text.trim(),
      ),
    );
  }
}

class _VerificationOverrideResult {
  const _VerificationOverrideResult({
    required this.status,
    required this.reason,
  });

  final String status;
  final String reason;
}

class _VerificationOverrideDialog extends StatefulWidget {
  const _VerificationOverrideDialog({required this.resident});

  final AppUser resident;

  @override
  State<_VerificationOverrideDialog> createState() =>
      _VerificationOverrideDialogState();
}

class _VerificationOverrideDialogState
    extends State<_VerificationOverrideDialog> {
  late String _status;
  final _reason = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _status =
        widget.resident.verificationStatus == AppConstants.verificationVerified
        ? AppConstants.verificationRejected
        : AppConstants.verificationVerified;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manual verification for ${widget.resident.fullName}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorText != null) ...[
              AdminInlineAlert(message: _errorText!),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'New status'),
              items: const [
                DropdownMenuItem(
                  value: AppConstants.verificationVerified,
                  child: Text('Verified'),
                ),
                DropdownMenuItem(
                  value: AppConstants.verificationRejected,
                  child: Text('Rejected'),
                ),
                DropdownMenuItem(
                  value: AppConstants.verificationPending,
                  child: Text('Pending'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reason',
                helperText: 'Required for the admin audit trail.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save decision')),
      ],
    );
  }

  void _save() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Enter a reason before saving.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_VerificationOverrideResult(status: _status, reason: reason));
  }
}

class _ExportFormatTile extends StatelessWidget {
  const _ExportFormatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AdminColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
