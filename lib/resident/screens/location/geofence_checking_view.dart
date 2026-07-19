// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : geofence_checking_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'location_verified_view.dart';
import 'outside_geofence_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

/// Geofence feature blocked check reason: chooses the right recovery action after location validation fails.
enum _LocationCheckIssue {
  servicesOff,
  permissionDenied,
  permissionBlocked,
  unavailable,
}

/// Acquires the user's position and verifies it against their community boundary.
class GeofenceCheckingView extends StatefulWidget {
  const GeofenceCheckingView({super.key, this.communityId, this.communityName});

  final String? communityId;
  final String? communityName;

  @override
  State<GeofenceCheckingView> createState() => _GeofenceCheckingViewState();
}

class _GeofenceCheckingViewState extends State<GeofenceCheckingView> {
  final CommunityService _communityService = CommunityService();
  String? _error;
  _LocationCheckIssue? _issue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  /// Geofence feature: gets the current GPS position, compares it to the selected community, and routes to the correct result screen.
  Future<void> _runCheck() async {
    setState(() {
      _error = null;
      _issue = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _issue = _LocationCheckIssue.servicesOff;
          _error =
              'Turn on phone location services so Jirani can verify your community.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        setState(() {
          _issue = _LocationCheckIssue.permissionDenied;
          _error =
              'Allow location permission so Jirani can confirm you are inside your registered community.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _issue = _LocationCheckIssue.permissionBlocked;
          _error =
              'Location permission is blocked. Enable it in app settings to continue.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final boundary = await _loadCommunityBoundary();

      // Geofence feature: if the resident is outside the radius, show the outside screen and re-check after they try again.
      if (isOutsideCommunityBoundary(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        communityLatitude: boundary.latitude,
        communityLongitude: boundary.longitude,
        radiusMeters: boundary.radiusMeters,
      )) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                OutsideGeofenceView(communityName: _selectedCommunityName),
          ),
        );
        if (mounted) await _runCheck();
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              LocationVerifiedView(communityName: _selectedCommunityName),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _issue = _LocationCheckIssue.unavailable;
        _error = error.toString();
      });
    }
  }

  /// Geofence feature: opens app settings when location permission is permanently blocked.
  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Geofence feature: opens phone location settings when GPS/location services are off.
  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Geofence feature: fetches the selected community boundary from Firestore before running the distance check.
  Future<_CommunityBoundary> _loadCommunityBoundary() async {
    final user = context.read<AuthViewModel>().currentUser;
    final communityId =
        widget.communityId?.trim() ?? user?.communityId.trim() ?? '';
    final communityName =
        widget.communityName?.trim() ?? user?.communityName.trim() ?? '';

    CommunityModel? community;
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
      throw Exception('Selected community location boundary was not found.');
    }
    if (!community.isActive) {
      throw Exception('The selected community is no longer active.');
    }
    if (community.radiusInMeters <= 0) {
      throw Exception('Community location boundary is not configured.');
    }
    return _CommunityBoundary(
      community.centerLocation.latitude,
      community.centerLocation.longitude,
      community.radiusInMeters,
    );
  }

  /// Geofence feature: chooses the label shown in checking/outside screens when communityName is missing.
  String get _selectedCommunityName {
    final name = widget.communityName?.trim() ?? '';
    return name.isEmpty ? 'your selected community' : name;
  }

  /// Geofence feature UI: shows the location illustration while the app validates the resident's area.
  Widget _buildMapImage() {
    return SizedBox(
      height: 238,
      width: 238,
      child: Image.asset(
        'assets/Location Map Ping.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBrandTeal.withValues(alpha: 0.12),
          ),
          child: const Center(
            child: Icon(Icons.location_on, size: 70, color: _kBrandTeal),
          ),
        ),
      ),
    );
  }

  /// Geofence feature UI: explains that the app is comparing the device location with the community boundary.
  Widget _buildCheckingStatusCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          'Comparing your current location with\n$_selectedCommunityName...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appInk,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  /// Geofence feature UI: shows permission, GPS, or missing-boundary errors with a retry action.
  Widget _buildErrorCard(BuildContext context) {
    final message =
        _error?.replaceFirst('Exception: ', '') ??
        'Could not check your location.';
    final issue = _issue;
    final primaryLabel = switch (issue) {
      _LocationCheckIssue.servicesOff => 'Open Location Settings',
      _LocationCheckIssue.permissionBlocked => 'Open App Settings',
      _LocationCheckIssue.permissionDenied => 'Allow Location',
      _ => 'Try Again',
    };
    final primaryAction = switch (issue) {
      _LocationCheckIssue.servicesOff => _openLocationSettings,
      _LocationCheckIssue.permissionBlocked => _openAppSettings,
      _ => _runCheck,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.3, color: context.appInk),
            ),
            const SizedBox(height: 12),
            Text(
              'Location verification is required before resident features can open.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: context.appMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _kBrandTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: primaryAction,
                child: Text(primaryLabel),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  /// Geofence feature UI: renders the checking page that appears before entering resident-only screens.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                children: [
                  _buildMapImage(),
                  const SizedBox(height: 28),
                  const Text(
                    'Checking Your Location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kBrandTeal,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Please wait while we check if you are within\n'
                    'your selected community area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_error == null)
                    _buildCheckingStatusCard(context)
                  else
                    _buildErrorCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Geofence feature data model: stores the selected community center and allowed radius for this screen.
class _CommunityBoundary {
  const _CommunityBoundary(this.latitude, this.longitude, this.radiusMeters);

  final double latitude;
  final double longitude;
  final double radiusMeters;
}
