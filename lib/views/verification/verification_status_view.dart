import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/viewmodels/verification_viewmodel.dart';
import 'package:jirani/views/verification/verification_process_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

Color _surface(BuildContext context) => context.isDarkUi
    ? context.residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
    : Colors.white;

Color _outline(BuildContext context, {double alpha = 0.18}) => context.isDarkUi
    ? context.residentScheme.outlineVariant
    : Colors.black.withValues(alpha: alpha);

class VerificationStatusView extends StatelessWidget {
  const VerificationStatusView({
    super.key,
    this.backToProcessReplacement = true,
  });

  final bool backToProcessReplacement;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerificationViewModel>(
      create: (_) => VerificationViewModel()..loadCurrentRequest(),
      child: _VerificationStatusContent(
        backToProcessReplacement: backToProcessReplacement,
      ),
    );
  }
}

class _VerificationStatusContent extends StatelessWidget {
  const _VerificationStatusContent({required this.backToProcessReplacement});

  final bool backToProcessReplacement;

  Future<void> _refresh(BuildContext context) async {
    await context.read<AuthViewModel>().refreshCurrentUser();
    if (!context.mounted) return;
    await context.read<VerificationViewModel>().loadCurrentRequest();
  }

  void _backToProcess(BuildContext context) {
    if (!backToProcessReplacement && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const VerificationProcessView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final verificationVm = context.watch<VerificationViewModel>();
    final request = verificationVm.currentRequest;
    final status = _StatusPresentation.from(
      userStatus: user?.verificationStatus,
      request: request,
    );
    final bottomInset = JiraniResponsive.bottomInset(context);
    final scheme = context.residentScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 18, 15, 10 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: status.accent,
                      onRefresh: () => _refresh(context),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (verificationVm.isLoading && request == null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 210),
                                  child: CircularProgressIndicator(
                                    color: _kBrandTeal,
                                  ),
                                )
                              else ...[
                                Image.asset(
                                  status.assetPath,
                                  width: status.imageWidth,
                                  height: status.imageHeight,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        status.fallbackIcon,
                                        size: 150,
                                        color: status.accent,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _StatusChip(status: status),
                                const SizedBox(height: 12),
                                Text(
                                  status.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (status.subtitle != null) ...[
                                  Text(
                                    status.subtitle!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.appInk,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                status.buildDetailsCard(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _backToProcess(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Back to Verification Process',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _StatusPresentation status;

  @override
  Widget build(BuildContext context) {
    final chipInk = context.onAccent(status.accent);
    return Container(
      height: 21,
      padding: const EdgeInsets.only(left: 3, right: 8),
      decoration: BoxDecoration(
        color: status.accent.withValues(alpha: status.chipOpacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: status.accent.withValues(alpha: 0.36),
            child: Icon(status.chipIcon, size: 10, color: chipInk),
          ),
          const SizedBox(width: 5),
          Text(
            status.chipLabel,
            style: TextStyle(
              color: chipInk,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 84),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline(context)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.appInk,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

class _RejectedReasonCard extends StatelessWidget {
  const _RejectedReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 95),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 15),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFFFF8F98),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Reason for Rejection',
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            thickness: 1,
            color: _outline(context, alpha: 0.22),
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.assetPath,
    required this.title,
    required this.chipLabel,
    required this.chipIcon,
    required this.accent,
    required this.details,
    required this.fallbackIcon,
    this.subtitle,
    this.imageWidth = 248,
    this.imageHeight = 248,
    this.chipOpacity = 0.20,
  });

  final String assetPath;
  final String title;
  final String chipLabel;
  final IconData chipIcon;
  final Color accent;
  final Widget details;
  final IconData fallbackIcon;
  final String? subtitle;
  final double imageWidth;
  final double imageHeight;
  final double chipOpacity;

  Widget buildDetailsCard() => details;

  static _StatusPresentation from({
    required String? userStatus,
    required VerificationRequest? request,
  }) {
    final requestStatus = request?.status;
    final normalizedStatus = _effectiveStatus(userStatus, requestStatus);

    if (normalizedStatus == AppConstants.verificationPending) {
      return const _StatusPresentation(
        assetPath: 'assets/pending review.png',
        title: 'Verification Not Started',
        chipLabel: 'Pending',
        chipIcon: Icons.hourglass_empty_rounded,
        accent: _kBrandTeal,
        fallbackIcon: Icons.fact_check_outlined,
        imageWidth: 265,
        imageHeight: 246,
        details: _MessageCard(
          text:
              'Submit proof of residence to start verification for your selected community.',
        ),
      );
    }

    if (normalizedStatus == AppConstants.verificationRejected) {
      final reason = request?.rejectionReason?.trim();
      return _StatusPresentation(
        assetPath: 'assets/verification rejected.png',
        title: 'Verification Failed',
        chipLabel: 'Verification Failed',
        chipIcon: Icons.priority_high_rounded,
        accent: const Color(0xFFFF8F98),
        fallbackIcon: Icons.cancel_rounded,
        subtitle: 'Your proof of residence could not be approved.',
        imageWidth: 270,
        imageHeight: 238,
        chipOpacity: 0.16,
        details: _RejectedReasonCard(
          reason: reason == null || reason.isEmpty
              ? 'The uploaded document was blurry or not a valid proof of address.'
              : reason,
        ),
      );
    }

    if (normalizedStatus == AppConstants.verificationVerified) {
      return _StatusPresentation(
        assetPath: 'assets/verification approved.png',
        title: 'Verification Approved',
        chipLabel: 'Verified',
        chipIcon: Icons.check_rounded,
        accent: const Color(0xFF34C759),
        fallbackIcon: Icons.verified_rounded,
        imageWidth: 270,
        imageHeight: 238,
        chipOpacity: 0.18,
        details: const _MessageCard(
          text:
              'Your residency has been verified. You now have full access to your community features.',
        ),
      );
    }

    return const _StatusPresentation(
      assetPath: 'assets/pending review.png',
      title: 'Verification Under Review',
      chipLabel: 'Pending Review',
      chipIcon: Icons.hourglass_bottom_rounded,
      accent: Color(0xFFFFCC00),
      fallbackIcon: Icons.manage_search_rounded,
      imageWidth: 265,
      imageHeight: 246,
      details: _MessageCard(
        text:
            'Your request has been submitted. You can browse limited features while waiting. Usually reviewed within 24 hours.',
      ),
    );
  }

  static String _effectiveStatus(String? userStatus, String? requestStatus) {
    if (userStatus == AppConstants.verificationPending) {
      return AppConstants.verificationPending;
    }
    if (userStatus == AppConstants.verificationVerified) {
      return AppConstants.verificationVerified;
    }
    if (userStatus == AppConstants.verificationRejected) {
      return AppConstants.verificationRejected;
    }
    if (requestStatus == AppConstants.verificationVerified) {
      return AppConstants.verificationVerified;
    }
    if (requestStatus == AppConstants.verificationRejected) {
      return AppConstants.verificationRejected;
    }
    return AppConstants.verificationSubmitted;
  }
}
