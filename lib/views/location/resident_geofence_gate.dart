import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/services/community_service.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/location/community_confirmation_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

class ResidentGeofenceGate extends StatefulWidget {
  const ResidentGeofenceGate({
    super.key,
    required this.user,
    required this.child,
  });

  final AppUser user;
  final Widget child;

  @override
  State<ResidentGeofenceGate> createState() => _ResidentGeofenceGateState();
}

class _ResidentGeofenceGateState extends State<ResidentGeofenceGate>
    with WidgetsBindingObserver {
  final CommunityService _communityService = CommunityService();

  bool _checking = true;
  bool _insideBoundary = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResidentGeofenceGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.communityId != widget.user.communityId ||
        oldWidget.user.communityName != widget.user.communityName ||
        oldWidget.user.locationVerified != widget.user.locationVerified) {
      unawaited(_check());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (!mounted) return;
    if (!widget.user.isResident) {
      setState(() {
        _checking = false;
        _insideBoundary = true;
        _message = null;
      });
      return;
    }

    final hasCommunity =
        widget.user.communityId.trim().isNotEmpty ||
        widget.user.communityName.trim().isNotEmpty;
    if (!hasCommunity) {
      setState(() {
        _checking = false;
        _insideBoundary = false;
        _message = 'Choose your community before entering Jirani.';
      });
      return;
    }

    setState(() {
      _checking = true;
      _message = null;
    });

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

      final boundary = await _loadBoundary().timeout(
        const Duration(seconds: 15),
      );
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

      if (!mounted) return;
      if (insideBoundary && !widget.user.locationVerified) {
        await context.read<AuthViewModel>().markLocationVerified();
      }

      if (!mounted) return;
      setState(() {
        _checking = false;
        _insideBoundary = insideBoundary;
        _message = _insideBoundary
            ? null
            : 'You are outside $_communityName. Move closer and try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _insideBoundary = false;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<_Boundary> _loadBoundary() async {
    CommunityModel? community;
    final communityId = widget.user.communityId.trim();
    final communityName = widget.user.communityName.trim();

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

  String get _communityName {
    final name = widget.user.communityName.trim();
    return name.isEmpty ? 'your selected community' : name;
  }

  Future<void> _chooseCommunity() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityConfirmationView(),
      ),
    );
    if (mounted) unawaited(_check());
  }

  @override
  Widget build(BuildContext context) {
    if (_insideBoundary && !_checking) return widget.child;

    return _GeofenceBlockScreen(
      checking: _checking,
      message: _message,
      hasCommunity:
          widget.user.communityId.trim().isNotEmpty ||
          widget.user.communityName.trim().isNotEmpty,
      onRetry: () => unawaited(_check()),
      onChooseCommunity: () => unawaited(_chooseCommunity()),
    );
  }
}

class _GeofenceBlockScreen extends StatelessWidget {
  const _GeofenceBlockScreen({
    required this.checking,
    required this.message,
    required this.hasCommunity,
    required this.onRetry,
    required this.onChooseCommunity,
  });

  final bool checking;
  final String? message;
  final bool hasCommunity;
  final VoidCallback onRetry;
  final VoidCallback onChooseCommunity;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 28, 28, 20 + bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      color: _kBrandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      checking
                          ? Icons.location_searching_rounded
                          : Icons.location_off_rounded,
                      color: _kBrandTeal,
                      size: 62,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    checking ? 'Checking Your Area' : 'Outside Community Area',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kBrandTeal,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    checking
                        ? 'Please wait while Jirani confirms that you are inside your selected community.'
                        : message ??
                              'Move back inside your selected community to use Jirani features.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (checking)
                    const Center(
                      child: CircularProgressIndicator(color: _kBrandTeal),
                    )
                  else ...[
                    _GateButton(
                      label: 'Try Again',
                      icon: Icons.refresh_rounded,
                      background: _kBrandTeal,
                      foreground: Colors.white,
                      onPressed: onRetry,
                    ),
                    const SizedBox(height: 10),
                    _GateButton(
                      label: hasCommunity
                          ? 'Change Community'
                          : 'Choose Community',
                      icon: Icons.apartment_rounded,
                      background: const Color(
                        0xFF787880,
                      ).withValues(alpha: 0.16),
                      foreground: _kBrandTeal,
                      onPressed: onChooseCommunity,
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GateButton extends StatelessWidget {
  const _GateButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
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
