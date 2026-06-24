import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const int _kMaxProfileImageBytes = 5 * 1024 * 1024;

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _imagePicker = ImagePicker();
  bool _verificationAlerts = true;
  bool _weeklyDigest = true;
  bool _reportEscalations = false;
  bool _profileImageSaving = false;

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
    final success = await auth.updateAdminProfileImage(
      bytes: bytes,
      originalFileName: picked.name,
    );
    if (!mounted) return;
    setState(() => _profileImageSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Admin profile photo updated.'
              : auth.errorMessage ?? 'Could not update profile photo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthViewModel>().currentAdmin;
    return AdminPageScroll(
      children: [
        AdminPanel(
          title: 'Admin Profile & Platform Settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSettingsSection(
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
                        _EditableAdminProfilePhoto(
                          name: admin?.fullName ?? 'Admin',
                          imageUrl: admin?.profileImageUrl ?? '',
                          isLoading: _profileImageSaving,
                          onTap: admin == null ? null : _changeProfileImage,
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
              AdminSettingsSection(
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
              AdminSettingsSection(
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

class _EditableAdminProfilePhoto extends StatelessWidget {
  const _EditableAdminProfilePhoto({
    required this.name,
    required this.imageUrl,
    required this.isLoading,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Change admin profile photo',
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AdminAvatar(
                        name: name,
                        imageUrl: imageUrl,
                        large: true,
                      ),
                    ),
                    if (isLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.34),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AdminColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Profile photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AdminColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminSettingsSection extends StatelessWidget {
  const AdminSettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

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
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 24),
          const Divider(color: AdminColors.border),
        ],
      ),
    );
  }
}
