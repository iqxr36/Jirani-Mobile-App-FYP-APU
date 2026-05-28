import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/services/verification_permission_prefs.dart';
import 'package:fyp_flutter_application/views/camera/camera_permission_view.dart';
import 'package:fyp_flutter_application/views/location/community_confirmation_view.dart';
import 'package:fyp_flutter_application/views/location/location_permission_view.dart';
import 'package:fyp_flutter_application/views/permissions/photos_documents_permission_view.dart';

enum VerificationPermissionStage {
  location,
  camera,
  photosDocuments,
}

/// Routes the once-per-install verification permission sequence.
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

  Future<void> _routeNext() async {
    final route = await _nextRoute();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(route);
  }

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
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
