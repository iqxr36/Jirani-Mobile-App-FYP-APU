import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';

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
      margin: const EdgeInsets.only(bottom: 10),
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
              children: [
                Chip(label: Text(request.status)),
                TextButton(onPressed: onView, child: const Text('View Details')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
