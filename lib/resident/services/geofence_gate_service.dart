import 'package:geolocator/geolocator.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';

class GeofenceGateResult {
  const GeofenceGateResult({required this.insideBoundary, this.message});

  final bool insideBoundary;
  final String? message;
}

class GeofenceGateService {
  GeofenceGateService({CommunityService? communityService})
    : _communityService = communityService ?? CommunityService();

  final CommunityService _communityService;

  Future<GeofenceGateResult> checkResidentAccess(AppUser user) async {
    if (!user.isResident) {
      return const GeofenceGateResult(insideBoundary: true);
    }

    final communityName = _communityName(user);
    if (user.communityId.trim().isEmpty && user.communityName.trim().isEmpty) {
      return const GeofenceGateResult(
        insideBoundary: false,
        message: 'Choose your community before entering Jirani.',
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 8));
      if (!serviceEnabled) {
        throw Exception('Turn on location services to enter your community.');
      }

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 8),
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 15),
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        throw Exception('Allow location access to enter your community.');
      }

      final boundary = await _loadBoundary(
        user,
      ).timeout(const Duration(seconds: 15));
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

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
      );
    } catch (error) {
      return GeofenceGateResult(
        insideBoundary: false,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

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

  String _communityName(AppUser user) {
    final name = user.communityName.trim();
    return name.isEmpty ? 'your selected community' : name;
  }
}

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
