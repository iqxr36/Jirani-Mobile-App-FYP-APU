// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : location_permission_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/resident/services/location_onboarding_prefs.dart';
import 'package:jirani/resident/services/verification_permission_prefs.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:geolocator/geolocator.dart';

import 'community_confirmation_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

/// Location permission — Figma Group 16: illustration, privacy card, enable / not now.
// Location permission feature: asks for device location access before community geofence verification.
class LocationPermissionView extends StatefulWidget {
  const LocationPermissionView({
    super.key,
    this.isInitialOnboarding = false,
    this.nextBuilder,
  });

  /// First install / one-time education from home; marks [LocationOnboardingPrefs] when disposed.
  final bool isInitialOnboarding;
  final WidgetBuilder? nextBuilder;

  @override
  State<LocationPermissionView> createState() => _LocationPermissionViewState();
}

class _LocationPermissionViewState extends State<LocationPermissionView>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _waitingForSettings = false;
  bool _hasOpenedNextScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.isInitialOnboarding) {
      unawaited(LocationOnboardingPrefs.markShown());
    }
    super.dispose();
  }

  @override
  // Location permission feature: resumes permission checks after the user returns from settings.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_waitingForSettings) return;
    _waitingForSettings = false;
    unawaited(_resumeAfterSettings());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLocationSettingsDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JiraniDialog(
        title: 'Turn on Location Services',
        icon: Icons.location_off_rounded,
        content: const Text(
          'Jirani must confirm that you are inside your registered community before you can use resident features. Turn on phone location services to continue.',
          style: TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay Here'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(_openLocationSettings());
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JiraniDialog(
        title: 'Location Permission Required',
        icon: Icons.my_location_rounded,
        content: const Text(
          'Location permission is blocked for Jirani. Enable it in app settings so we can verify your community before opening the app.',
          style: TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay Here'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(_openAppSettings());
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Location permission feature: explains why denial blocks progress and gives a recovery action without advancing into the app.
  void _showPermissionRequiredDialog({required bool openSettings}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JiraniDialog(
        title: 'Location Permission Needed',
        icon: Icons.verified_user_rounded,
        content: const Text(
          'Jirani uses your location to confirm you are inside your registered community. Because this is required for resident access, you cannot continue until location permission is allowed.',
          style: TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay Here'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (openSettings) {
                unawaited(_openAppSettings());
              } else {
                unawaited(_handleEnableLocation());
              }
            },
            child: Text(openSettings ? 'Open Settings' : 'Allow Location'),
          ),
        ],
      ),
    );
  }

  // Location permission feature: opens app settings when permission was denied permanently.
  Future<void> _openAppSettings() async {
    _waitingForSettings = true;
    try {
      final opened = await Geolocator.openAppSettings();
      if (!opened && mounted) {
        _waitingForSettings = false;
        _showSnack('Could not open app settings. Please try again.');
      }
    } catch (_) {
      _waitingForSettings = false;
      if (mounted) {
        _showSnack('Could not open app settings. Please try again.');
      }
    }
  }

  // Location permission feature: opens OS location settings when GPS/location services are disabled.
  Future<void> _openLocationSettings() async {
    _waitingForSettings = true;
    try {
      final opened = await Geolocator.openLocationSettings();
      if (!opened && mounted) {
        _waitingForSettings = false;
        _showSnack('Could not open location settings. Please try again.');
      }
    } catch (_) {
      _waitingForSettings = false;
      if (mounted) {
        _showSnack('Could not open location settings. Please try again.');
      }
    }
  }

  // Location permission feature: retries the permission flow after the settings screen returns.
  Future<void> _resumeAfterSettings() async {
    if (_hasOpenedNextScreen || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showSnack('Turn on location services to continue.');
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _openNextScreen();
        return;
      }

      _showSnack('Location permission is still required to continue.');
    } catch (_) {
      if (mounted) {
        _showSnack('Could not check location permission. Please try again.');
      }
    } finally {
      if (mounted && !_hasOpenedNextScreen) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Location permission feature: moves the resident to community confirmation/geofence checks once allowed.
  Future<void> _openNextScreen() async {
    if (_hasOpenedNextScreen || !mounted) return;
    _hasOpenedNextScreen = true;
    if (!widget.isInitialOnboarding) {
      await VerificationPermissionPrefs.markLocationShown();
    }
    if (!mounted) return;
    final nextBuilder = widget.nextBuilder;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: nextBuilder ?? (_) => const CommunityConfirmationView(),
      ),
    );
  }

  // Location permission feature: requests foreground location permission and handles denied states.
  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.deniedForever) {
      _showAppSettingsDialog();
      return;
    }

    if (permission == LocationPermission.denied) {
      _showPermissionRequiredDialog(openSettings: false);
      return;
    }

    await _openNextScreen();
  }

  // Location permission feature: validates service availability and asks for permission when the button is tapped.
  Future<void> _handleEnableLocation() async {
    if (_isLoading || _hasOpenedNextScreen) return;
    setState(() => _isLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;

      if (!serviceEnabled) {
        _showLocationSettingsDialog();
        return;
      }

      await _requestLocationPermission();
    } catch (e) {
      if (mounted) {
        _showSnack('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted && !_hasOpenedNextScreen) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Location permission feature: exits the permission screen when the resident chooses not to continue.
  void _handleNotNow() {
    if (_isLoading || _hasOpenedNextScreen) return;
    _showPermissionRequiredDialog(openSettings: false);
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Image.asset(
        'assets/perm1.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholderIllustration(),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    final softTeal = _kBrandTeal.withValues(alpha: 0.12);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 24,
          top: 20,
          child: Icon(Icons.home_rounded, size: 28, color: softTeal),
        ),
        Positioned(
          right: 32,
          top: 36,
          child: Icon(Icons.person_outline_rounded, size: 26, color: softTeal),
        ),
        Positioned(
          right: 48,
          bottom: 28,
          child: Icon(Icons.map_outlined, size: 24, color: softTeal),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: softTeal),
        ),
        Icon(Icons.location_on_rounded, size: 88, color: _kBrandTeal),
      ],
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Enable Location Access',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _kBrandTeal,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'This helps keep Jirani safe\nfor real residents only.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appInk,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.skeletonBar,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: _kBrandTeal,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your location is only used for\ncommunity verification.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.appInk,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableLocationButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : _handleEnableLocation,
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Checking Location...',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Enable Location',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotNowButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF787880).withValues(alpha: 0.16),
          foregroundColor: _kBrandTeal,
          disabledForegroundColor: _kBrandTeal.withValues(alpha: 0.45),
          disabledBackgroundColor: const Color(
            0xFF787880,
          ).withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : _handleNotNow,
        child: const Text(
          'Not Now',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 18 + bottomInset),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildIllustration(),
                        const SizedBox(height: 16),
                        _buildTitle(),
                        const SizedBox(height: 32),
                        _buildSubtitle(context),
                        const SizedBox(height: 32),
                        _buildPrivacyCard(context),
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEnableLocationButton(),
                        const SizedBox(height: 12),
                        _buildNotNowButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
