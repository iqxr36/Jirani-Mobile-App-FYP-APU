// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : geofence_gate_service.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:geolocator/geolocator.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';

/// Platform location operations used by the geofence gate.
///
/// Keeping this boundary injectable lets the gate be tested without invoking
/// platform channels and, importantly, keeps passive checks separate from OS
/// permission prompts.
abstract interface class GeofenceLocationGateway {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition();
}

class GeolocatorGeofenceLocationGateway implements GeofenceLocationGateway {
  const GeolocatorGeofenceLocationGateway();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 20),
    ),
  );
}

/// Geofence feature block reason: lets the UI choose the right recovery action instead of showing a generic retry loop.
enum GeofenceGateBlockReason {
  missingCommunity,
  locationServicesOff,
  permissionDenied,
  permissionDeniedForever,
  outsideBoundary,
  communityUnavailable,
  checkFailed,
}

/// Geofence feature result: tells the resident shell whether to allow app access or show a boundary message.
class GeofenceGateResult {
  const GeofenceGateResult({
    required this.insideBoundary,
    this.message,
    this.blockReason,
  });

  final bool insideBoundary;
  final String? message;
  final GeofenceGateBlockReason? blockReason;
}

/// Geofence feature service: validates resident access by comparing the device location to the selected community radius.
class GeofenceGateService {
  GeofenceGateService({
    CommunityService? communityService,
    GeofenceLocationGateway? locationGateway,
  }) : _communityService = communityService ?? CommunityService(),
       _locationGateway =
           locationGateway ?? const GeolocatorGeofenceLocationGateway();

  final CommunityService _communityService;
  final GeofenceLocationGateway _locationGateway;

  /// Requests foreground location only after an explicit user action.
  Future<GeofenceGateResult> requestForegroundLocationPermission() async {
    try {
      final serviceEnabled = await _locationGateway.isServiceEnabled().timeout(
        const Duration(seconds: 8),
      );
      if (!serviceEnabled) {
        return const GeofenceGateResult(
          insideBoundary: false,
          message: 'Turn on location services to enter your community.',
          blockReason: GeofenceGateBlockReason.locationServicesOff,
        );
      }

      final permission = await _locationGateway.requestPermission().timeout(
        const Duration(seconds: 15),
      );
      return _permissionResult(permission);
    } catch (_) {
      return const GeofenceGateResult(
        insideBoundary: false,
        message: 'Could not request location permission. Please try again.',
        blockReason: GeofenceGateBlockReason.checkFailed,
      );
    }
  }

  /// Geofence feature: checks permissions, loads the resident community boundary, and returns whether the resident may enter the app.
  Future<GeofenceGateResult> checkResidentAccess(AppUser user) async {
    if (!user.isResident) {
      return const GeofenceGateResult(insideBoundary: true);
    }

    final communityName = _communityName(user);
    if (user.communityId.trim().isEmpty && user.communityName.trim().isEmpty) {
      return const GeofenceGateResult(
        insideBoundary: false,
        message: 'Choose your community before entering Jirani.',
        blockReason: GeofenceGateBlockReason.missingCommunity,
      );
    }

    try {
      final serviceEnabled = await _locationGateway.isServiceEnabled().timeout(
        const Duration(seconds: 8),
      );
      if (!serviceEnabled) {
        return const GeofenceGateResult(
          insideBoundary: false,
          message: 'Turn on location services to enter your community.',
          blockReason: GeofenceGateBlockReason.locationServicesOff,
        );
      }

      final permission = await _locationGateway.checkPermission().timeout(
        const Duration(seconds: 8),
      );
      final permissionResult = _permissionResult(permission);
      if (permissionResult.blockReason != null) return permissionResult;

      final boundary = await _loadBoundary(
        user,
      ).timeout(const Duration(seconds: 15));
      final position = await _locationGateway.getCurrentPosition();

      // Geofence feature: calculate the straight-line distance from the phone to the community center.
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        boundary.latitude,
        boundary.longitude,
      );
      final insideBoundary = distance <= boundary.radiusMeters;

      return GeofenceGateResult(
        insideBoundary: insideBoundary,
        message: insideBoundary
            ? null
            : 'You are outside $communityName. Move closer and try again.',
        blockReason: insideBoundary
            ? null
            : GeofenceGateBlockReason.outsideBoundary,
      );
    } catch (error) {
      return GeofenceGateResult(
        insideBoundary: false,
        message: error.toString().replaceFirst('Exception: ', ''),
        blockReason: GeofenceGateBlockReason.checkFailed,
      );
    }
  }

  GeofenceGateResult _permissionResult(LocationPermission permission) {
    if (permission == LocationPermission.deniedForever) {
      return const GeofenceGateResult(
        insideBoundary: false,
        message:
            'Location permission is blocked. Enable it in app settings to enter your community.',
        blockReason: GeofenceGateBlockReason.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return const GeofenceGateResult(
        insideBoundary: false,
        message: 'Allow location access to enter your community.',
        blockReason: GeofenceGateBlockReason.permissionDenied,
      );
    }
    return const GeofenceGateResult(insideBoundary: true);
  }

  /// Geofence feature: loads the community center point and radius from Firestore using either communityId or communityName.
  Future<_Boundary> _loadBoundary(AppUser user) async {
    CommunityModel? community;
    final communityId = user.communityId.trim();
    final communityName = user.communityName.trim();

    if (communityId.isNotEmpty) {
      community = await _communityService.fetchCommunity(communityId);
    }
    if (community == null && communityName.isNotEmpty) {
      final activeCommunities = await _communityService
          .fetchActiveCommunities();
      for (final activeCommunity in activeCommunities) {
        if (activeCommunity.name == communityName) {
          community = activeCommunity;
          break;
        }
      }
    }

    if (community == null) {
      throw Exception('Community boundary was not found.');
    }
    if (!community.isActive) {
      throw Exception('Your selected community is no longer active.');
    }
    if (community.radiusInMeters <= 0) {
      throw Exception('Community boundary is not configured.');
    }

    return _Boundary(
      latitude: community.centerLocation.latitude,
      longitude: community.centerLocation.longitude,
      radiusMeters: community.radiusInMeters,
    );
  }

  /// Geofence feature: provides a readable community name for resident-facing boundary messages.
  String _communityName(AppUser user) {
    final name = user.communityName.trim();
    return name.isEmpty ? 'your selected community' : name;
  }
}

/// Geofence feature data model: holds the minimum boundary values needed for the distance calculation.
class _Boundary {
  const _Boundary({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
}
