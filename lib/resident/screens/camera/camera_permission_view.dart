import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/data/repositories/verification_permission_repository.dart';
import 'package:jirani/resident/services/verification_permission_prefs.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

/// Camera permission — Figma Group 25: illustration, title, info card, enable / maybe later.
class CameraPermissionView extends StatefulWidget {
  const CameraPermissionView({super.key, this.nextBuilder});

  final WidgetBuilder? nextBuilder;

  @override
  State<CameraPermissionView> createState() => _CameraPermissionViewState();
}

class _CameraPermissionViewState extends State<CameraPermissionView> {
  final _permissionRepository = VerificationPermissionRepository();
  bool _enabling = false;
  bool _skipping = false;

  bool get _buttonsLocked => _enabling || _skipping;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _completePermissionFlow() async {
    await VerificationPermissionPrefs.markCameraShown();
    if (!mounted) return;
    final nextBuilder = widget.nextBuilder;
    if (nextBuilder == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: nextBuilder),
    );
  }

  Future<void> _saveCameraPreference({
    required bool enabled,
    required String status,
  }) async {
    await _permissionRepository.saveCameraPreference(
      enabled: enabled,
      status: status,
    );
  }

  Future<void> _handleEnableCamera() async {
    if (_buttonsLocked) return;
    setState(() => _enabling = true);
    try {
      final status = await Permission.camera.request();

      if (!mounted) return;

      if (status.isGranted || status.isLimited) {
        await _saveCameraPreference(enabled: true, status: 'authorized');
        if (!mounted) return;
        await _completePermissionFlow();
      } else if (status.isPermanentlyDenied) {
        await _saveCameraPreference(enabled: false, status: 'denied');
        if (!mounted) return;
        _showSnack(
          'Camera access is blocked. You can enable it in your device settings.',
        );
        await _completePermissionFlow();
      } else {
        await _saveCameraPreference(enabled: false, status: 'denied');
        if (!mounted) return;
        _showSnack(
          'Camera access was not granted. You can enable it later from settings.',
        );
        await _completePermissionFlow();
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not update camera settings.');
        await _completePermissionFlow();
      }
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  Future<void> _handleMaybeLater() async {
    if (_buttonsLocked) return;
    setState(() => _skipping = true);
    try {
      await _saveCameraPreference(enabled: false, status: 'skipped');
      if (!mounted) return;
      await _completePermissionFlow();
    } catch (_) {
      if (mounted) {
        _showSnack('Could not save your preference.');
        await _completePermissionFlow();
      }
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Image.asset(
        'assets/cam-perm.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholderIllustration(),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    final softTeal = _kBrandTeal.withValues(alpha: 0.14);
    return Stack(
      alignment: Alignment.center,
      children: [Icon(Icons.camera_alt_outlined, size: 88, color: softTeal)],
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Enable Camera Access',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _kBrandTeal,
        fontSize: 25,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Text(
          'Your phone camera will be used to show evidences and proofs for borrowing, lending, and task Services.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appInk,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  Widget _buildEnableCameraButton() {
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
        onPressed: _buttonsLocked ? null : _handleEnableCamera,
        child: _enabling
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
                    'Enabling...',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              )
            : const Text(
                'Enable Camera',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildMaybeLaterButton() {
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
        onPressed: _buttonsLocked ? null : _handleMaybeLater,
        child: const Text(
          'Maybe Later',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
                        const SizedBox(height: 28),
                        _buildIllustration(),
                        const SizedBox(height: 22),
                        _buildTitle(),
                        const SizedBox(height: 22),
                        _buildInfoCard(context),
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
                        const SizedBox(height: 24),
                        _buildEnableCameraButton(),
                        const SizedBox(height: 8),
                        _buildMaybeLaterButton(),
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
