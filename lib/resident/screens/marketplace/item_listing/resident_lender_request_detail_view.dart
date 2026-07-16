part of '../resident_item_listing_view.dart';

/// Marketplace lender screen: lets the owner approve, hand over, inspect return, dispute damage, and review a borrow request.
class ResidentLenderRequestDetailView extends StatefulWidget {
  const ResidentLenderRequestDetailView({
    super.key,
    required this.initialRequest,
  });

  final BorrowRequest initialRequest;

  @override
  State<ResidentLenderRequestDetailView> createState() =>
      _ResidentLenderRequestDetailViewState();
}

class _ResidentLenderRequestDetailViewState
    extends State<ResidentLenderRequestDetailView> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _returnCodeController = TextEditingController();
  final TextEditingController _ownerReturnNotesController =
      TextEditingController();
  final TextEditingController _minorDeductionController =
      TextEditingController();
  final TextEditingController _minorIssueReasonController =
      TextEditingController();
  final TextEditingController _majorDamageReasonController =
      TextEditingController();
  final TextEditingController _depositReasonController =
      TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  String _conditionBefore = AppConstants.borrowConditionBeforeGood;
  String _conditionAfter = AppConstants.borrowConditionAfterSame;
  String _depositDecision = AppConstants.depositDecisionReturnDeposit;
  int _rating = 5;
  bool _localReviewSubmitted = false;
  XFile? _handoverProof;
  XFile? _returnIssueProof;

  @override
  /// Marketplace lender screen lifecycle: disposes form controllers used across handover, return, dispute, and review forms.
  void dispose() {
    _returnCodeController.dispose();
    _ownerReturnNotesController.dispose();
    _minorDeductionController.dispose();
    _minorIssueReasonController.dispose();
    _majorDamageReasonController.dispose();
    _depositReasonController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  /// Marketplace lender screen: opens the borrower's public profile from the request detail header.
  void _openBorrowerProfile(BorrowRequest request) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublicResidentProfileView(
          userId: request.borrowerId,
          fallbackName: request.borrowerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Consumer<BorrowRequestProvider>(
            builder: (context, provider, _) {
              final request = provider.incomingRequests.firstWhere(
                (candidate) => candidate.id == widget.initialRequest.id,
                orElse: () => widget.initialRequest,
              );
              final pending = _requestIsPending(request);
              final tracking =
                  !pending &&
                  request.status != AppConstants.borrowStatusRejected &&
                  request.status != AppConstants.borrowStatusCancelled;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _InsetContent(
                      sideInset: sideInset,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _ScreenTitleBar(
                            title: tracking
                                ? 'Transaction Tracking'
                                : 'Request Details',
                            onBack: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 18),
                          _GlassPanel(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    _RequestItemThumb(
                                      request: request,
                                      size: 94,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.itemTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: context.appInk,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _StatusPill(
                                            label: _requestStatusLabel(request),
                                            tone: _requestStatusTone(request),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const _SectionLabel('Borrower'),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _RequestBorrowerAvatar(
                                      request: request,
                                      radius: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowerSummary(request: request),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _TinyTextButton(
                                    label: 'View Profile',
                                    icon: Icons.person_search_rounded,
                                    onTap: () => _openBorrowerProfile(request),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionLabel('Borrowing Details'),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  label: 'Dates',
                                  value: _requestDateRange(request),
                                ),
                                if (request.pickupTime.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _DetailRow(
                                    label: 'Pickup time',
                                    value: request.pickupTime.trim(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _RequestMoneyRow(request: request),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionLabel('Borrower Message'),
                                const SizedBox(height: 8),
                                Text(
                                  request.message.trim().isEmpty
                                      ? 'No message provided.'
                                      : request.message.trim(),
                                  style: TextStyle(
                                    color: context.appMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (pending)
                            Row(
                              children: [
                                Expanded(
                                  child: _DangerButton(
                                    label: 'Reject Request',
                                    icon: Icons.close_rounded,
                                    onTap: user == null || provider.isLoading
                                        ? null
                                        : () => _rejectRequestFromDetail(
                                            context,
                                            request,
                                            user,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PrimaryButton(
                                    label: provider.isLoading
                                        ? 'Approving...'
                                        : 'Approve Request',
                                    icon: Icons.check_rounded,
                                    onTap: user == null || provider.isLoading
                                        ? null
                                        : () => _approveRequestFromDetail(
                                            context,
                                            request,
                                            user,
                                          ),
                                  ),
                                ),
                              ],
                            )
                          else
                            _LenderTransactionBody(
                              request: request,
                              provider: provider,
                              conditionBefore: _conditionBefore,
                              conditionAfter: _conditionAfter,
                              depositDecision: _depositDecision,
                              returnCodeController: _returnCodeController,
                              ownerReturnNotesController:
                                  _ownerReturnNotesController,
                              minorDeductionController:
                                  _minorDeductionController,
                              minorIssueReasonController:
                                  _minorIssueReasonController,
                              majorDamageReasonController:
                                  _majorDamageReasonController,
                              depositReasonController: _depositReasonController,
                              reviewController: _reviewController,
                              handoverProofName: _handoverProof?.name,
                              returnIssueProofName: _returnIssueProof?.name,
                              rating: _rating,
                              localReviewSubmitted: _localReviewSubmitted,
                              onConditionBeforeChanged: (value) =>
                                  setState(() => _conditionBefore = value),
                              onConditionAfterChanged: (value) =>
                                  setState(() => _conditionAfter = value),
                              onDepositDecisionChanged: (value) =>
                                  setState(() => _depositDecision = value),
                              onRatingChanged: (value) =>
                                  setState(() => _rating = value),
                              onOpenChat: () => _openChat(request, user),
                              onPickHandoverProof: _pickHandoverProof,
                              onPickReturnIssueProof: _pickReturnIssueProof,
                              onConfirmHandover: () =>
                                  _confirmHandover(request, user),
                              onConfirmReturn: () =>
                                  _confirmReturn(request, user),
                              onReportMinorIssue: () =>
                                  _reportMinorIssue(request, user),
                              onReportMajorDamage: () =>
                                  _reportMajorDamage(request, user),
                              onSubmitDepositDecision: () =>
                                  _submitDepositDecision(request, user),
                              onSubmitReview: () =>
                                  _submitReview(request, user),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Marketplace approval: owner approves the request, then waits for the borrower to complete payment.
  Future<void> _approveRequestFromDetail(
    BuildContext context,
    BorrowRequest request,
    AppUser user,
  ) async {
    final provider = context.read<BorrowRequestProvider>();
    await provider.approveBorrowRequest(
      requestId: request.id,
      ownerId: user.uid,
    );
    if (!context.mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          'Request approved. Waiting for borrower payment.',
    );
  }

  /// Marketplace approval: owner rejects the request with a reason before payment can happen.
  Future<void> _rejectRequestFromDetail(
    BuildContext context,
    BorrowRequest request,
    AppUser user,
  ) async {
    final reason = await _showRejectReasonSheet(context);
    if (reason == null || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BorrowRequestProvider>();
    await provider.rejectBorrowRequest(
      requestId: request.id,
      ownerId: user.uid,
      rejectionReason: reason,
    );

    final message = provider.errorMessage ?? 'Request rejected.';
    final succeeded = provider.errorMessage == null;
    if (succeeded) {
      navigator.pop();
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Marketplace chat: opens borrower chat only after payment has completed.
  Future<void> _openChat(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
      _showSnack(context, 'Chat unlocks after borrower payment is completed.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final chatProvider = context.read<ChatProvider>();
    try {
      final chat =
          chatProvider.chatById(request.chatId) ??
          await chatProvider.openOrCreateChat(
            _borrowerFromRequest(request: request, currentUser: user),
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResidentChatThreadView(initialChat: chat),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  /// Marketplace handover proof: lets the lender attach an optional before-handover photo.
  Future<void> _pickHandoverProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.residentOutline(),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Handover Proof',
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Optional photo before handing the item to the borrower.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _ProofSourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  subtitle: 'Use your Android camera',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ProofSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;

    if (source == ImageSource.camera &&
        !await DevicePermissionAccess.ensureCamera(context)) {
      return;
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (!mounted || picked == null) return;
      setState(() => _handoverProof = picked);
    } catch (_) {
      if (!mounted) return;
      final sourceName = source == ImageSource.camera ? 'camera' : 'gallery';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the $sourceName. You can continue without a proof photo.',
          ),
        ),
      );
    }
  }

  /// Marketplace return evidence: lets the lender attach a damage/lost-item photo for minor or major disputes.
  Future<void> _pickReturnIssueProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.residentOutline(),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Return Evidence',
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a clear photo of the issue before submitting the dispute.',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _ProofSourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  subtitle: 'Use your Android camera',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ProofSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;

    if (source == ImageSource.camera &&
        !await DevicePermissionAccess.ensureCamera(context)) {
      return;
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (!mounted || picked == null) return;
      setState(() => _returnIssueProof = picked);
    } catch (_) {
      if (!mounted) return;
      final sourceName = source == ImageSource.camera ? 'camera' : 'gallery';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the $sourceName. You can submit minor issues without a photo, but major damage needs evidence.',
          ),
        ),
      );
    }
  }

  /// Marketplace handover: owner confirms item condition and generates the arrival code for the borrower.
  Future<void> _confirmHandover(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.confirmHandover(
      requestId: request.id,
      ownerId: user.uid,
      conditionBefore: _conditionBefore,
      localProofPath: _handoverProof?.path,
    );
    if (!mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          'Arrival code generated. Show it to the borrower.',
    );
  }

  /// Marketplace return: owner confirms a clean return and triggers full deposit refund when applicable.
  Future<void> _confirmReturn(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final code = _returnCodeController.text.trim();
    if (!_isFourDigitCode(code)) {
      _showSnack(context, 'Enter the 4-digit return code from the borrower.');
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.confirmReturn(
      requestId: request.id,
      ownerId: user.uid,
      conditionAfter: AppConstants.borrowConditionAfterSame,
      ownerReturnNotes: _ownerReturnNotesController.text.trim(),
      returnCode: code,
    );
    if (!mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          'Return confirmed. Deposit was released automatically.',
    );
  }

  /// Marketplace dispute: owner requests a minor damage deduction from the deposit for borrower approval.
  Future<void> _reportMinorIssue(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final amount = double.tryParse(_minorDeductionController.text.trim());
    if (amount == null) {
      _showSnack(context, 'Enter the deduction amount requested from deposit.');
      return;
    }
    final reason = _minorIssueReasonController.text.trim();
    if (reason.isEmpty) {
      _showSnack(context, 'Add a reason for the minor issue.');
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.reportMinorIssue(
      requestId: request.id,
      ownerId: user.uid,
      deductionAmount: amount,
      reason: reason,
      localProofPath: _returnIssueProof?.path,
    );
    if (!mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          'Minor issue sent to borrower for deduction approval.',
    );
  }

  /// Marketplace dispute: owner escalates major damage/loss to admin with required photo evidence.
  Future<void> _reportMajorDamage(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final reason = _majorDamageReasonController.text.trim();
    if (reason.isEmpty) {
      _showSnack(context, 'Add a damage description for admin review.');
      return;
    }
    if (_returnIssueProof == null) {
      _showSnack(context, 'Add photo evidence before reporting major damage.');
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.reportMajorDamage(
      requestId: request.id,
      ownerId: user.uid,
      conditionAfter: _conditionAfter == AppConstants.borrowConditionAfterLost
          ? AppConstants.borrowConditionAfterLost
          : AppConstants.borrowConditionAfterMajor,
      description: reason,
      localProofPath: _returnIssueProof!.path,
    );
    if (!mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          'Major damage reported. Admin will review the dispute.',
    );
  }

  /// Marketplace deposit: owner records a clean-return refund decision or routes withhold cases to admin.
  Future<void> _submitDepositDecision(
    BorrowRequest request,
    AppUser? user,
  ) async {
    if (user == null) return;
    final reason = _depositReasonController.text.trim();
    if (_depositDecision == AppConstants.depositDecisionWithholdDeposit &&
        reason.isEmpty) {
      _showSnack(context, 'Add a reason before withholding the deposit.');
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.setDepositDecision(
      requestId: request.id,
      ownerId: user.uid,
      decision: _depositDecision,
      reason: reason,
    );
    if (!mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Deposit decision saved.');
  }

  /// Marketplace reviews: lender submits their one-time review after the transaction is completed.
  Future<void> _submitReview(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    try {
      await context.read<ReviewProvider>().createReview(
        borrowRequest: request,
        reviewerId: user.uid,
        reviewerName: user.fullName,
        role: AppConstants.reviewRoleOwnerToBorrower,
        rating: _rating,
        comment: _reviewController.text,
      );
      if (!mounted) return;
      setState(() => _localReviewSubmitted = true);
      _showSnack(
        context,
        'Review submitted. It stays hidden until both reviews are in or the 3-day grace period ends.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

/// Marketplace lender UI: chooses the correct owner action card for the current transaction status.
class _LenderTransactionBody extends StatelessWidget {
  const _LenderTransactionBody({
    required this.request,
    required this.provider,
    required this.conditionBefore,
    required this.conditionAfter,
    required this.depositDecision,
    required this.returnCodeController,
    required this.ownerReturnNotesController,
    required this.minorDeductionController,
    required this.minorIssueReasonController,
    required this.majorDamageReasonController,
    required this.depositReasonController,
    required this.reviewController,
    required this.handoverProofName,
    required this.returnIssueProofName,
    required this.rating,
    required this.localReviewSubmitted,
    required this.onConditionBeforeChanged,
    required this.onConditionAfterChanged,
    required this.onDepositDecisionChanged,
    required this.onRatingChanged,
    required this.onOpenChat,
    required this.onPickHandoverProof,
    required this.onPickReturnIssueProof,
    required this.onConfirmHandover,
    required this.onConfirmReturn,
    required this.onReportMinorIssue,
    required this.onReportMajorDamage,
    required this.onSubmitDepositDecision,
    required this.onSubmitReview,
  });

  final BorrowRequest request;
  final BorrowRequestProvider provider;
  final String conditionBefore;
  final String conditionAfter;
  final String depositDecision;
  final TextEditingController returnCodeController;
  final TextEditingController ownerReturnNotesController;
  final TextEditingController minorDeductionController;
  final TextEditingController minorIssueReasonController;
  final TextEditingController majorDamageReasonController;
  final TextEditingController depositReasonController;
  final TextEditingController reviewController;
  final String? handoverProofName;
  final String? returnIssueProofName;
  final int rating;
  final bool localReviewSubmitted;
  final ValueChanged<String> onConditionBeforeChanged;
  final ValueChanged<String> onConditionAfterChanged;
  final ValueChanged<String> onDepositDecisionChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onOpenChat;
  final VoidCallback onPickHandoverProof;
  final VoidCallback onPickReturnIssueProof;
  final VoidCallback onConfirmHandover;
  final VoidCallback onConfirmReturn;
  final VoidCallback onReportMinorIssue;
  final VoidCallback onReportMajorDamage;
  final VoidCallback onSubmitDepositDecision;
  final VoidCallback onSubmitReview;

  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case AppConstants.borrowStatusApproved:
        if (MarketplaceBorrowFlow.isPaymentComplete(request)) {
          return _LenderPaidWaitingCard(
            request: request,
            conditionBefore: conditionBefore,
            handoverProofName: handoverProofName,
            isLoading: provider.isLoading,
            onConditionBeforeChanged: onConditionBeforeChanged,
            onPickHandoverProof: onPickHandoverProof,
            onOpenChat: onOpenChat,
            onConfirmHandover: onConfirmHandover,
          );
        }
        return const _LenderApprovedUnpaidCard();
      case AppConstants.borrowStatusPickupReady:
        return _LenderHandoverCard(request: request, onOpenChat: onOpenChat);
      case AppConstants.borrowStatusHandedOver:
      case AppConstants.borrowStatusActive:
        return _LenderActiveCard(request: request, onOpenChat: onOpenChat);
      case AppConstants.borrowStatusReturnSubmitted:
        return _LenderReturnCard(
          request: request,
          conditionAfter: conditionAfter,
          returnCodeController: returnCodeController,
          ownerReturnNotesController: ownerReturnNotesController,
          minorDeductionController: minorDeductionController,
          minorIssueReasonController: minorIssueReasonController,
          majorDamageReasonController: majorDamageReasonController,
          returnIssueProofName: returnIssueProofName,
          isLoading: provider.isLoading,
          onConditionAfterChanged: onConditionAfterChanged,
          onOpenChat: onOpenChat,
          onPickReturnIssueProof: onPickReturnIssueProof,
          onConfirmReturn: onConfirmReturn,
          onReportMinorIssue: onReportMinorIssue,
          onReportMajorDamage: onReportMajorDamage,
        );
      case AppConstants.borrowStatusMinorIssuePending:
        return _LenderMinorIssueWaitingCard(
          request: request,
          onOpenChat: onOpenChat,
        );
      case AppConstants.borrowStatusDisputed:
        return _LenderDisputedCard(request: request, onOpenChat: onOpenChat);
      case AppConstants.borrowStatusCompleted:
        return _LenderCompletedCard(
          request: request,
          depositDecision: depositDecision,
          depositReasonController: depositReasonController,
          reviewController: reviewController,
          isLoading: provider.isLoading,
          rating: rating,
          localReviewSubmitted: localReviewSubmitted,
          onDepositDecisionChanged: onDepositDecisionChanged,
          onRatingChanged: onRatingChanged,
          onSubmitDepositDecision: onSubmitDepositDecision,
          onSubmitReview: onSubmitReview,
        );
      default:
        return _StateCard(
          icon: Icons.info_outline_rounded,
          title: _requestStatusLabel(request),
          message: _requestReadOnlyMessage(request),
        );
    }
  }
}

class _LenderApprovedUnpaidCard extends StatelessWidget {
  const _LenderApprovedUnpaidCard();

  @override
  Widget build(BuildContext context) {
    return const _GlassPanel(
      child: _TrackingStepCard(
        icon: Icons.payments_outlined,
        title: 'Waiting for Payment',
        message:
            'The request is approved. Handover and chat unlock after the borrower completes payment.',
      ),
    );
  }
}

class _LenderPaidWaitingCard extends StatelessWidget {
  const _LenderPaidWaitingCard({
    required this.request,
    required this.conditionBefore,
    required this.handoverProofName,
    required this.isLoading,
    required this.onConditionBeforeChanged,
    required this.onPickHandoverProof,
    required this.onOpenChat,
    required this.onConfirmHandover,
  });

  final BorrowRequest request;
  final String conditionBefore;
  final String? handoverProofName;
  final bool isLoading;
  final ValueChanged<String> onConditionBeforeChanged;
  final VoidCallback onPickHandoverProof;
  final VoidCallback onOpenChat;
  final VoidCallback onConfirmHandover;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Active Transaction'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat with Borrower',
            message: 'Chat with borrower for meetup.',
            action: _SecondaryButton(
              label: 'Open Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onOpenChat,
            ),
          ),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.fact_check_outlined,
            title: 'Inspect item condition',
            message:
                'Select the item condition before handing it to the borrower.',
            child: _OptionWrap(
              options: _handoverConditionOptions,
              selectedValue: conditionBefore,
              onChanged: onConditionBeforeChanged,
            ),
          ),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.camera_alt_outlined,
            title: 'Proof Photo',
            message: 'Optional owner proof before the borrower takes the item.',
            action: _SecondaryButton(
              label: handoverProofName == null ? 'Add Photo' : 'Photo Added',
              icon: Icons.camera_alt_outlined,
              onTap: onPickHandoverProof,
            ),
            footer: handoverProofName == null
                ? null
                : Text(
                    handoverProofName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kBrandTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: isLoading ? 'Starting...' : 'Arrive / Handover',
            icon: Icons.qr_code_2_rounded,
            onTap: isLoading ? null : onConfirmHandover,
          ),
        ],
      ),
    );
  }
}

class _LenderHandoverCard extends StatelessWidget {
  const _LenderHandoverCard({required this.request, required this.onOpenChat});

  final BorrowRequest request;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Handover Completion'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Arrival Code',
            message:
                'Show or read this code to the borrower after handing over the item. The borrow period starts when they enter it.',
            child: _LenderCodeDisplay(
              label: 'Arrival Code',
              code: request.handoverCode,
            ),
          ),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.fact_check_outlined,
            title: 'Condition recorded',
            message:
                'Condition at handover: ${_handoverConditionLabel(request.itemConditionBefore)}.',
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Open Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _LenderCodeDisplay extends StatelessWidget {
  const _LenderCodeDisplay({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    final cleanCode = code.trim().isEmpty ? '----' : code.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final char in cleanCode.characters)
                Expanded(
                  child: Container(
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.softSurface(),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.residentOutline()),
                    ),
                    child: Text(
                      char,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LenderActiveCard extends StatelessWidget {
  const _LenderActiveCard({required this.request, required this.onOpenChat});

  final BorrowRequest request;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Active Transaction'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.inventory_2_outlined,
            title: 'Item with Borrower',
            message:
                'Borrowing is active until ${_shortDateFormat.format(request.expectedReturnDate)}. Return confirmation unlocks after the borrower starts return.',
            child: _MiniInfoTile(
              label: 'Condition at handover',
              value: _handoverConditionLabel(request.itemConditionBefore),
            ),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Open Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _LenderReturnCard extends StatelessWidget {
  const _LenderReturnCard({
    required this.request,
    required this.conditionAfter,
    required this.returnCodeController,
    required this.ownerReturnNotesController,
    required this.minorDeductionController,
    required this.minorIssueReasonController,
    required this.majorDamageReasonController,
    required this.returnIssueProofName,
    required this.isLoading,
    required this.onConditionAfterChanged,
    required this.onOpenChat,
    required this.onPickReturnIssueProof,
    required this.onConfirmReturn,
    required this.onReportMinorIssue,
    required this.onReportMajorDamage,
  });

  final BorrowRequest request;
  final String conditionAfter;
  final TextEditingController returnCodeController;
  final TextEditingController ownerReturnNotesController;
  final TextEditingController minorDeductionController;
  final TextEditingController minorIssueReasonController;
  final TextEditingController majorDamageReasonController;
  final String? returnIssueProofName;
  final bool isLoading;
  final ValueChanged<String> onConditionAfterChanged;
  final VoidCallback onOpenChat;
  final VoidCallback onPickReturnIssueProof;
  final VoidCallback onConfirmReturn;
  final VoidCallback onReportMinorIssue;
  final VoidCallback onReportMajorDamage;

  @override
  Widget build(BuildContext context) {
    final isGood = conditionAfter == AppConstants.borrowConditionAfterSame;
    final isMinor = conditionAfter == AppConstants.borrowConditionAfterMinor;
    final isMajor =
        conditionAfter == AppConstants.borrowConditionAfterMajor ||
        conditionAfter == AppConstants.borrowConditionAfterLost;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Return Inspection'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Meet Borrower',
            message:
                'Inspect the item before closing the transaction or opening a dispute.',
            action: _SecondaryButton(
              label: 'Open Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onOpenChat,
            ),
          ),
          if (request.returnNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _TrackingStepCard(
              icon: Icons.notes_rounded,
              title: 'Borrower Notes',
              message: request.returnNotes.trim(),
            ),
          ],
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.fact_check_outlined,
            title: 'Inspection Result',
            message:
                'Choose the path that matches the returned item condition.',
            child: _OptionWrap(
              options: _returnInspectionOptions,
              selectedValue: conditionAfter,
              onChanged: onConditionAfterChanged,
            ),
          ),
          if (isGood) ...[
            const SizedBox(height: 12),
            TextField(
              controller: ownerReturnNotesController,
              minLines: 2,
              maxLines: 3,
              decoration: context.residentInputDecoration(
                label: 'Owner notes',
                hint: 'Optional notes for a clean return',
              ),
            ),
            const SizedBox(height: 12),
            _TrackingStepCard(
              icon: Icons.pin_rounded,
              title: 'Completion Code',
              message:
                  'Enter the 4-digit code from the borrower after you are satisfied with the item condition.',
              action: _PrimaryButton(
                label: isLoading ? 'Confirming...' : 'Item is Good',
                icon: Icons.assignment_return_rounded,
                onTap: isLoading ? null : onConfirmReturn,
              ),
              child: _CodeTextField(
                controller: returnCodeController,
                label: 'Completion Code',
              ),
            ),
          ],
          if (isMinor) ...[
            const SizedBox(height: 12),
            _TrackingStepCard(
              icon: Icons.build_circle_outlined,
              title: 'Minor Issue',
              message:
                  'Request a deduction from the borrower. The transaction waits for their accept or decline response.',
              footer: returnIssueProofName == null
                  ? null
                  : Text(
                      returnIssueProofName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kBrandTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              action: _SecondaryButton(
                label: returnIssueProofName == null
                    ? 'Add Photo'
                    : 'Replace Photo',
                icon: Icons.camera_alt_outlined,
                onTap: onPickReturnIssueProof,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: minorDeductionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: context.residentInputDecoration(
                      label: 'Deduction amount',
                      hint: 'Example: 10',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minorIssueReasonController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: context.residentInputDecoration(
                      label: 'Reason',
                      hint: 'Explain the scratch, missing piece, or issue',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PrimaryButton(
              label: isLoading ? 'Sending...' : 'Report Minor Issue',
              icon: Icons.price_change_outlined,
              onTap: isLoading ? null : onReportMinorIssue,
            ),
          ],
          if (isMajor) ...[
            const SizedBox(height: 12),
            _TrackingStepCard(
              icon: Icons.report_problem_outlined,
              title: conditionAfter == AppConstants.borrowConditionAfterLost
                  ? 'Lost Item'
                  : 'Major Damage',
              message:
                  'This freezes the deposit and creates an admin dispute ticket. Photo evidence is required.',
              footer: returnIssueProofName == null
                  ? null
                  : Text(
                      returnIssueProofName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kBrandTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              action: _SecondaryButton(
                label: returnIssueProofName == null
                    ? 'Add Evidence'
                    : 'Replace Evidence',
                icon: Icons.camera_alt_outlined,
                onTap: onPickReturnIssueProof,
              ),
              child: TextField(
                controller: majorDamageReasonController,
                minLines: 3,
                maxLines: 4,
                decoration: context.residentInputDecoration(
                  label: 'Damage description',
                  hint: 'Explain what happened and what admin should review',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DangerButton(
              label: isLoading ? 'Submitting...' : 'Report Major Damage',
              icon: Icons.gavel_rounded,
              onTap: isLoading ? null : onReportMajorDamage,
            ),
          ],
        ],
      ),
    );
  }
}

class _LenderMinorIssueWaitingCard extends StatelessWidget {
  const _LenderMinorIssueWaitingCard({
    required this.request,
    required this.onOpenChat,
  });

  final BorrowRequest request;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Minor Issue Pending'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Waiting for borrower response',
            message:
                'You requested ${_money(request.minorDeductionAmount)} for: ${request.minorIssueReason}. If the borrower declines, admin review starts automatically.',
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Open Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _LenderDisputedCard extends StatelessWidget {
  const _LenderDisputedCard({required this.request, required this.onOpenChat});

  final BorrowRequest request;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final reason = request.disputeReason.trim().isNotEmpty
        ? request.disputeReason.trim()
        : request.ownerReturnNotes.trim();
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Admin Dispute'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.gavel_rounded,
            title: 'Deposit Frozen',
            message:
                'Admin will review the evidence and decide whether the deposit is released to the borrower or withheld for you.',
            child: _MiniInfoTile(
              label: 'Reason',
              value: reason.isEmpty ? 'No reason recorded' : reason,
            ),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Open Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

/// Marketplace lender UI: completed-state card showing payout/deposit outcome and one-time borrower review form.
class _LenderCompletedCard extends StatelessWidget {
  const _LenderCompletedCard({
    required this.request,
    required this.depositDecision,
    required this.depositReasonController,
    required this.reviewController,
    required this.isLoading,
    required this.rating,
    required this.localReviewSubmitted,
    required this.onDepositDecisionChanged,
    required this.onRatingChanged,
    required this.onSubmitDepositDecision,
    required this.onSubmitReview,
  });

  final BorrowRequest request;
  final String depositDecision;
  final TextEditingController depositReasonController;
  final TextEditingController reviewController;
  final bool isLoading;
  final int rating;
  final bool localReviewSubmitted;
  final ValueChanged<String> onDepositDecisionChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmitDepositDecision;
  final VoidCallback onSubmitReview;

  @override
  Widget build(BuildContext context) {
    final pendingDeposit =
        request.hasDeposit &&
        request.depositDecision == AppConstants.depositDecisionPending;
    final reviewSubmitted =
        localReviewSubmitted || request.ownerReviewSubmitted;

    if (!pendingDeposit) {
      return _GlassPanel(
        child: _TrackingStepCard(
          icon: Icons.check_circle_rounded,
          title: 'Transaction Completed',
          message: _depositSummaryMessage(request),
          child: Column(
            children: [
              _MiniInfoTile(
                label: 'Returned condition',
                value: _returnConditionLabel(request.itemConditionAfter),
              ),
              const SizedBox(height: 8),
              _MiniInfoTile(
                label: 'Deposit',
                value: _depositDecisionLabel(request.depositDecision),
              ),
              if (_hasLenderAdminDecision(request)) ...[
                const SizedBox(height: 12),
                _LenderAdminDecisionPanel(request: request),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (reviewSubmitted)
                const _TrackingStepCard(
                  icon: Icons.rate_review_rounded,
                  title: 'Review Submitted',
                  message:
                      'Your review is saved and cannot be changed. It stays hidden until both reviews are submitted or the 3-day grace period ends.',
                )
              else ...[
                Text(
                  'Rate the Borrower',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Did ${request.borrowerName} treat the item safely and return it on time?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: RatingBar.builder(
                    initialRating: rating.toDouble(),
                    minRating: 1,
                    itemSize: 32,
                    allowHalfRating: false,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    onRatingUpdate: (value) => onRatingChanged(value.round()),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: context.residentInputDecoration(
                    label: 'Private until published',
                    hint: 'Optional comment about item care and punctuality',
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<ReviewProvider>(
                  builder: (context, provider, _) {
                    return _PrimaryButton(
                      label: provider.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Review',
                      icon: Icons.rate_review_rounded,
                      onTap: provider.isSubmitting ? null : onSubmitReview,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Deposit Decision'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.security_rounded,
            title: 'Issue Reported',
            message:
                'The returned condition needs a deposit decision. Choose whether to release or withhold the refundable deposit.',
            child: Column(
              children: [
                _MiniInfoTile(
                  label: 'Returned condition',
                  value: _returnConditionLabel(request.itemConditionAfter),
                ),
                const SizedBox(height: 8),
                _MiniInfoTile(
                  label: 'Refundable deposit',
                  value: _money(request.depositAmount),
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OptionWrap(
            options: _depositDecisionOptions,
            selectedValue: depositDecision,
            onChanged: onDepositDecisionChanged,
          ),
          if (depositDecision ==
              AppConstants.depositDecisionWithholdDeposit) ...[
            const SizedBox(height: 12),
            TextField(
              controller: depositReasonController,
              minLines: 3,
              maxLines: 4,
              decoration: context.residentInputDecoration(
                label: 'Reason',
                hint: 'Explain the damage, missing part, or lost item',
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: isLoading ? 'Saving...' : 'Save Deposit Decision',
            icon: Icons.verified_rounded,
            onTap: isLoading ? null : onSubmitDepositDecision,
          ),
        ],
      ),
    );
  }
}

/// Marketplace lender UI: explains the admin deposit decision and manual payout status.
class _LenderAdminDecisionPanel extends StatelessWidget {
  const _LenderAdminDecisionPanel({required this.request});

  final BorrowRequest request;

  @override
  /// Marketplace lender UI: renders pending approval or the full transaction tracking flow for this owner request.
  Widget build(BuildContext context) {
    return _TrackingStepCard(
      icon: _lenderAdminDecisionIcon(request),
      title: _lenderAdminDecisionTitle(request),
      message: _lenderAdminDecisionMessage(request),
      child: Column(
        children: [
          _MiniInfoTile(
            label: 'Item fee',
            value: _money(request.lenderBaseEarning),
          ),
          const SizedBox(height: 8),
          _MiniInfoTile(
            label: 'Damage deduction',
            value: _money(request.lenderDamageEarning),
          ),
          const SizedBox(height: 8),
          _MiniInfoTile(
            label: 'Manual payout total',
            value: _money(request.lenderTotalEarning),
            emphasized: true,
          ),
          if (request.manualPayoutReference.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _MiniInfoTile(
              label: 'Payout reference',
              value: request.manualPayoutReference.trim(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingStepCard extends StatelessWidget {
  const _TrackingStepCard({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
    this.action,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final Widget? action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kBrandTeal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
          if (action != null) ...[const SizedBox(height: 12), action!],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_Option> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _ChoiceChipButton(
            label: option.label,
            selected: option.value == selectedValue,
            onTap: () => onChanged(option.value),
          ),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _kBrandTeal.withValues(alpha: 0.12)
          : context.softSurface(),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _kBrandTeal : context.residentOutline(),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kBrandTeal : context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeTextField extends StatelessWidget {
  const _CodeTextField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      maxLength: 4,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appInk,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      decoration: context
          .residentInputDecoration(label: label, hint: '0000')
          .copyWith(counterText: ''),
    );
  }
}

class _ProofSourceTile extends StatelessWidget {
  const _ProofSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.softSurface(),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.residentOutline()),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kBrandTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: context.appMuted),
            ],
          ),
        ),
      ),
    );
  }
}
