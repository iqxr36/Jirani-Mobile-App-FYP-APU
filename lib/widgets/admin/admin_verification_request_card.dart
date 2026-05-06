import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_status_chip.dart';

class AdminVerificationRequestCard extends StatelessWidget {
  const AdminVerificationRequestCard({
    super.key,
    required this.request,
    required this.onView,
  });

  final VerificationRequest request;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0.6,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBEC8CA), width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.fullName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(request.email),
              Text(request.phoneNumber),
              const SizedBox(height: 6),
              Text('Community: ${request.communityName}'),
              Text('Unit: ${request.unitNumber}'),
              Text('Document: ${request.documentType}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminStatusChip(status: request.status),
                  FilledButton.tonalIcon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Review'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
