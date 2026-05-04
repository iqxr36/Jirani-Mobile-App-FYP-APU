import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/profile/edit_profile_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_status_view.dart';
import 'package:fyp_flutter_application/widgets/verification_status_chip.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: user == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const EditProfileView()),
                    );
                  },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: user.profileImageUrl.isEmpty
                              ? Text(
                                  _initials(user.fullName),
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : ClipOval(
                                  child: Image.network(
                                    user.profileImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      _initials(user.fullName),
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                        if (user.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(user.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            Chip(label: Text(_roleLabel(user.role))),
                            VerificationStatusChip(status: user.verificationStatus),
                            if (user.isVerifiedResident) const VerifiedBadge(compact: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.apartment_outlined, label: 'Community', value: _display(user.communityName)),
                        _InfoRow(icon: Icons.door_front_door_outlined, label: 'Unit', value: _display(user.unitNumber)),
                        _InfoRow(
                          icon: Icons.star_border_rounded,
                          label: 'Reputation',
                          value: '${user.reputationScore} (${user.totalReviews} reviews)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const EditProfileView()),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verification status',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
                    );
                  },
                ),
                _MenuTile(icon: Icons.inventory_2_outlined, title: 'My items', subtitle: 'Phase 3', enabled: false),
                _MenuTile(icon: Icons.handshake_outlined, title: 'My borrowings', subtitle: 'Phase 4', enabled: false),
                _MenuTile(icon: Icons.home_repair_service_outlined, title: 'My services', subtitle: 'Phase 5', enabled: false),
                _MenuTile(icon: Icons.reviews_outlined, title: 'Reviews', subtitle: 'Phase 6', enabled: false),
                _MenuTile(icon: Icons.flag_outlined, title: 'Safety reports', subtitle: 'Phase 6', enabled: false),
                _MenuTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Phase 6', enabled: false),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: vm.isLoading ? null : () => vm.logout(),
                ),
              ],
            ),
    );
  }

  static String _roleLabel(String role) {
    if (role == AppConstants.roleCommunityAdmin) return 'Community admin';
    if (role == AppConstants.roleSystemAdmin) return 'System admin';
    return 'Resident';
  }

  static String _display(String value) => value.isEmpty ? '—' : value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade700)),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
