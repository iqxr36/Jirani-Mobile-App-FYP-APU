import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/data/repositories/verification_permission_repository.dart';
import 'package:jirani/services/verification_permission_prefs.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

/// Photos and documents permission step for the verification onboarding flow.
class PhotosDocumentsPermissionView extends StatefulWidget {
  const PhotosDocumentsPermissionView({super.key, this.nextBuilder});

  final WidgetBuilder? nextBuilder;

  @override
  State<PhotosDocumentsPermissionView> createState() =>
      _PhotosDocumentsPermissionViewState();
}

class _PhotosDocumentsPermissionViewState
    extends State<PhotosDocumentsPermissionView> {
  final _permissionRepository = VerificationPermissionRepository();
  bool _allowing = false;
  bool _skipping = false;

  bool get _buttonsLocked => _allowing || _skipping;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _completePermissionStep() async {
    await VerificationPermissionPrefs.markPhotosDocumentsShown();
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

  Future<void> _savePreference({
    required bool enabled,
    required String status,
  }) async {
    await _permissionRepository.savePhotosDocumentsPreference(
      enabled: enabled,
      status: status,
    );
  }

  Future<void> _handleAllowAccess() async {
    if (_buttonsLocked) return;
    setState(() => _allowing = true);

    try {
      if (kIsWeb) {
        await _savePreference(enabled: true, status: 'notRequired');
        if (!mounted) return;
        await _completePermissionStep();
        return;
      }

      final photosStatus = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();
      final statuses = [photosStatus, storageStatus];
      final authorized = statuses.any(
        (status) => status.isGranted || status.isLimited,
      );
      final blocked = statuses.any((status) => status.isPermanentlyDenied);

      await _savePreference(
        enabled: authorized,
        status: authorized ? 'authorized' : 'denied',
      );
      if (!mounted) return;

      if (blocked && !authorized) {
        _showSnack(
          'Photos and document access is blocked. You can enable it in device settings.',
        );
      } else if (!authorized) {
        _showSnack(
          'Photos and document access was not granted. You can still choose files later from the picker.',
        );
      }
      await _completePermissionStep();
    } catch (_) {
      if (mounted) {
        _showSnack('Could not update photos and document access.');
        await _completePermissionStep();
      }
    } finally {
      if (mounted) setState(() => _allowing = false);
    }
  }

  Future<void> _handleMaybeLater() async {
    if (_buttonsLocked) return;
    setState(() => _skipping = true);

    try {
      await _savePreference(enabled: false, status: 'skipped');
      if (!mounted) return;
      await _completePermissionStep();
    } catch (_) {
      if (mounted) {
        _showSnack('Could not save your preference.');
        await _completePermissionStep();
      }
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  Widget _buildIllustration(BuildContext context) {
    final softTeal = _kBrandTeal.withValues(alpha: 0.14);
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 136,
            height: 158,
            decoration: BoxDecoration(
              color: context.glassFill(),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: softTeal, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _kBrandTeal.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Positioned(
            top: 48,
            child: Icon(
              Icons.photo_library_outlined,
              size: 54,
              color: _kBrandTeal,
            ),
          ),
          Positioned(
            bottom: 48,
            child: Icon(Icons.description_outlined, size: 42, color: softTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Allow Photos and Documents',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _kBrandTeal,
        fontSize: 24,
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
          'Photos and documents are used when you upload proof of residence and supporting verification files.',
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

  Widget _buildAllowButton() {
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
        onPressed: _buttonsLocked ? null : _handleAllowAccess,
        child: _allowing
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
                    'Allowing...',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              )
            : const Text(
                'Allow Access',
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
                        _buildIllustration(context),
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
                        _buildAllowButton(),
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
