// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : outside_geofence_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);

/// Geofence feature: returns true when the resident's GPS point is farther than the community radius.
bool isOutsideCommunityBoundary({
  required double userLatitude,
  required double userLongitude,
  required double communityLatitude,
  required double communityLongitude,
  required double radiusMeters,
}) {
  return Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        communityLatitude,
        communityLongitude,
      ) >
      radiusMeters;
}

/// Shown when the user's current location is outside the community boundary.
class OutsideGeofenceView extends StatefulWidget {
  const OutsideGeofenceView({super.key, required this.communityName});

  final String communityName;

  @override
  State<OutsideGeofenceView> createState() => _OutsideGeofenceViewState();
}

class _OutsideGeofenceViewState extends State<OutsideGeofenceView> {
  bool _returningToLogin = false;

  /// Geofence feature: signs the resident out when they cannot access the app from outside the community.
  Future<void> _returnToLogin() async {
    if (_returningToLogin) return;
    setState(() => _returningToLogin = true);

    final viewModel = context.read<AuthViewModel>();
    await viewModel.logout();
    if (!mounted) return;

    if (viewModel.firebaseUser != null) {
      setState(() => _returningToLogin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                'Could not return to login. Please try again.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Geofence feature UI: displays the outside-area illustration or a fallback icon.
  Widget _buildIllustration(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.clamp(context, 220, minFactor: 0.78),
      width: double.infinity,
      child: Image.asset(
        'assets/Location2.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(
            Icons.location_off_rounded,
            size: 112,
            color: Color(0xFFEA4A5B),
          ),
        ),
      ),
    );
  }

  /// Geofence feature UI: summarizes the selected community and the current outside-boundary status.
  Widget _buildResultCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'COMMUNITY',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    widget.communityName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: context.residentOutline()),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'STATUS',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 4, 9, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFFFBAC0),
                        child: Icon(
                          Icons.priority_high_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Outside Boundary',
                        style: TextStyle(
                          color: context.appInk,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Geofence feature UI: returns to the checking screen so the location can be verified again.
  Widget _buildTryAgainButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _returningToLogin ? null : () => Navigator.of(context).pop(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 18),
            SizedBox(width: 4),
            Text(
              'Try Again',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  /// Geofence feature UI: lets the resident leave the gated flow and go back to login.
  Widget _buildReturnToLoginButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF787880).withValues(alpha: 0.16),
          foregroundColor: _kBrandTeal,
          disabledForegroundColor: _kBrandTeal.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _returningToLogin ? null : _returnToLogin,
        child: _returningToLogin
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kBrandTeal,
                ),
              )
            : const Text(
                'Return to Login',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }

  @override
  /// Geofence feature UI: renders the blocked screen when the resident is outside the allowed community radius.
  Widget build(BuildContext context) {
    final padding = JiraniResponsive.pagePadding(context, top: 16, bottom: 24);

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
                      children: [
                        const Text(
                          'Outside Area',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _kBrandTeal,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildIllustration(context),
                        const SizedBox(height: 12),
                        Text(
                          'You appear to be outside your\nselected community.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Make sure that you are closer to your\n'
                          'residence area and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildResultCard(context),
                        const Spacer(),
                        const SizedBox(height: 24),
                        _buildTryAgainButton(),
                        const SizedBox(height: 9),
                        _buildReturnToLoginButton(),
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
