// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : geofence_manager.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

/// Registers the currently active partner communities as native geofence zones.
class GeofenceManager {
  GeofenceManager._();

  static final GeofenceManager instance = GeofenceManager._();

  bool _initialized = false;

  /// Geofence feature: checks whether the app can read the device location while it is open.
  Future<bool> hasForegroundLocationPermission() async {
    final locationStatus = await Permission.location.status;
    return locationStatus.isGranted || locationStatus.isLimited;
  }

  /// Geofence feature: checks whether native geofence monitoring can continue after the app is backgrounded.
  Future<bool> hasBackgroundLocationPermission() async {
    final alwaysStatus = await Permission.locationAlways.status;
    return alwaysStatus.isGranted || alwaysStatus.isLimited;
  }

  /// Geofence feature: asks for foreground and background location permissions required by native geofence monitoring.
  Future<bool> requestLocationPermissions() async {
    try {
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        debugPrint('Gatekeeper: foreground location permission not granted.');
        return false;
      }

      final alwaysStatus = await Permission.locationAlways.request();
      if (!alwaysStatus.isGranted) {
        debugPrint('Gatekeeper: background location permission not granted.');
        return false;
      }

      return true;
    } catch (error) {
      debugPrint('Gatekeeper: failed to request location permissions: $error');
      return false;
    }
  }

  /// Geofence feature: initializes the native geofence plugin once before registering community zones.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
    } on NativeGeofenceException catch (error) {
      debugPrint(
        'Gatekeeper: native geofence initialization failed: '
        '${error.code} ${error.message}',
      );
      rethrow;
    }
  }

  /// Geofence feature: replaces old zones with active Firestore communities so enter/exit callbacks match current data.
  Future<void> startGeofencing(List<CommunityModel> communities) async {
    final hasForeground = await hasForegroundLocationPermission();
    final hasBackground = await hasBackgroundLocationPermission();
    if (!hasForeground || !hasBackground) {
      debugPrint(
        'Gatekeeper: native monitoring was not started because foreground '
        'and background location permissions are required.',
      );
      return;
    }

    try {
      await initialize();
      await NativeGeofenceManager.instance.removeAllGeofences();

      final activeCommunities = communities.where(
        (community) => community.isActive,
      );

      for (final community in activeCommunities) {
        final geofence = Geofence(
          id: community.communityId,
          location: Location(
            latitude: community.centerLocation.latitude,
            longitude: community.centerLocation.longitude,
          ),
          radiusMeters: community.radiusInMeters,
          triggers: const {GeofenceEvent.enter, GeofenceEvent.exit},
          iosSettings: const IosGeofenceSettings(initialTrigger: true),
          androidSettings: const AndroidGeofenceSettings(
            initialTriggers: {GeofenceEvent.enter},
            notificationResponsiveness: Duration(minutes: 1),
          ),
        );

        await NativeGeofenceManager.instance.createGeofence(
          geofence,
          gatekeeperGeofenceTriggered,
        );
      }
    } on NativeGeofenceException catch (error) {
      debugPrint(
        'Gatekeeper: failed to register native geofences: '
        '${error.code} ${error.message}',
      );
      rethrow;
    }
  }
}

@pragma('vm:entry-point')
/// Geofence feature callback: receives native enter/exit events even when invoked by the platform outside normal Dart UI flow.
Future<void> gatekeeperGeofenceTriggered(GeofenceCallbackParams params) async {
  final communityIds = params.geofences
      .map((geofence) => geofence.id)
      .join(', ');

  if (params.event == GeofenceEvent.enter) {
    debugPrint('Gatekeeper: entered community geofence(s): $communityIds');
    return;
  }

  if (params.event == GeofenceEvent.exit) {
    debugPrint('Gatekeeper: exited community geofence(s): $communityIds');
    return;
  }

  debugPrint(
    'Gatekeeper: received ${params.event} for community geofence(s): '
    '$communityIds',
  );
}
