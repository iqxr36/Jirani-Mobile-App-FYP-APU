// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : location_access.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/services/location_onboarding_prefs.dart';
import 'package:jirani/resident/screens/location/location_permission_view.dart';
import 'package:jirani/resident/screens/verification/verification_permission_flow_view.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground location: first-launch education + on-demand gate for verification / future geofence.
class LocationAccess {
  LocationAccess._();

  /// OS location services on and app has When-In-Use (or Always) permission.
  static Future<bool> isLocationReadyForUse() async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) return false;
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Once per install (resident home): show [LocationPermissionView] if services/permission not ready.
  /// If location is already usable, records onboarding as done without blocking the user.
  static Future<void> showInitialOnboardingIfNeeded(
    BuildContext context,
  ) async {
    if (await LocationOnboardingPrefs.wasShown()) return;

    if (await isLocationReadyForUse()) {
      await LocationOnboardingPrefs.markShown();
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LocationPermissionView(isInitialOnboarding: true),
      ),
    );
  }

  /// Verification flow: one-time permissions, then confirm community before geofence checking.
  static Future<void> openVerificationLocationFlow(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const VerificationPermissionFlowView(),
      ),
    );
  }
}
