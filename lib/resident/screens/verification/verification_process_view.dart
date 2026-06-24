import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/logic/verification_viewmodel.dart';
import 'package:jirani/resident/screens/verification/residency_verification_view.dart';
import 'package:jirani/resident/screens/verification/verification_status_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

Color _surface(BuildContext context) => context.isDarkUi
    ? context.residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
    : Colors.white;

Color _outline(BuildContext context) => context.isDarkUi
    ? context.residentScheme.outlineVariant
    : Colors.black.withValues(alpha: 0.20);

class VerificationProcessView extends StatelessWidget {
  const VerificationProcessView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerificationViewModel>(
      create: (_) => VerificationViewModel()..loadCurrentRequest(),
      child: const _VerificationProcessContent(),
    );
  }
}

class _VerificationProcessContent extends StatelessWidget {
  const _VerificationProcessContent();

  Future<void> _refresh(BuildContext context) async {
    await context.read<AuthViewModel>().refreshCurrentUser();
    if (!context.mounted) return;
    await context.read<VerificationViewModel>().loadCurrentRequest();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final verificationVm = context.watch<VerificationViewModel>();
    final request = verificationVm.currentRequest;
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: RefreshIndicator(
                      color: _kBrandTeal,
                      onRefresh: () => _refresh(context),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Complete a few quick steps to unlock full access to your community.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appInk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 35),
                              if (verificationVm.isLoading && request == null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 80),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: _kBrandTeal,
                                    ),
                                  ),
                                )
                              else ...[
                                Builder(
                                  builder: (context) {
                                    final steps = _buildSteps(user, request);
                                    return Column(
                                      children: [
                                        _ProgressSummaryCard(steps: steps),
                                        const SizedBox(height: 16),
                                        _VerificationTimeline(steps: steps),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                                if (verificationVm.errorMessage != null)
                                  _StatusMessageCard(
                                    icon: Icons.error_outline_rounded,
                                    text: verificationVm.errorMessage!,
                                    iconColor: const Color(0xFFB00020),
                                  )
                                else
                                  const _StatusMessageCard(
                                    icon: Icons.lock_person_rounded,
                                    text:
                                        'Your information is only used for residency verification and community safety.',
                                    iconColor: _kBrandTeal,
                                  ),
                                if (_needsDocumentAction(user, request)) ...[
                                  const SizedBox(height: 12),
                                  _DocumentActionButton(
                                    label: _documentActionLabel(user, request),
                                    onPressed: () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const ResidencyVerificationView(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (_hasStatusUpdate(user, request)) ...[
                                  const SizedBox(height: 12),
                                  _LatestUpdateButton(
                                    onPressed: () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const VerificationStatusView(
                                                backToProcessReplacement: false,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ),
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

  bool _needsDocumentAction(AppUser? user, VerificationRequest? request) {
    final userStatus = user?.verificationStatus;
    if (userStatus == AppConstants.verificationPending) {
      return true;
    }

    final requestStatus = request?.status;
    if (userStatus == AppConstants.verificationVerified ||
        requestStatus == AppConstants.verificationVerified ||
        userStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending) {
      return false;
    }
    return request == null ||
        userStatus == AppConstants.verificationPending ||
        userStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRequestCancelled;
  }

  String _documentActionLabel(AppUser? user, VerificationRequest? request) {
    final userStatus = user?.verificationStatus;
    if (userStatus == AppConstants.verificationPending) {
      return 'Submit Verification Documents';
    }

    final requestStatus = request?.status;
    if (userStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRequestCancelled) {
      return 'Submit Updated Documents';
    }
    return 'Submit Verification Documents';
  }

  bool _hasStatusUpdate(AppUser? user, VerificationRequest? request) {
    final userStatus = user?.verificationStatus;
    final effectiveRequest = _effectiveRequestForAccount(user, request);
    return effectiveRequest != null ||
        userStatus == AppConstants.verificationSubmitted ||
        userStatus == AppConstants.verificationRejected ||
        userStatus == AppConstants.verificationVerified;
  }

  VerificationRequest? _effectiveRequestForAccount(
    AppUser? user,
    VerificationRequest? request,
  ) {
    if (user?.verificationStatus == AppConstants.verificationPending) {
      return null;
    }
    return request;
  }

  List<_ProgressStepData> _buildSteps(
    AppUser? user,
    VerificationRequest? request,
  ) {
    final userStatus =
        user?.verificationStatus ?? AppConstants.verificationPending;
    final effectiveRequest = _effectiveRequestForAccount(user, request);
    final requestStatus = effectiveRequest?.status ?? userStatus;
    final hasRequest = effectiveRequest != null;
    final requestCommunityName = effectiveRequest?.communityName.trim() ?? '';
    final userCommunityName = user?.communityName.trim() ?? '';
    final communityName = requestCommunityName.isNotEmpty
        ? requestCommunityName
        : userCommunityName;
    final submittedDate = hasRequest
        ? _formatDate(effectiveRequest.submittedAt)
        : null;
    final isVerified =
        userStatus == AppConstants.verificationVerified ||
        requestStatus == AppConstants.verificationVerified;
    final isRejected =
        userStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRejected;
    final isCancelled =
        requestStatus == AppConstants.verificationRequestCancelled;
    final isSubmitted =
        requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending;
    final locationVerified = user?.locationVerified == true;

    return [
      _ProgressStepData(
        title: 'Confirm Your Community',
        description: communityName.isEmpty
            ? 'Select or confirm the residence where you currently live.'
            : '$communityName has been selected for this verification.',
        icon: Icons.home_rounded,
        state: communityName.isEmpty ? _StepState.current : _StepState.complete,
      ),
      _ProgressStepData(
        title: 'Check Your Location',
        description: locationVerified
            ? 'Your selected community location check is complete.'
            : 'We verify that you are near your selected community.',
        icon: Icons.location_on_rounded,
        state: locationVerified
            ? _StepState.complete
            : communityName.isEmpty
            ? _StepState.waiting
            : _StepState.current,
      ),
      _ProgressStepData(
        title: 'Upload Proof of Residence',
        description: hasRequest
            ? 'Submitted $submittedDate for management review.'
            : 'Submit a clear document such as a utility bill, tenancy agreement, or access card.',
        icon: Icons.badge_outlined,
        state: hasRequest && !isCancelled
            ? _StepState.complete
            : locationVerified
            ? _StepState.current
            : _StepState.waiting,
      ),
      _ProgressStepData(
        title: 'Management Review',
        description: _reviewDescription(
          effectiveRequest,
          isVerified,
          isRejected,
          isCancelled,
          isSubmitted,
        ),
        icon: Icons.folder_outlined,
        state: isVerified
            ? _StepState.complete
            : isRejected
            ? _StepState.rejected
            : isSubmitted
            ? _StepState.current
            : _StepState.waiting,
      ),
    ];
  }

  String _reviewDescription(
    VerificationRequest? request,
    bool isVerified,
    bool isRejected,
    bool isCancelled,
    bool isSubmitted,
  ) {
    if (isVerified) {
      final reviewedAt = request?.reviewedAt;
      return reviewedAt == null
          ? 'Your residency verification is complete.'
          : 'Approved on ${_formatDate(reviewedAt)}. Full community access is unlocked.';
    }
    if (isRejected) {
      final reason = request?.rejectionReason?.trim();
      return reason == null || reason.isEmpty
          ? 'Your request needs attention. Please submit updated proof.'
          : reason;
    }
    if (isCancelled) {
      return 'This request was cancelled. Submit a new request to continue.';
    }
    if (isSubmitted) {
      return 'Your request is under management review. Pull down to refresh the latest update.';
    }
    return 'Your request will be reviewed before your verification is complete.';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 34,
              ),
            ),
          ),
          const Text(
            'Verification Process',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.steps});

  final List<_ProgressStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({required this.steps});

  final List<_ProgressStepData> steps;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final completed = steps
        .where((step) => step.state == _StepState.complete)
        .length;
    final rejected = steps.any((step) => step.state == _StepState.rejected);
    final accent = rejected ? const Color(0xFFE5484D) : _kBrandTeal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              rejected
                  ? Icons.error_outline_rounded
                  : Icons.verified_user_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rejected
                      ? 'Verification Needs Attention'
                      : '$completed of ${steps.length} Steps Complete',
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  rejected
                      ? 'Review the highlighted step and submit updated proof.'
                      : 'Completed tasks stay highlighted as you move forward.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final _ProgressStepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = _StepColors.forState(context, step.state);
    final ink = context.appInk;
    final muted = context.appMuted;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isLast ? 84 : 116),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 67,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast)
                    Positioned(
                      top: 67,
                      bottom: 0,
                      child: SizedBox(
                        width: 2,
                        child: CustomPaint(
                          painter: _DashedLinePainter(color: colors.connector),
                        ),
                      ),
                    ),
                  Container(
                    width: 67,
                    height: 67,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, size: 28, color: colors.icon),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ),
                          _StepChip(label: colors.label, color: colors.icon),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.description,
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestUpdateButton extends StatelessWidget {
  const _LatestUpdateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_active_outlined, size: 17),
        label: const Text(
          'View Latest Update',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.residentScheme.primary,
          side: BorderSide(color: context.residentScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DocumentActionButton extends StatelessWidget {
  const _DocumentActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StatusMessageCard extends StatelessWidget {
  const _StatusMessageCard({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _outline(context)),
      ),
      padding: const EdgeInsets.fromLTRB(13, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 19),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dashHeight = 8.0;
    const dashGap = 4.0;
    var y = 0.0;
    final x = size.width / 2;

    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dashHeight).clamp(0, size.height)),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressStepData {
  const _ProgressStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.state,
  });

  final String title;
  final String description;
  final IconData icon;
  final _StepState state;
}

enum _StepState { complete, current, waiting, rejected }

class _StepColors {
  const _StepColors({
    required this.background,
    required this.icon,
    required this.cardBackground,
    required this.border,
    required this.connector,
    required this.label,
  });

  final Color background;
  final Color icon;
  final Color cardBackground;
  final Color border;
  final Color connector;
  final String label;

  static _StepColors forState(BuildContext context, _StepState state) {
    if (context.isDarkUi) {
      final scheme = context.residentScheme;
      switch (state) {
        case _StepState.complete:
          return _StepColors(
            background: scheme.primaryContainer.withValues(alpha: 0.72),
            icon: scheme.primary,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.outlineVariant,
            connector: scheme.primary,
            label: 'DONE',
          );
        case _StepState.current:
          return _StepColors(
            background: scheme.primary.withValues(alpha: 0.28),
            icon: scheme.primary,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.primary.withValues(alpha: 0.42),
            connector: scheme.primary.withValues(alpha: 0.42),
            label: 'NOW',
          );
        case _StepState.rejected:
          return _StepColors(
            background: scheme.errorContainer.withValues(alpha: 0.72),
            icon: scheme.error,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.error.withValues(alpha: 0.42),
            connector: scheme.error,
            label: 'FIX',
          );
        case _StepState.waiting:
          return _StepColors(
            background: scheme.surfaceContainerHighest,
            icon: scheme.onSurfaceVariant,
            cardBackground: scheme.surfaceContainerHighest.withValues(
              alpha: 0.92,
            ),
            border: scheme.outlineVariant,
            connector: scheme.outlineVariant.withValues(alpha: 0.55),
            label: 'WAIT',
          );
      }
    }

    switch (state) {
      case _StepState.complete:
        return const _StepColors(
          background: Color(0xFFD7F6DE),
          icon: Color(0xFF157A38),
          cardBackground: Color(0xFFF3FCF5),
          border: Color(0xFFB8E8C5),
          connector: Color(0xFF34C759),
          label: 'DONE',
        );
      case _StepState.current:
        return const _StepColors(
          background: Color(0x4083C5BE),
          icon: _kBrandTeal,
          cardBackground: Color(0xFFF2FBFA),
          border: Color(0x6683C5BE),
          connector: Color(0x6683C5BE),
          label: 'NOW',
        );
      case _StepState.rejected:
        return const _StepColors(
          background: Color(0xFFFFDFE2),
          icon: Color(0xFFE5484D),
          cardBackground: Color(0xFFFFF5F6),
          border: Color(0xFFFFBAC0),
          connector: Color(0xFFFF8F98),
          label: 'FIX',
        );
      case _StepState.waiting:
        return const _StepColors(
          background: Color(0xFFEFEFF0),
          icon: Color(0xFF737378),
          cardBackground: Colors.white,
          border: Color(0xFFE3E3E6),
          connector: Color(0x4D3C3C43),
          label: 'WAIT',
        );
    }
  }
}
