import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/theme/admin_theme_preset.dart';
import 'package:jirani/admin/logic/theme/admin_button_styles.dart';
import 'package:jirani/admin/providers/admin_theme_provider.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/admin_notification_preferences.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const int _kMaxProfileImageBytes = 5 * 1024 * 1024;

// Admin settings UI feature: manages admin profile, security, and notification preferences.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _initialized = false;
  bool _profileImageSaving = false;
  bool _passwordSending = false;
  bool _settingsSaving = false;
  Uint8List? _localProfilePreview;
  bool _verificationAlerts = true;
  bool _reportEscalations = true;
  bool _serviceDisputeAlerts = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncAdmin(AdminUser? admin) {
    if (_initialized || admin == null) return;
    _initialized = true;
    _fullNameController.text = admin.fullName;
    _phoneController.text = admin.phoneNumber;
    final prefs = admin.notificationPreferences;
    _verificationAlerts = prefs.verificationAlerts;
    _reportEscalations = prefs.reportEscalations;
    _serviceDisputeAlerts = prefs.serviceDisputeAlerts;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminColors.danger : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _validateOptionalPhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    return Validators.validatePhone(value);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? helper,
    Widget? suffix,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      suffixIcon: suffix,
      filled: true,
      fillColor: readOnly ? AdminColors.background : AdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AdminColors.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AdminColors.border.withValues(alpha: 0.7)),
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    if (_profileImageSaving) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 82,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > _kMaxProfileImageBytes) {
      _showSnack(
        'Choose an image under 5 MB for your profile photo.',
        isError: true,
      );
      return;
    }

    setState(() {
      _localProfilePreview = bytes;
      _profileImageSaving = true;
    });

    final auth = context.read<AuthViewModel>();
    final success = await auth.updateAdminProfileImage(
      bytes: bytes,
      originalFileName: picked.name,
    );
    if (!mounted) return;
    setState(() {
      _profileImageSaving = false;
      _localProfilePreview = null;
    });
    _showSnack(
      success
          ? 'Profile photo updated.'
          : auth.errorMessage ?? 'Could not update profile photo.',
      isError: !success,
    );
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_settingsSaving) return;

    setState(() => _settingsSaving = true);
    final auth = context.read<AuthViewModel>();
    final prefs = AdminNotificationPreferences(
      verificationAlerts: _verificationAlerts,
      reportEscalations: _reportEscalations,
      serviceDisputeAlerts: _serviceDisputeAlerts,
      weeklyDigest:
          auth.currentAdmin?.notificationPreferences.weeklyDigest ?? false,
    );
    final success = await auth.updateAdminProfileSettings(
      fullName: _fullNameController.text,
      phoneNumber: _phoneController.text,
      notificationPreferences: prefs,
    );
    if (!mounted) return;
    setState(() => _settingsSaving = false);
    if (success) {
      _showSnack('Settings saved.');
    } else {
      _showSnack(
        auth.errorMessage ?? 'Could not save settings.',
        isError: true,
      );
    }
  }

  Future<void> _sendPasswordReset(AdminUser admin) async {
    if (_passwordSending) return;
    setState(() => _passwordSending = true);
    final auth = context.read<AuthViewModel>();
    await auth.sendPasswordResetEmail(admin.email);
    if (!mounted) return;
    setState(() => _passwordSending = false);
    _showSnack(
      auth.errorMessage == null
          ? 'Password reset link sent to ${admin.email}.'
          : auth.errorMessage!,
      isError: auth.errorMessage != null,
    );
  }

  Future<void> _copyUserId(String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));
    if (!mounted) return;
    _showSnack('User ID copied.');
  }

  void _handleProfileImageRenderError(Object error) {
    if (!mounted) return;
    context.read<AuthViewModel>().reportAdminProfileImageRenderFailure(error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeProvider = context.watch<AdminThemeProvider>();
    final admin = auth.currentAdmin;
    _syncAdmin(admin);

    return AdminPageScroll(
      children: [
        if (admin == null)
          AdminPanel(
            title: 'Admin Profile & Platform Settings',
            child: const Text('Sign in again to manage your admin settings.'),
          )
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminProfileHeroCard(
                  admin: admin,
                  previewBytes:
                      _localProfilePreview ?? auth.adminProfileImageBytes,
                  isLoading: _profileImageSaving,
                  onChangePhoto: _changeProfileImage,
                  onImageError: _handleProfileImageRenderError,
                ),
                if (admin.profileImageUrl.trim().isNotEmpty &&
                    auth.adminProfileImageErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  AdminInlineAlert(message: auth.adminProfileImageErrorMessage!),
                ],
                const SizedBox(height: 20),
                _AdminSettingsCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final fieldWidth = isWide
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _fullNameController,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[A-Za-z\s'-]"),
                                ),
                                LengthLimitingTextInputFormatter(60),
                              ],
                              decoration: _fieldDecoration(label: 'Display name'),
                              validator: Validators.validateFullName,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _phoneController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(
                                label: 'Phone number',
                                hint: '+60...',
                                helper: 'Optional contact for other admins.',
                              ),
                              validator: _validateOptionalPhone,
                            ),
                          ),
                          SizedBox(
                            width: isWide ? constraints.maxWidth : fieldWidth,
                            child: TextFormField(
                              initialValue: admin.email,
                              readOnly: true,
                              decoration: _fieldDecoration(
                                label: 'Email',
                                helper:
                                    'Email is your login. Use Security below to manage access.',
                                readOnly: true,
                                suffix: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: AdminColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _AdminSettingsCard(
                  icon: Icons.badge_outlined,
                  title: 'Account',
                  child: _AdminAccountContextCard(
                    admin: admin,
                    onCopyUserId: () => _copyUserId(admin.uid),
                  ),
                ),
                const SizedBox(height: 16),
                _AdminSettingsCard(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AdminColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: AdminColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'We never store your password here. Request a secure reset link by email.',
                          style: TextStyle(
                            color: AdminColors.muted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _passwordSending ? null : () => _sendPasswordReset(admin),
                          style: AdminButtonStyles.primaryOutlined(context),
                          icon: _passwordSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.mail_outline_rounded),
                          label: const Text('Email me a password reset link'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AdminSettingsCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Preferences',
                  subtitle: 'Choose which admin alerts you want to receive.',
                  child: Column(
                    children: [
                      _AdminNotificationTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Verification request alerts',
                        subtitle: 'Notify me when residents submit documents.',
                        value: _verificationAlerts,
                        onChanged: (value) =>
                            setState(() => _verificationAlerts = value),
                      ),
                      _AdminNotificationTile(
                        icon: Icons.report_gmailerrorred_outlined,
                        title: 'Report escalations',
                        subtitle: 'Flag high-risk complaints immediately.',
                        value: _reportEscalations,
                        onChanged: (value) =>
                            setState(() => _reportEscalations = value),
                      ),
                      _AdminNotificationTile(
                        icon: Icons.gavel_outlined,
                        title: 'Service dispute alerts',
                        subtitle:
                            'Notify me when residents dispute service payments.',
                        value: _serviceDisputeAlerts,
                        onChanged: (value) =>
                            setState(() => _serviceDisputeAlerts = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _AdminSettingsCard(
                  icon: Icons.palette_outlined,
                  title: 'Portal theme',
                  subtitle: 'Choose the accent color for the admin dashboard.',
                  child: _AdminThemePicker(
                    selectedId: themeProvider.presetId,
                    presets: themeProvider.presets,
                    onSelected: themeProvider.setPreset,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _settingsSaving || auth.isLoading ? null : _saveSettings,
                  style: AdminButtonStyles.primaryFilled(context),
                  icon: _settingsSaving || auth.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _settingsSaving || auth.isLoading ? 'Saving...' : 'Save Changes',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdminProfileHeroCard extends StatelessWidget {
  const _AdminProfileHeroCard({
    required this.admin,
    required this.previewBytes,
    required this.isLoading,
    required this.onChangePhoto,
    required this.onImageError,
  });

  final AdminUser admin;
  final Uint8List? previewBytes;
  final bool isLoading;
  final VoidCallback onChangePhoto;
  final void Function(Object error) onImageError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.primary,
            AdminColors.primary.withValues(alpha: 0.88),
            AdminColors.secondary.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Change admin profile photo',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : onChangePhoto,
                      customBorder: const CircleBorder(),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 3,
                              ),
                            ),
                            child: AdminAvatar(
                              name: admin.fullName,
                              imageUrl: admin.profileImageUrl,
                              previewBytes: previewBytes,
                              large: true,
                              onImageError: onImageError,
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AdminColors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_camera_outlined,
                                    size: 17,
                                    color: AdminColors.primary,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        admin.roleLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.assignedCommunityLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLoading ? 'Uploading photo...' : 'Tap photo to update',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
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
        ],
      ),
    );
  }
}

class _AdminSettingsCard extends StatelessWidget {
  const _AdminSettingsCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: adminSurfaceDecoration().copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AdminColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AdminAccountContextCard extends StatelessWidget {
  const _AdminAccountContextCard({
    required this.admin,
    required this.onCopyUserId,
  });

  final AdminUser admin;
  final VoidCallback onCopyUserId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _AdminFactTile(
              width: tileWidth,
              label: 'Role',
              value: admin.roleLabel,
              icon: Icons.workspace_premium_outlined,
            ),
            _AdminFactTile(
              width: tileWidth,
              label: 'Assigned community',
              value: admin.assignedCommunityLabel,
              icon: Icons.apartment_outlined,
            ),
            _AdminFactTile(
              width: tileWidth,
              label: 'Account status',
              value: admin.isActive ? 'Active' : 'Inactive',
              icon: Icons.check_circle_outline_rounded,
              valueColor: admin.isActive ? AdminColors.success : AdminColors.danger,
            ),
            _AdminUserIdTile(
              width: constraints.maxWidth,
              uid: admin.uid,
              onCopy: onCopyUserId,
            ),
          ],
        );
      },
    );
  }
}

class _AdminFactTile extends StatelessWidget {
  const _AdminFactTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AdminColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value.trim().isEmpty ? '-' : value,
                    style: TextStyle(
                      color: valueColor ?? AdminColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserIdTile extends StatelessWidget {
  const _AdminUserIdTile({
    required this.width,
    required this.uid,
    required this.onCopy,
  });

  final double width;
  final String uid;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User ID',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    uid,
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy user ID',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    backgroundColor: AdminColors.surface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  const _AdminNotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AdminColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? AdminColors.ink : AdminColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AdminColors.primary,
          ),
        ],
      ),
    );
  }
}

class _AdminThemePicker extends StatelessWidget {
  const _AdminThemePicker({
    required this.selectedId,
    required this.presets,
    required this.onSelected,
  });

  final String selectedId;
  final List<AdminThemePreset> presets;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final preset in presets)
              SizedBox(
                width: tileWidth,
                child: _AdminThemeOptionTile(
                  preset: preset,
                  selected: preset.id == selectedId,
                  onTap: () => onSelected(preset.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminThemeOptionTile extends StatelessWidget {
  const _AdminThemeOptionTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AdminThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label} theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? preset.primary : AdminColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: preset.primary.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [preset.primary, preset.secondary],
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: TextStyle(
                          color: AdminColors.ink,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _swatchLabel(preset.id),
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontSize: 12,
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

  String _swatchLabel(String id) {
    return switch (id) {
      'darkPurple' => 'Rich purple accents',
      'maroon' => 'Warm maroon accents',
      'darkBlue' => 'Deep blue accents',
      _ => 'Default teal accents',
    };
  }
}
