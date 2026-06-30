import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:provider/provider.dart';

// Admin residents UI feature: manages resident accounts, verification overrides, notices, and exports.
class AdminResidentsScreen extends StatefulWidget {
  const AdminResidentsScreen({super.key});

  @override
  State<AdminResidentsScreen> createState() => _AdminResidentsScreenState();
}

class _AdminResidentsScreenState extends State<AdminResidentsScreen> {
  String _verificationFilter = 'all';
  String _accountFilter = 'all';
  String _communityFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final residents = _filteredResidents(admin.residents);
    final communities = admin.residents
        .map((resident) => resident.communityName.trim())
        .where((community) => community.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Resident Directory',
          subtitle:
              'Search, filter, and manage resident account health across communities.',
          controls: [
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
              },
              onSelected: (value) => setState(() => _accountFilter = value),
            ),
            _ResidentFilterMenu(
              icon: Icons.home_work_outlined,
              label: _communityFilter == 'all' ? 'Community' : _communityFilter,
              value: _communityFilter,
              values: {
                'all': 'All communities',
                for (final community in communities) community: community,
              },
              onSelected: (value) => setState(() => _communityFilter = value),
            ),
            FilledButton.tonalIcon(
              onPressed: residents.isEmpty ? null : () => _exportResidents(residents),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export Data'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdminPanel(
          title: 'All Residents',
          action: '${residents.length} accounts',
          padding: EdgeInsets.zero,
          child: residents.isEmpty
              ? const AdminEmptyPanelMessage(
                  icon: Icons.groups_2_rounded,
                  title: 'No residents found',
                  body:
                      'Residents in this admin community will appear after registration.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Community')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Verification')),
                      DataColumn(label: Text('Account')),
                      DataColumn(label: Text('')),
                    ],
                    rows: residents
                        .map((resident) => _residentRow(context, admin, resident))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  List<AppUser> _filteredResidents(List<AppUser> residents) {
    return residents.where((resident) {
      if (_verificationFilter != 'all' &&
          resident.verificationStatus != _verificationFilter) {
        return false;
      }
      if (_accountFilter != 'all' && resident.accountStatus != _accountFilter) {
        return false;
      }
      if (_communityFilter != 'all' &&
          resident.communityName.trim() != _communityFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  DataRow _residentRow(
    BuildContext context,
    AdminProvider admin,
    AppUser resident,
  ) {
    final accountColor = _accountStatusColor(resident.accountStatus);
    final accountLabel = _accountStatusLabel(resident.accountStatus);
    return DataRow(
      cells: [
        DataCell(AdminIdentityCell(name: resident.fullName)),
        DataCell(Text(resident.email)),
        DataCell(Text(resident.phoneNumber.isEmpty ? '-' : resident.phoneNumber)),
        DataCell(Text(resident.communityName)),
        DataCell(Text(resident.unitNumber.isEmpty ? '-' : resident.unitNumber)),
        DataCell(
          AdminStatusPill(
            label: adminStatusLabel(resident.verificationStatus),
            color: resident.isVerifiedResident
                ? AdminColors.success
                : resident.verificationStatus == AppConstants.verificationRejected
                ? AdminColors.warning
                : AdminColors.muted,
          ),
        ),
        DataCell(AdminStatusPill(label: accountLabel, color: accountColor)),
        DataCell(
          PopupMenuButton<_ResidentAction>(
            tooltip: 'Resident actions',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (action) => _handleResidentAction(
              context,
              admin,
              resident,
              action,
            ),
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
        _showSnack(context, ok ? 'Resident details updated.' : admin.errorMessage);
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
        _showSnack(context, ok ? 'Notice sent to resident.' : admin.errorMessage);
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
        final reason = await _askReason(
          context,
          title: 'Suspend account',
          label: 'Suspension reason',
          confirmLabel: 'Suspend',
        );
        if (reason == null) return;
        final ok = await admin.suspendResident(
          resident: resident,
          adminUid: adminUid,
          reason: reason,
        );
        if (!context.mounted) return;
        _showSnack(context, ok ? 'Resident suspended.' : admin.errorMessage);
        return;
      case _ResidentAction.reactivate:
        final confirmed = await _confirm(
          context,
          title: 'Reactivate account',
          body: 'Reactivate ${resident.fullName} and remove the suspension flag?',
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
  Future<void> _showResidentProfile(
    BuildContext context,
    AppUser resident,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resident.fullName),
        content: SizedBox(
          width: 620,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminInfoTile(label: 'Email', value: resident.email),
              AdminInfoTile(label: 'Phone', value: resident.phoneNumber),
              AdminInfoTile(label: 'Community', value: resident.communityName),
              AdminInfoTile(label: 'Unit', value: resident.unitNumber),
              AdminInfoTile(
                label: 'Verification',
                value: adminStatusLabel(resident.verificationStatus),
              ),
              AdminInfoTile(
                label: 'Account',
                value: _accountStatusLabel(resident.accountStatus),
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
                label: 'Trust score',
                value: resident.communityTrustScore.toStringAsFixed(1),
              ),
              if (resident.suspendedReason.trim().isNotEmpty)
                AdminInfoTile(
                  label: 'Suspension reason',
                  value: resident.suspendedReason,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Admin residents UI feature: asks for required admin reason before account or verification actions.
  Future<String?> _askReason(
    BuildContext context, {
    required String title,
    required String label,
    required String confirmLabel,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(context).pop(reason);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
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

  // Admin residents UI feature: exports the currently filtered resident list for admin reporting.
  void _exportResidents(List<AppUser> residents) {
    final csv = [
      'Name,Email,Phone,Community,Unit,Verification,Account',
      ...residents.map((resident) {
        return [
          resident.fullName,
          resident.email,
          resident.phoneNumber,
          resident.communityName,
          resident.unitNumber,
          adminStatusLabel(resident.verificationStatus),
          _accountStatusLabel(resident.accountStatus),
        ].map(_csvCell).join(',');
      }),
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    _showSnack(context, 'Resident CSV copied to clipboard.');
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _showSnack(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Action failed.')),
    );
  }

  String _accountStatusLabel(String status) {
    return switch (status) {
      AppConstants.accountStatusSuspended => 'Suspended',
      AppConstants.accountStatusArchived => 'Archived',
      _ => 'Active',
    };
  }

  Color _accountStatusColor(String status) {
    return switch (status) {
      AppConstants.accountStatusSuspended => AdminColors.danger,
      AppConstants.accountStatusArchived => AdminColors.muted,
      _ => AdminColors.primary,
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
}

class _ResidentActionLabel extends StatelessWidget {
  const _ResidentActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
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
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => values.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon),
        label: Text(label),
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
        width: 560,
        child: Wrap(
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_firstName.text.trim().isEmpty ||
                _lastName.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _ResidentEditResult(
                firstName: _firstName.text,
                lastName: _lastName.text,
                phoneNumber: _phone.text,
                unitNumber: _unit.text,
                communityId: _communityId.text,
                communityName: _communityName.text,
              ),
            );
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
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
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _ResidentNoticeResult(
                title: _title.text,
                message: _message.text,
              ),
            );
          },
          child: const Text('Send notice'),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    _status = widget.resident.verificationStatus ==
            AppConstants.verificationVerified
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
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reason.text.trim();
            if (reason.isEmpty) return;
            Navigator.of(context).pop(
              _VerificationOverrideResult(status: _status, reason: reason),
            );
          },
          child: const Text('Save decision'),
        ),
      ],
    );
  }
}
