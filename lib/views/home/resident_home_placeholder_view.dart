import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/location/location_permission_view.dart';
import 'package:fyp_flutter_application/resident/screens/borrowing/incoming_borrow_requests_screen.dart';
import 'package:fyp_flutter_application/resident/screens/borrowing/my_borrow_requests_screen.dart';
import 'package:fyp_flutter_application/resident/screens/reports/my_reports_screen.dart';
import 'package:fyp_flutter_application/resident/screens/services/my_services_screen.dart';
import 'package:fyp_flutter_application/resident/screens/services/services_browse_screen.dart';
import 'package:fyp_flutter_application/views/marketplace/add_item_view.dart';
import 'package:fyp_flutter_application/views/marketplace/marketplace_browse_view.dart';
import 'package:fyp_flutter_application/views/marketplace/my_listed_items_view.dart';
import 'package:fyp_flutter_application/views/profile/profile_view.dart';
import 'package:fyp_flutter_application/views/verification/upload_verification_document_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_status_view.dart';
import 'package:fyp_flutter_application/widgets/verification_status_chip.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';
import 'package:provider/provider.dart';

/// Phase 1–2 placeholder for the resident dashboard (verified / pending / limited copy).
class ResidentHomePlaceholderView extends StatelessWidget {
  const ResidentHomePlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.currentUser;
    final status = user?.verificationStatus ?? '';
    final isVerified = user?.isVerifiedResident ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileView()),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hello${user != null && user.fullName.isNotEmpty ? ', ${user.fullName.split(' ').first}' : ''}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This is your home dashboard placeholder. Feature modules will appear here in later phases.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
          ),
          if (user != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Signed in as ${user.email}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Verification: '),
                        VerificationStatusChip(status: user.verificationStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isVerified) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Verified resident',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const VerifiedBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have full access within Trust Community for features as they roll out (marketplace, services, chat, and more).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isVerified && user != null) ...[
            const SizedBox(height: 12),
            if (status == AppConstants.verificationPending) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Limited access',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Only verified residents can access full community features (marketplace, services, chat, and more). '
                        'Complete residency verification when you are ready.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const LocationPermissionView()),
                          );
                        },
                        child: const Text('Complete verification'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (status == AppConstants.verificationSubmitted) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hourglass_top_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Verification under review',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your documents are being reviewed. We will update your status when the review is complete.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
                          );
                        },
                        child: const Text('View verification status'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (status == AppConstants.verificationRejected) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Verification rejected',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your last submission could not be verified. You can review the reason in Verification status and upload new proof.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const UploadVerificationDocumentView()),
                          );
                        },
                        child: const Text('Resubmit verification'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
                          );
                        },
                        child: const Text('View verification status'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Verification status: ${status.isEmpty ? 'unknown' : status}. Open Verification status for details.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Text('Quick previews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _FeaturePreviewCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Items nearby',
            subtitle: 'Marketplace — Phase 3',
            enabled: isVerified,
            onTap: () {
              if (isVerified) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MarketplaceBrowseView()),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complete residency verification to access marketplace features.')),
              );
            },
          ),
          if (isVerified) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AddItemView()),
                    );
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Add Item'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MyListedItemsView()),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('My Listed Items'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MyBorrowRequestsScreen()),
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('My Borrow Requests'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const IncomingBorrowRequestsScreen()),
                    );
                  },
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Incoming Requests'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ServicesBrowseScreen()),
                    );
                  },
                  icon: const Icon(Icons.home_repair_service_outlined),
                  label: const Text('Services'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MyServicesScreen()),
                    );
                  },
                  icon: const Icon(Icons.design_services_outlined),
                  label: const Text('My Services'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('My Reports'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _FeaturePreviewCard(
            icon: Icons.handshake_outlined,
            title: 'Active borrowings',
            subtitle: 'Phase 4',
            enabled: false,
          ),
          _FeaturePreviewCard(
            icon: Icons.home_repair_service_outlined,
            title: 'Local services',
            subtitle: 'Browse resident listings',
            enabled: isVerified,
            onTap: () {
              if (isVerified) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ServicesBrowseScreen()),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complete residency verification to access services.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturePreviewCard extends StatelessWidget {
  const _FeaturePreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(enabled ? Icons.chevron_right : Icons.lock_outline, size: 20),
        onTap: onTap,
      ),
    );
  }
}
