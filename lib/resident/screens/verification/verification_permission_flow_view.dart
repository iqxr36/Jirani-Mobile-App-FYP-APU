// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_permission_flow_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/services/verification_permission_prefs.dart';
import 'package:jirani/resident/screens/camera/camera_permission_view.dart';
import 'package:jirani/resident/screens/location/community_confirmation_view.dart';
import 'package:jirani/resident/screens/location/location_permission_view.dart';
import 'package:jirani/resident/screens/permissions/photos_documents_permission_view.dart';

enum VerificationPermissionStage { location, camera, photosDocuments }

/// Routes the once-per-install verification permission sequence.
// Verification onboarding feature: routes residents through notification, camera, photos, and document upload steps.
class VerificationPermissionFlowView extends StatefulWidget {
  const VerificationPermissionFlowView({
    super.key,
    this.startAt = VerificationPermissionStage.location,
  });

  final VerificationPermissionStage startAt;

  @override
  State<VerificationPermissionFlowView> createState() =>
      _VerificationPermissionFlowViewState();
}

class _VerificationPermissionFlowViewState
    extends State<VerificationPermissionFlowView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeNext());
  }

  // Verification onboarding feature: computes and opens the next required permission/upload screen.
  Future<void> _routeNext() async {
    final route = await _nextRoute();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(route);
  }

  // Verification onboarding feature: chooses which permission screen is next based on saved preferences.
  Future<MaterialPageRoute<void>> _nextRoute() async {
    final shouldStartAtLocation =
        widget.startAt == VerificationPermissionStage.location;
    final shouldStartAtCamera =
        shouldStartAtLocation ||
        widget.startAt == VerificationPermissionStage.camera;

    if (shouldStartAtLocation &&
        !await VerificationPermissionPrefs.wasLocationShown()) {
      return MaterialPageRoute<void>(
        builder: (_) => LocationPermissionView(
          isInitialOnboarding: false,
          nextBuilder: (_) => const VerificationPermissionFlowView(
            startAt: VerificationPermissionStage.camera,
          ),
        ),
      );
    }

    if (shouldStartAtCamera &&
        !await VerificationPermissionPrefs.wasCameraShown()) {
      return MaterialPageRoute<void>(
        builder: (_) => CameraPermissionView(
          nextBuilder: (_) => const VerificationPermissionFlowView(
            startAt: VerificationPermissionStage.photosDocuments,
          ),
        ),
      );
    }

    if (!await VerificationPermissionPrefs.wasPhotosDocumentsShown()) {
      return MaterialPageRoute<void>(
        builder: (_) => PhotosDocumentsPermissionView(
          nextBuilder: (_) => const CommunityConfirmationView(),
        ),
      );
    }

    return MaterialPageRoute<void>(
      builder: (_) => const CommunityConfirmationView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
