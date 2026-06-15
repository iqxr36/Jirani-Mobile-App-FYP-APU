import 'package:flutter/material.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/auth/email_verification_view.dart';
import 'package:jirani/views/auth/phone_verification_view.dart';
import 'package:jirani/views/verification/verification_process_view.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF8E8E93);
const double _kMaxContentWidth = 350;
const int _kMaxProfileImageBytes = 5 * 1024 * 1024;

class ResidentProfileView extends StatefulWidget {
  const ResidentProfileView({super.key});

  @override
  State<ResidentProfileView> createState() => _ResidentProfileViewState();
}

class _ResidentProfileViewState extends State<ResidentProfileView> {
  final _imagePicker = ImagePicker();
  bool _darkTheme = false;
  bool _pushNotifications = true;
  bool _locationAlerts = true;
  bool _profileImageSaving = false;

  void _openVerificationProcess() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const VerificationProcessView()),
    );
  }

  void _openEmailVerification(AppUser user) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EmailVerificationView(
          email: user.email,
          sendLinkOnOpen: true,
          onVerified: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openPhoneVerification(AppUser user) {
    final phone = user.phoneNumber.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a phone number before verifying.')),
      );
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PhoneVerificationView(phoneNumber: phone),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an image under 5 MB for your profile photo.'),
        ),
      );
      return;
    }

    setState(() => _profileImageSaving = true);
    final auth = context.read<AuthViewModel>();
    final success = await auth.updateResidentProfileImage(
      bytes: bytes,
      originalFileName: picked.name,
    );
    if (!mounted) return;
    setState(() => _profileImageSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile photo updated.'
              : auth.errorMessage ?? 'Could not update profile photo.',
        ),
      ),
    );
  }

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is not available yet.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(
                    user: user,
                    onEditProfile: () => _showUnavailable('Edit Profile'),
                    onChangePhoto: user == null ? null : _changeProfileImage,
                    isPhotoUpdating: _profileImageSaving,
                    onVerificationStatus: _openVerificationProcess,
                    onVerifyEmail: user == null || user.emailVerified
                        ? null
                        : () => _openEmailVerification(user),
                    onVerifyPhone: user == null || user.phoneVerified
                        ? null
                        : () => _openPhoneVerification(user),
                    onMyItems: () => _showUnavailable('My Items'),
                    onRatings: () => _showUnavailable('Ratings & Reviews'),
                    onMyServices: () => _showUnavailable('My Services'),
                    onLogout: _logout,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    darkTheme: _darkTheme,
                    pushNotifications: _pushNotifications,
                    locationAlerts: _locationAlerts,
                    onDarkThemeChanged: (value) =>
                        setState(() => _darkTheme = value),
                    onPushNotificationsChanged: (value) =>
                        setState(() => _pushNotifications = value),
                    onLocationAlertsChanged: (value) =>
                        setState(() => _locationAlerts = value),
                    onPrivacy: () => _showUnavailable('Privacy'),
                    onLanguage: () => _showUnavailable('Language'),
                    onPaymentMethods: () => _showUnavailable('Payment Methods'),
                    onHelp: () => _showUnavailable('Help & Support'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.onEditProfile,
    required this.onChangePhoto,
    required this.isPhotoUpdating,
    required this.onVerificationStatus,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
    required this.onMyItems,
    required this.onRatings,
    required this.onMyServices,
    required this.onLogout,
  });

  final AppUser? user;
  final VoidCallback onEditProfile;
  final VoidCallback? onChangePhoto;
  final bool isPhotoUpdating;
  final VoidCallback onVerificationStatus;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;
  final VoidCallback onMyItems;
  final VoidCallback onRatings;
  final VoidCallback onMyServices;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Neighbor';
    final community = user?.communityName.trim().isNotEmpty == true
        ? user!.communityName.trim().toUpperCase()
        : 'COMMUNITY';
    final unit = user?.unitNumber.trim().isNotEmpty == true
        ? user!.unitNumber.trim()
        : '-';
    final status = _VerificationStatus.from(user?.verificationStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _VerificationChip(status: status),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _ProfileAvatar(
                  user: user,
                  onTap: onChangePhoto,
                  isLoading: isPhotoUpdating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    community,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                Flexible(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricChip(
                value: '${user?.completedBorrowings ?? 0}',
                label: 'Borrowed',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                value: '${user?.completedLendings ?? 0}',
                label: 'Lent',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                value: '${user?.completedServices ?? 0}',
                label: 'Services',
              ),
            ],
          ),
          const SizedBox(height: 17),
          _IdentityVerificationPanel(
            user: user,
            onVerifyEmail: onVerifyEmail,
            onVerifyPhone: onVerifyPhone,
          ),
          const SizedBox(height: 17),
          Divider(
            height: 1,
            thickness: 2,
            color: Colors.black.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 17),
          _ProfileMenuRow(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: onEditProfile,
          ),
          _ProfileMenuRow(
            icon: Icons.verified_user_outlined,
            label: 'Verification Status',
            onTap: onVerificationStatus,
          ),
          _ProfileMenuRow(
            icon: Icons.inventory_2_outlined,
            label: 'My Items',
            onTap: onMyItems,
          ),
          _ProfileMenuRow(
            icon: Icons.star_border_rounded,
            label: 'Ratings & Reviews',
            onTap: onRatings,
          ),
          _ProfileMenuRow(
            icon: Icons.article_outlined,
            label: 'My Services',
            onTap: onMyServices,
          ),
          _ProfileMenuRow(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: const Color(0xFFB00020),
            onTap: onLogout,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _VerificationStatus {
  const _VerificationStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _VerificationStatus.from(String? status) {
    switch (status) {
      case 'verified':
        return const _VerificationStatus(
          label: 'Verified',
          color: Color(0xFF34C759),
          icon: Icons.check_rounded,
        );
      case 'submitted':
        return const _VerificationStatus(
          label: 'In Review',
          color: Color(0xFFFFB020),
          icon: Icons.hourglass_bottom_rounded,
        );
      case 'rejected':
        return const _VerificationStatus(
          label: 'Rejected',
          color: Color(0xFFE5484D),
          icon: Icons.priority_high_rounded,
        );
      default:
        return const _VerificationStatus(
          label: 'Pending',
          color: _kBrandTeal,
          icon: Icons.lock_outline_rounded,
        );
    }
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.status});

  final _VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 4, right: 9),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: status.color.withValues(alpha: 0.22),
            child: Icon(status.icon, size: 11, color: status.color),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityVerificationPanel extends StatelessWidget {
  const _IdentityVerificationPanel({
    required this.user,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
  });

  final AppUser? user;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;

  @override
  Widget build(BuildContext context) {
    final email = user?.email.trim() ?? '';
    final phone = user?.phoneNumber.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _IdentityVerificationRow(
            icon: Icons.mark_email_read_outlined,
            title: 'Email Address',
            value: email.isEmpty ? 'No email saved' : email,
            verified: user?.emailVerified ?? false,
            actionLabel: 'Verify now',
            onTap: onVerifyEmail,
          ),
          Divider(height: 14, color: Colors.black.withValues(alpha: 0.08)),
          _IdentityVerificationRow(
            icon: Icons.sms_outlined,
            title: 'Phone Number',
            value: phone.isEmpty ? 'No phone saved' : phone,
            verified: user?.phoneVerified ?? false,
            actionLabel: phone.isEmpty ? 'Add first' : 'Verify now',
            onTap: onVerifyPhone,
          ),
        ],
      ),
    );
  }
}

class _IdentityVerificationRow extends StatelessWidget {
  const _IdentityVerificationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.verified,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool verified;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = verified ? const Color(0xFF34C759) : _kBrandTeal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: verified ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'Verified' : actionLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _kMutedText,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.onTap,
    required this.isLoading,
  });

  final AppUser? user;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profileImageUrl.trim() ?? '';

    return Semantics(
      button: onTap != null,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCDE8EC),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kBrandTeal.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: _kBrandTeal,
                            size: 62,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_outline_rounded,
                              color: _kBrandTeal,
                              size: 62,
                            ),
                          ),
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.34),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kBrandTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 41,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 32, color: color),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1.5,
            color: Colors.black.withValues(alpha: 0.16),
          ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.darkTheme,
    required this.pushNotifications,
    required this.locationAlerts,
    required this.onDarkThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onLocationAlertsChanged,
    required this.onPrivacy,
    required this.onLanguage,
    required this.onPaymentMethods,
    required this.onHelp,
  });

  final bool darkTheme;
  final bool pushNotifications;
  final bool locationAlerts;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final ValueChanged<bool> onLocationAlertsChanged;
  final VoidCallback onPrivacy;
  final VoidCallback onLanguage;
  final VoidCallback onPaymentMethods;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsSwitchRow(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            value: pushNotifications,
            onChanged: onPushNotificationsChanged,
          ),
          _SettingsSwitchRow(
            icon: Icons.location_on_outlined,
            label: 'Location Alerts',
            value: locationAlerts,
            onChanged: onLocationAlertsChanged,
          ),
          _SettingsSwitchRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Theme',
            value: darkTheme,
            onChanged: onDarkThemeChanged,
          ),
          _SettingsActionRow(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy & Safety',
            onTap: onPrivacy,
          ),
          _SettingsActionRow(
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: 'English',
            onTap: onLanguage,
          ),
          _SettingsActionRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment Methods',
            onTap: onPaymentMethods,
          ),
          _SettingsActionRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: onHelp,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: icon,
      label: label,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: _kBrandTeal,
        activeTrackColor: _kBrandTeal.withValues(alpha: 0.24),
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: icon,
      label: label,
      onTap: onTap,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 24),
        ],
      ),
    );
  }
}

class _SettingsBaseRow extends StatelessWidget {
  const _SettingsBaseRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: row,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
      ],
    );
  }
}
