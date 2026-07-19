// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_process_content.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../verification_process_view.dart';

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
    final requestStatus = request?.status;
    if (requestStatus == AppConstants.verificationVerified ||
        requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending) {
      return false;
    }
    if (requestStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRequestCancelled) {
      return true;
    }

    final userStatus = user?.verificationStatus;
    if (userStatus == AppConstants.verificationPending) {
      return true;
    }
    if (userStatus == AppConstants.verificationVerified ||
        userStatus == AppConstants.verificationSubmitted) {
      return false;
    }
    return request == null ||
        userStatus == AppConstants.verificationPending ||
        userStatus == AppConstants.verificationRejected;
  }

  String _documentActionLabel(AppUser? user, VerificationRequest? request) {
    final requestStatus = request?.status;
    if (requestStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRequestCancelled) {
      return 'Submit Updated Documents';
    }
    final userStatus = user?.verificationStatus;
    if (userStatus == AppConstants.verificationRejected) {
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
    final requestStatus = request?.status;
    if (requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending ||
        requestStatus == AppConstants.verificationVerified ||
        requestStatus == AppConstants.verificationRejected ||
        requestStatus == AppConstants.verificationRequestCancelled) {
      return request;
    }
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
