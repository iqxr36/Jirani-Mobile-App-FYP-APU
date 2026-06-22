import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/services/geofence_gate_service.dart';
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
  final GeofenceGateService _gateService = GeofenceGateService();

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

    final wasInsideBoundary = _insideBoundary;
    setState(() {
      _checking = !wasInsideBoundary;
      _message = null;
    });

    final result = await _gateService.checkResidentAccess(widget.user);

    if (!mounted) return;
    if (result.insideBoundary && !widget.user.locationVerified) {
      try {
        await context.read<AuthViewModel>().markLocationVerified();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _checking = false;
          _insideBoundary = false;
          _message = 'Could not save location verification. Try again.';
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _insideBoundary = result.insideBoundary;
      _message = result.message;
    });
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
    if (_insideBoundary) return widget.child;

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
                          checking
                              ? 'Checking Your Area'
                              : 'Outside Community Area',
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
            );
          },
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
