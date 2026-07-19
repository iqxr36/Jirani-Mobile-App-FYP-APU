// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_geofence_gate.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/resident/services/geofence_gate_service.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/location/community_confirmation_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

/// Geofence feature wrapper: blocks resident app content until the user's selected community boundary is verified.
class ResidentGeofenceGate extends StatefulWidget {
  const ResidentGeofenceGate({
    super.key,
    required this.user,
    required this.child,
    this.gateService,
  });

  final AppUser user;
  final Widget child;
  final GeofenceGateService? gateService;

  @override
  State<ResidentGeofenceGate> createState() => _ResidentGeofenceGateState();
}

class _ResidentGeofenceGateState extends State<ResidentGeofenceGate>
    with WidgetsBindingObserver {
  late final GeofenceGateService _gateService;

  bool _checking = true;
  bool _insideBoundary = false;
  String? _message;
  GeofenceGateBlockReason? _blockReason;
  bool _checkInProgress = false;
  bool _waitingForSettings = false;

  @override
  /// Geofence feature lifecycle: starts the first boundary check after the widget is mounted.
  void initState() {
    super.initState();
    _gateService = widget.gateService ?? GeofenceGateService();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  /// Geofence feature lifecycle: removes the app lifecycle observer used for re-checking on resume.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  /// Geofence feature lifecycle: re-runs the check when the resident changes community or verification state.
  void didUpdateWidget(covariant ResidentGeofenceGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.communityId != widget.user.communityId ||
        oldWidget.user.communityName != widget.user.communityName ||
        oldWidget.user.locationVerified != widget.user.locationVerified) {
      unawaited(_check());
    }
  }

  @override
  /// Geofence feature lifecycle: re-checks the resident boundary when the app returns to the foreground.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      unawaited(_check());
    }
  }

  /// Geofence feature: decides whether to show the protected resident app or the blocked community boundary screen.
  Future<void> _check() async {
    if (!mounted || _checkInProgress) return;
    _checkInProgress = true;
    try {
      if (!widget.user.isResident) {
        setState(() {
          _checking = false;
          _insideBoundary = true;
          _message = null;
          _blockReason = null;
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
          _blockReason = GeofenceGateBlockReason.missingCommunity;
        });
        return;
      }

      final wasInsideBoundary = _insideBoundary;
      setState(() {
        _checking = !wasInsideBoundary;
        _message = null;
        _blockReason = null;
      });

      final result = await _gateService.checkResidentAccess(widget.user);

      if (!mounted) return;
      // Geofence feature: persist the first successful location verification so the user record reflects the approved location.
      if (result.insideBoundary && !widget.user.locationVerified) {
        try {
          await context.read<AuthViewModel>().markLocationVerified();
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _checking = false;
            _insideBoundary = false;
            _message = 'Could not save location verification. Try again.';
            _blockReason = GeofenceGateBlockReason.checkFailed;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _checking = false;
        _insideBoundary = result.insideBoundary;
        _message = result.message;
        _blockReason = result.blockReason;
      });
    } finally {
      _checkInProgress = false;
    }
  }

  Future<void> _requestLocationPermission() async {
    if (!mounted || _checkInProgress) return;
    _checkInProgress = true;
    setState(() => _checking = true);
    try {
      final result = await _gateService.requestForegroundLocationPermission();
      if (!mounted) return;
      if (result.blockReason == null) {
        _checkInProgress = false;
        await _check();
        return;
      }
      setState(() {
        _checking = false;
        _insideBoundary = false;
        _message = result.message;
        _blockReason = result.blockReason;
      });
    } finally {
      _checkInProgress = false;
    }
  }

  /// Geofence feature: opens phone app settings after permission is permanently denied.
  Future<void> _openAppSettings() async {
    _waitingForSettings = await Geolocator.openAppSettings();
    if (!_waitingForSettings && mounted) unawaited(_check());
  }

  /// Geofence feature: opens phone location settings when GPS/location services are turned off.
  Future<void> _openLocationSettings() async {
    _waitingForSettings = await Geolocator.openLocationSettings();
    if (!_waitingForSettings && mounted) unawaited(_check());
  }

  /// Geofence feature: opens community selection, then re-checks the new boundary after returning.
  Future<void> _chooseCommunity() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityConfirmationView(),
      ),
    );
    if (mounted) unawaited(_check());
  }

  @override
  /// Geofence feature UI: either renders resident content or a gate screen with retry/community actions.
  Widget build(BuildContext context) {
    if (_insideBoundary) return widget.child;

    return _GeofenceBlockScreen(
      checking: _checking,
      message: _message,
      blockReason: _blockReason,
      hasCommunity:
          widget.user.communityId.trim().isNotEmpty ||
          widget.user.communityName.trim().isNotEmpty,
      onRetry: () => unawaited(_check()),
      onRequestLocation: () => unawaited(_requestLocationPermission()),
      onOpenAppSettings: () => unawaited(_openAppSettings()),
      onOpenLocationSettings: () => unawaited(_openLocationSettings()),
      onChooseCommunity: () => unawaited(_chooseCommunity()),
    );
  }
}

/// Geofence feature UI: explains why resident content is blocked and offers retry or community selection.
class _GeofenceBlockScreen extends StatelessWidget {
  const _GeofenceBlockScreen({
    required this.checking,
    required this.message,
    required this.blockReason,
    required this.hasCommunity,
    required this.onRetry,
    required this.onRequestLocation,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    required this.onChooseCommunity,
  });

  final bool checking;
  final String? message;
  final GeofenceGateBlockReason? blockReason;
  final bool hasCommunity;
  final VoidCallback onRetry;
  final VoidCallback onRequestLocation;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onChooseCommunity;

  /// Geofence feature UI: chooses a specific blocked-state title instead of a generic outside-area message.
  String get _title {
    if (checking) return 'Checking Your Area';
    return switch (blockReason) {
      GeofenceGateBlockReason.locationServicesOff =>
        'Turn On Location Services',
      GeofenceGateBlockReason.permissionDenied ||
      GeofenceGateBlockReason.permissionDeniedForever =>
        'Location Permission Needed',
      GeofenceGateBlockReason.missingCommunity => 'Choose Your Community',
      GeofenceGateBlockReason.outsideBoundary => 'Outside Community Area',
      _ => 'Location Check Needed',
    };
  }

  /// Geofence feature UI: chooses the primary recovery label based on the exact blocked reason.
  String get _primaryLabel {
    return switch (blockReason) {
      GeofenceGateBlockReason.locationServicesOff => 'Open Location Settings',
      GeofenceGateBlockReason.permissionDenied => 'Allow Location',
      GeofenceGateBlockReason.permissionDeniedForever => 'Open App Settings',
      GeofenceGateBlockReason.missingCommunity =>
        hasCommunity ? 'Change Community' : 'Choose Community',
      _ => 'Try Again',
    };
  }

  /// Geofence feature UI: chooses the primary recovery icon based on the exact blocked reason.
  IconData get _primaryIcon {
    return switch (blockReason) {
      GeofenceGateBlockReason.locationServicesOff =>
        Icons.location_disabled_rounded,
      GeofenceGateBlockReason.permissionDenied ||
      GeofenceGateBlockReason.permissionDeniedForever => Icons.settings_rounded,
      GeofenceGateBlockReason.missingCommunity => Icons.apartment_rounded,
      _ => Icons.refresh_rounded,
    };
  }

  /// Geofence feature UI: routes the primary action to permission settings, location settings, community selection, or manual retry.
  VoidCallback get _primaryAction {
    return switch (blockReason) {
      GeofenceGateBlockReason.locationServicesOff => onOpenLocationSettings,
      GeofenceGateBlockReason.permissionDenied => onRequestLocation,
      GeofenceGateBlockReason.permissionDeniedForever => onOpenAppSettings,
      GeofenceGateBlockReason.missingCommunity => onChooseCommunity,
      _ => onRetry,
    };
  }

  /// Geofence feature UI: explains why the hard gate exists so denial does not feel like a broken loop.
  Widget _buildRequirementCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user_rounded, color: _kBrandTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jirani requires location verification before residents can use the app. This confirms you are inside your registered community and keeps community features limited to real nearby residents.',
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  /// Geofence feature UI: builds the responsive blocked-state layout shown before resident access is allowed.
  Widget build(BuildContext context) {
    final padding = JiraniResponsive.pagePadding(context, top: 28, bottom: 24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: padding,
              child: JiraniResponsiveCenter(
                width: JiraniContentWidth.auth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight > padding.vertical
                        ? constraints.maxHeight - padding.vertical
                        : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Center(
                          child: Container(
                            width: JiraniResponsive.scale(context, 118),
                            height: JiraniResponsive.scale(context, 118),
                            decoration: BoxDecoration(
                              color: _kBrandTeal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              checking
                                  ? Icons.location_searching_rounded
                                  : Icons.location_off_rounded,
                              color: _kBrandTeal,
                              size: JiraniResponsive.scale(context, 62),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _kBrandTeal,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          checking
                              ? 'Please wait while Jirani confirms that you are inside your selected community.'
                              : message ??
                                    'Location verification is required before you can use Jirani.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (checking)
                          const Center(
                            child: CircularProgressIndicator(
                              color: _kBrandTeal,
                            ),
                          )
                        else ...[
                          _buildRequirementCard(context),
                          const SizedBox(height: 14),
                          _GateButton(
                            label: _primaryLabel,
                            icon: _primaryIcon,
                            background: _kBrandTeal,
                            foreground: Colors.white,
                            onPressed: _primaryAction,
                          ),
                          if (blockReason !=
                              GeofenceGateBlockReason.missingCommunity) ...[
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
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Geofence feature UI component: shared action button for retrying checks or choosing a community.
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
  /// Geofence feature UI component: renders one fixed-height gate action button.
  Widget build(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.minTouchTarget,
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
