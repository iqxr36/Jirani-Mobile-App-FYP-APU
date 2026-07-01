part of '../resident_profile_view.dart';

// Resident profile feature: main profile hub for verification, listings, reviews, payment methods, settings, and logout.
class ResidentProfileView extends StatefulWidget {
  const ResidentProfileView({super.key});

  @override
  State<ResidentProfileView> createState() => _ResidentProfileViewState();
}

class _ResidentProfileViewState extends State<ResidentProfileView> {
  final _imagePicker = ImagePicker();
  final _permissionRepository = VerificationPermissionRepository();
  bool _pushNotifications = true;
  bool _profileImageSaving = false;
  bool _loadedNotificationPreference = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedNotificationPreference) return;
    _loadedNotificationPreference = true;
    _loadNotificationPreference();
  }

  // Resident profile feature: reads saved push-notification preference for the profile toggle.
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

  // Resident profile feature: updates push-notification preference and rolls back the toggle on failure.
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

  // Resident verification feature: opens the residency verification flow from the profile card.
  void _openVerificationProcess() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const VerificationProcessView()),
    );
  }

  // Resident verification feature: opens email verification and returns to profile after success.
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

  // Resident verification feature: opens phone verification if the resident has a saved phone number.
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

  // Resident settings feature: opens settings with callbacks wired back to profile state/providers.
  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ResidentSettingsView(
              darkTheme: themeProvider.isDarkMode,
              pushNotifications: _pushNotifications,
              onDarkThemeChanged: themeProvider.setDarkMode,
              onPushNotificationsChanged: _setPushNotifications,
              onPrivacy: () => _showUnavailable('Privacy'),
              onPaymentMethods: _openPaymentMethods,
              onHelp: () => _showUnavailable('Help & Support'),
            );
          },
        ),
      ),
    );
  }

  // Marketplace lender feature: opens the resident's lender dashboard and item listings.
  void _openMyItems() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentMyItemsView()),
    );
  }

  // Review feature: opens the resident's reviews and Community Trust Score screen.
  void _openRatings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentReviewsView()),
    );
  }

  // Payments feature: opens the resident payment information screen.
  void _openPaymentMethods() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PaymentMethodsView()),
    );
  }

  // Resident profile feature: opens editable personal profile details.
  void _openEditProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ResidentEditProfileView()),
    );
  }

  // Authentication feature: signs the resident out from the profile menu.
  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
  }

  // Resident profile feature: picks, validates, uploads, and saves a new profile photo.
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

  // Resident profile feature: shows a placeholder message for not-yet-built profile destinations.
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
