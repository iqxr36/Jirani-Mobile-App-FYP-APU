import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

bool isOutsideCommunityBoundary({
  required double userLatitude,
  required double userLongitude,
  required double communityLatitude,
  required double communityLongitude,
  required double radiusMeters,
}) {
  return Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        communityLatitude,
        communityLongitude,
      ) >
      radiusMeters;
}

/// Shown when the user's current location is outside the community boundary.
class OutsideGeofenceView extends StatelessWidget {
  const OutsideGeofenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outside community zone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.map_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'You appear to be outside the approved community boundary.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Return to your community area, then retry the location check.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retry location check'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
