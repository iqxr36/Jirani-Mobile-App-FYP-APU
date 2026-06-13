import 'package:flutter/material.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/widgets/admin_status_widgets.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _verificationAlerts = true;
  bool _weeklyDigest = true;
  bool _reportEscalations = false;

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
                        AdminAvatar(
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
