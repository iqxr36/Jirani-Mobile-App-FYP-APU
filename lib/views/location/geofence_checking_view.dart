import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/data/models/community_model.dart';
import 'package:fyp_flutter_application/services/community_service.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'location_verified_view.dart';
import 'outside_geofence_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 350;

/// Acquires the user's position and verifies it against their community boundary.
class GeofenceCheckingView extends StatefulWidget {
  const GeofenceCheckingView({
    super.key,
    this.communityId,
    this.communityName,
  });

  final String? communityId;
  final String? communityName;

  @override
  State<GeofenceCheckingView> createState() => _GeofenceCheckingViewState();
}

class _GeofenceCheckingViewState extends State<GeofenceCheckingView> {
  final CommunityService _communityService = CommunityService();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  Future<void> _runCheck() async {
    setState(() => _error = null);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final boundary = await _loadCommunityBoundary();

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
            builder: (_) => OutsideGeofenceView(
              communityName: _selectedCommunityName,
            ),
          ),
        );
        if (mounted) await _runCheck();
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LocationVerifiedView(
            communityName: _selectedCommunityName,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

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
      final activeCommunities =
          await _communityService.fetchActiveCommunities();
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

  String get _selectedCommunityName {
    final name = widget.communityName?.trim() ?? '';
    return name.isEmpty ? 'your selected community' : name;
  }

  Widget _buildMapImage() {
    return SizedBox(
      height: 238,
      width: 238,
      child: Image.asset(
        'assets/Location Map Ping.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => DecoratedBox(
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

  Widget _buildCheckingStatusCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          'Comparing your current location with\n$_selectedCommunityName...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final message =
        _error?.replaceFirst('Exception: ', '') ??
        'Could not check your location.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.3),
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
                onPressed: _runCheck,
                child: const Text('Try Again'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const Text(
                    'Please wait while we check if you are within\n'
                    'your selected community area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_error == null)
                    _buildCheckingStatusCard()
                  else
                    _buildErrorCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityBoundary {
  const _CommunityBoundary(this.latitude, this.longitude, this.radiusMeters);

  final double latitude;
  final double longitude;
  final double radiusMeters;
}
