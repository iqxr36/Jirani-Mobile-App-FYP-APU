import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/data/models/community_model.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

/// Registers the currently active partner communities as native geofence zones.
class GeofenceManager {
  GeofenceManager._();

  static final GeofenceManager instance = GeofenceManager._();

  bool _initialized = false;

  Future<bool> hasForegroundLocationPermission() async {
    final locationStatus = await Permission.location.status;
    return locationStatus.isGranted || locationStatus.isLimited;
  }

  Future<bool> hasBackgroundLocationPermission() async {
    final alwaysStatus = await Permission.locationAlways.status;
    return alwaysStatus.isGranted || alwaysStatus.isLimited;
  }

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

  Future<void> startGeofencing(List<CommunityModel> communities) async {
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
          triggers: const {
            GeofenceEvent.enter,
            GeofenceEvent.exit,
          },
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
