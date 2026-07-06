import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;
const int _kMaxProfileImageBytes = 5 * 1024 * 1024;

class ResidentEditProfileView extends StatefulWidget {
  const ResidentEditProfileView({super.key});

  @override
  State<ResidentEditProfileView> createState() =>
      _ResidentEditProfileViewState();
}

class _ResidentEditProfileViewState extends State<ResidentEditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;
  bool _photoSaving = false;
  bool _passwordSending = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncUser(AppUser? user) {
    if (_initialized || user == null) return;
    _initialized = true;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
  }

  Future<void> _changePhoto() async {
    if (_photoSaving) return;
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
      _showSnack('Choose an image under 5 MB for your profile photo.');
      return;
    }

    setState(() => _photoSaving = true);
    final auth = context.read<AuthViewModel>();
    final success = await auth.updateResidentProfileImage(
      bytes: bytes,
      originalFileName: picked.name,
    );
    if (!mounted) return;
    setState(() => _photoSaving = false);
    _showSnack(
      success ? 'Profile photo updated.' : auth.errorMessage ?? 'Could not update profile photo.',
    );
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthViewModel>();
    final authEmail =
        (auth.firebaseUser?.email ?? auth.currentUser?.email ?? '').trim();
    final previousEmail = authEmail.isNotEmpty
        ? authEmail.toLowerCase()
        : (auth.currentUser?.email.trim().toLowerCase() ?? '');
    final nextEmail = _emailController.text.trim().toLowerCase();
    final emailChanged = nextEmail.isNotEmpty && nextEmail != previousEmail;
    final success = await auth.updateResidentProfileBasics(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
    );
    if (!mounted) return;
    if (!success) {
      _showSnack(auth.errorMessage ?? 'Could not update profile.');
      return;
    }
    if (emailChanged) {
      final pendingEmail = _emailController.text.trim();
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm your new email'),
            content: Text(
              'We sent a confirmation link to $pendingEmail. '
              'Open that email and tap the link. Your profile will keep showing '
              'your current address until you confirm.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
    } else {
      _showSnack('Profile updated.');
    }
    Navigator.of(context).pop();
  }

  Future<void> _sendPasswordReset(AppUser user) async {
    if (_passwordSending) return;
    setState(() => _passwordSending = true);
    final auth = context.read<AuthViewModel>();
    await auth.sendPasswordResetEmail(user.email);
    if (!mounted) return;
    setState(() => _passwordSending = false);
    _showSnack(
      auth.errorMessage == null
          ? 'Password reset link sent to ${user.email}.'
          : auth.errorMessage!,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    _syncUser(user);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EditProfileHeader(),
                    const SizedBox(height: 18),
                    if (user == null)
                      const _EditPanel(
                        child: Text('Sign in again to edit your profile.'),
                      )
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EditPanel(
                              child: Column(
                                children: [
                                  _EditableAvatar(
                                    user: user,
                                    saving: _photoSaving,
                                    onTap: _changePhoto,
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _firstNameController,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r"[A-Za-z\s'-]"),
                                      ),
                                      LengthLimitingTextInputFormatter(60),
                                    ],
                                    decoration: context.residentInputDecoration(
                                      label: 'First name',
                                      hint: 'Enter first name',
                                    ),
                                    validator: Validators.validateFirstName,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _lastNameController,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r"[A-Za-z\s'-]"),
                                      ),
                                      LengthLimitingTextInputFormatter(60),
                                    ],
                                    decoration: context.residentInputDecoration(
                                      label: 'Last name',
                                      hint: 'Enter last name',
                                    ),
                                    validator: Validators.validateLastName,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: context.residentInputDecoration(
                                      label: 'Email',
                                      hint: 'name@example.com',
                                    ),
                                    validator: Validators.validateEmail,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.hasPendingEmailChange
                                        ? 'Waiting for confirmation at ${user.pendingEmail}.'
                                        : 'Changing email sends a confirmation link to the new address.',
                                    style: TextStyle(
                                      color: context.appMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9+\s-]'),
                                      ),
                                      LengthLimitingTextInputFormatter(20),
                                    ],
                                    decoration: context.residentInputDecoration(
                                      label: 'Phone number',
                                      hint: '+60...',
                                    ),
                                    validator: Validators.validatePhone,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _EditPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ReadOnlyInfo(
                                    label: 'Community',
                                    value: user.communityName.trim().isEmpty
                                        ? '-'
                                        : user.communityName,
                                  ),
                                  const SizedBox(height: 10),
                                  _ReadOnlyInfo(
                                    label: 'Unit number',
                                    value: user.unitNumber.trim().isEmpty
                                        ? '-'
                                        : user.unitNumber,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _EditPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      color: context.appInk,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Send a secure reset link to your email.',
                                    style: TextStyle(
                                      color: context.appMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _passwordSending
                                        ? null
                                        : () => _sendPasswordReset(user),
                                    icon: const Icon(Icons.lock_reset_rounded),
                                    label: Text(
                                      _passwordSending
                                          ? 'Sending...'
                                          : 'Change Password',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _kBrandTeal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: auth.isLoading ? null : _saveProfile,
                              icon: const Icon(Icons.check_rounded),
                              label: Text(
                                auth.isLoading ? 'Saving...' : 'Save Changes',
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
        ),
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 32,
              ),
            ),
          ),
          const Text(
            'Edit Profile',
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPanel extends StatelessWidget {
  const _EditPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.10,
          blurRadius: 22,
          dy: 10,
        ),
      ),
      child: child,
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.user,
    required this.saving,
    required this.onTap,
  });

  final AppUser user;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.profileImageUrl.trim();
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: _kBrandTeal.withValues(alpha: 0.10),
              backgroundImage:
                  imageUrl.isEmpty ? null : NetworkImage(imageUrl),
              child: imageUrl.isEmpty
                  ? Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        color: _kBrandTeal,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            Material(
              color: _kBrandTeal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: saving ? null : onTap,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: saving
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tap camera to update photo',
          style: TextStyle(
            color: context.appMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.appInk,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'R';
  final first = parts.first.characters.first;
  final second = parts.length > 1 && parts[1].isNotEmpty
      ? parts[1].characters.first
      : '';
  return '$first$second'.toUpperCase();
}
