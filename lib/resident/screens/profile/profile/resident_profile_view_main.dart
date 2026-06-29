part of '../resident_profile_view.dart';

class ResidentProfileView extends StatefulWidget {
  const ResidentProfileView({super.key});

  @override
  State<ResidentProfileView> createState() => _ResidentProfileViewState();
}

class _ResidentProfileViewState extends State<ResidentProfileView> {
  final _imagePicker = ImagePicker();
  final _permissionRepository = VerificationPermissionRepository();
  bool _pushNotifications = true;
  bool _locationAlerts = true;
  bool _profileImageSaving = false;
  bool _loadedNotificationPreference = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedNotificationPreference) return;
    _loadedNotificationPreference = true;
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final enabled = snap.data()?['notificationEnabled'];
    if (!mounted) return;
    if (enabled is bool) {
      setState(() => _pushNotifications = enabled);
    }
  }

  Future<void> _setPushNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    try {
      await _permissionRepository.updateNotificationEnabled(enabled: value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pushNotifications = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update notification settings.')),
      );
    }
  }

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

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ResidentSettingsView(
              darkTheme: themeProvider.isDarkMode,
              pushNotifications: _pushNotifications,
              locationAlerts: _locationAlerts,
              onDarkThemeChanged: themeProvider.setDarkMode,
              onPushNotificationsChanged: _setPushNotifications,
              onLocationAlertsChanged: (value) =>
                  setState(() => _locationAlerts = value),
              onPrivacy: () => _showUnavailable('Privacy'),
              onLanguage: () => _showUnavailable('Language'),
              onPaymentMethods: _openPaymentMethods,
              onHelp: () => _showUnavailable('Help & Support'),
            );
          },
        ),
      ),
    );
  }

  void _openMyItems() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentMyItemsView()),
    );
  }

  void _openRatings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentReviewsView()),
    );
  }

  void _openPaymentMethods() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PaymentMethodsView()),
    );
  }

  void _openEditProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentEditProfileView()),
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
                  _ProfileStatsBuilder(
                    user: user,
                    builder: (context, counts) {
                      return _ProfileCard(
                        user: user,
                        marketplaceCounts: counts,
                        onEditProfile: _openEditProfile,
                        onChangePhoto: user == null
                            ? null
                            : _changeProfileImage,
                        isPhotoUpdating: _profileImageSaving,
                        onVerificationStatus: _openVerificationProcess,
                        onVerifyEmail: user == null || user.emailVerified
                            ? null
                            : () => _openEmailVerification(user),
                        onVerifyPhone: user == null || user.phoneVerified
                            ? null
                            : () => _openPhoneVerification(user),
                        onMyItems: _openMyItems,
                        onRatings: _openRatings,
                        onMyServices: () => _showUnavailable('My Services'),
                        onSettings: _openSettings,
                        onLogout: _logout,
                      );
                    },
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
