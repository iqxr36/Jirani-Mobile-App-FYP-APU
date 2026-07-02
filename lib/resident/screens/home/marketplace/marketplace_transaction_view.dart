part of '../resident_marketplace_view.dart';

/// Marketplace borrower screen: tracks one approved borrow request from payment through return, deposit decision, and review.
class MarketplaceTransactionView extends StatefulWidget {
  const MarketplaceTransactionView({super.key, required this.initialRequest});

  final BorrowRequest initialRequest;

  @override
  State<MarketplaceTransactionView> createState() =>
      _MarketplaceTransactionViewState();
}

class _MarketplaceTransactionViewState
    extends State<MarketplaceTransactionView> {
  final TextEditingController _handoverCodeController = TextEditingController();
  final TextEditingController _returnNotesController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  bool _localReviewSubmitted = false;

  @override
  void dispose() {
    _handoverCodeController.dispose();
    _returnNotesController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  /// Marketplace borrower screen: prefers the live provider version of the request over the initial navigation snapshot.
  BorrowRequest _currentRequest(BorrowRequestProvider provider) {
    for (final request in provider.myBorrowRequests) {
      if (request.id == widget.initialRequest.id) return request;
    }
    return provider.selectedRequest?.id == widget.initialRequest.id
        ? provider.selectedRequest!
        : widget.initialRequest;
  }

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    final user = context.watch<AuthViewModel>().currentUser;
    final requestProvider = context.watch<BorrowRequestProvider>();
    final request = _currentRequest(requestProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _InsetContent(
                  sideInset: sideInset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _ScreenTitleBar(
                        title: 'Borrowing',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 16),
                      _TransactionHeader(request: request),
                      const SizedBox(height: 14),
                      _ProgressPanel(request: request),
                      if (_FinancialLedgerPanel.shouldShow(
                        request,
                        user?.uid ?? '',
                      )) ...[
                        const SizedBox(height: 14),
                        _FinancialLedgerPanel(
                          request: request,
                          currentUserId: user?.uid ?? '',
                        ),
                      ],
                      const SizedBox(height: 14),
                      _TransactionBody(
                        request: request,
                        returnNotesController: _returnNotesController,
                        reviewController: _reviewController,
                        handoverCodeController: _handoverCodeController,
                        rating: _rating,
                        localReviewSubmitted: _localReviewSubmitted,
                        onRatingChanged: (rating) =>
                            setState(() => _rating = rating),
                        onPayment: () => _completePayment(request, user),
                        onOpenChat: () => _openChat(request, user),
                        onPickupReady: () => _confirmPickupReady(request, user),
                        onSubmitReturn: () => _submitReturn(request, user),
                        onAcceptMinorIssue: () =>
                            _respondToMinorIssue(request, user, true),
                        onDeclineMinorIssue: () =>
                            _respondToMinorIssue(request, user, false),
                        onSubmitReview: () => _submitReview(request, user),
                      ),
                      const SizedBox(height: 34),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Marketplace payments: starts Xendit hosted checkout for the approved request.
  Future<void> _completePayment(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final paymentProvider = context.read<PaymentProvider>();
    final result = await paymentProvider.createXenditMarketplacePayment(
      request: request,
      successRedirectUrl:
          'https://final-year-project-faisal.web.app/xendit-payment-success',
      failureRedirectUrl:
          'https://final-year-project-faisal.web.app/xendit-payment-failed',
    );
    if (!mounted) return;

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            paymentProvider.errorMessage ??
                'Payment could not start. Please try again.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(result.checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open Xendit checkout.')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text("Payment opened. We're confirming with Xendit shortly."),
        duration: Duration(seconds: 4),
      ),
    );
    final status = await paymentProvider.waitForPaymentConfirmation(
      result.paymentId,
    );
    if (!mounted) return;

    final feedback = _paymentFeedback(status, paymentProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(feedback.message), duration: feedback.duration),
    );
  }

  /// Marketplace payments: maps backend/webhook payment results into borrower-friendly SnackBar messages.
  ({String message, Duration duration}) _paymentFeedback(
    String? status,
    PaymentProvider provider,
  ) {
    switch (status) {
      case AppConstants.paymentStatusSucceeded:
        return (
          message: 'Payment received. Chat and handover unlock shortly.',
          duration: const Duration(seconds: 3),
        );
      case AppConstants.paymentStatusCancelled:
        return (
          message: 'Payment was cancelled or expired. No charge was made.',
          duration: const Duration(seconds: 3),
        );
      case AppConstants.paymentStatusFailed:
        return (
          message: provider.errorMessage ??
              'Payment failed. Please try another Xendit payment method.',
          duration: const Duration(seconds: 5),
        );
      case AppConstants.paymentStatusPending:
      default:
        return (
          message:
              "Payment submitted. We are confirming with Xendit. Pull to refresh in a moment.",
          duration: const Duration(seconds: 4),
        );
    }
  }

  /// Marketplace chat: opens lender chat after payment has unlocked the transaction chat id.
  Future<void> _openChat(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final chatProvider = context.read<ChatProvider>();
    try {
      final chat =
          chatProvider.chatById(request.chatId) ??
          await chatProvider.openOrCreateChat(
            _ownerFromRequest(request: request, currentUser: user),
          );
      if (!mounted) return;
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResidentChatThreadView(initialChat: chat),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  /// Marketplace handover: borrower enters the lender's arrival code to start the active borrow period.
  Future<void> _confirmPickupReady(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final code = _handoverCodeController.text.trim();
    final codeError = Validators.validateFourDigitCode(code);
    if (codeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(codeError.replaceFirst('Code', 'Arrival code'))),
      );
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.confirmPickupReady(
      requestId: request.id,
      borrowerId: user.uid,
      handoverCode: code,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              'Pickup confirmed. Borrowing is now in progress.',
        ),
      ),
    );
  }

  /// Marketplace return: borrower submits return notes and receives/shares the return confirmation code.
  Future<void> _submitReturn(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.submitReturn(
      requestId: request.id,
      borrowerId: user.uid,
      returnNotes: _returnNotesController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              'Return started. Share your return code with the lender.',
        ),
      ),
    );
  }

  /// Marketplace dispute: borrower accepts a partial deduction or declines and sends the case to admin review.
  Future<void> _respondToMinorIssue(
    BorrowRequest request,
    AppUser? user,
    bool accepted,
  ) async {
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.respondToMinorIssue(
      requestId: request.id,
      borrowerId: user.uid,
      accepted: accepted,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              (accepted
                  ? 'Deduction accepted. Transaction completed.'
                  : 'Deduction declined. Admin dispute review started.'),
        ),
      ),
    );
  }

  /// Marketplace reviews: borrower submits their one-time review after the transaction is completed.
  Future<void> _submitReview(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ReviewProvider>().createReview(
        borrowRequest: request,
        reviewerId: user.uid,
        reviewerName: user.fullName,
        role: AppConstants.reviewRoleBorrowerToOwner,
        rating: _rating,
        comment: _reviewController.text,
      );
      if (!mounted) return;
      setState(() => _localReviewSubmitted = true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Review submitted. It stays hidden until both reviews are in or the 3-day grace period ends.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

}

/// Marketplace borrower UI: chooses the correct transaction action card for the current borrow status.
class _TransactionBody extends StatelessWidget {
  const _TransactionBody({
    required this.request,
    required this.returnNotesController,
    required this.reviewController,
    required this.handoverCodeController,
    required this.rating,
    required this.localReviewSubmitted,
    required this.onRatingChanged,
    required this.onPayment,
    required this.onOpenChat,
    required this.onPickupReady,
    required this.onSubmitReturn,
    required this.onAcceptMinorIssue,
    required this.onDeclineMinorIssue,
    required this.onSubmitReview,
  });

  final BorrowRequest request;
  final TextEditingController returnNotesController;
  final TextEditingController reviewController;
  final TextEditingController handoverCodeController;
  final int rating;
  final bool localReviewSubmitted;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onPayment;
  final VoidCallback onOpenChat;
  final VoidCallback onPickupReady;
  final VoidCallback onSubmitReturn;
  final VoidCallback onAcceptMinorIssue;
  final VoidCallback onDeclineMinorIssue;
  final VoidCallback onSubmitReview;

  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case AppConstants.borrowStatusPending:
        return const _StateCard(
          icon: Icons.pending_actions_rounded,
          title: 'Waiting for owner approval',
          message:
              'The owner will review your request. Checkout unlocks once they accept it.',
        );
      case AppConstants.borrowStatusRejected:
        return _StateCard(
          icon: Icons.cancel_outlined,
          title: 'Request declined',
          message: request.rejectionReason.isEmpty
              ? 'The owner declined this borrow request.'
              : request.rejectionReason,
        );
      case AppConstants.borrowStatusCancelled:
        return const _StateCard(
          icon: Icons.block_rounded,
          title: 'Request cancelled',
          message: 'This borrow request is no longer active.',
        );
      case AppConstants.borrowStatusApproved:
        if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
          return _CheckoutCard(
            request: request,
            onPayment: onPayment,
          );
        }
        return _WaitingForLenderArrivalCard(onOpenChat: onOpenChat);
      case AppConstants.borrowStatusPickupReady:
        return _ConfirmPickupCodeCard(
          request: request,
          handoverCodeController: handoverCodeController,
          onOpenChat: onOpenChat,
          onConfirmPickup: onPickupReady,
        );
      case AppConstants.borrowStatusActive:
      case AppConstants.borrowStatusHandedOver:
        return _ActiveBorrowCard(
          request: request,
          returnNotesController: returnNotesController,
          onOpenChat: onOpenChat,
          onSubmitReturn: onSubmitReturn,
        );
      case AppConstants.borrowStatusReturnSubmitted:
        return _ReturnSubmittedCard(request: request, onOpenChat: onOpenChat);
      case AppConstants.borrowStatusMinorIssuePending:
        return _MinorIssuePromptCard(
          request: request,
          onOpenChat: onOpenChat,
          onAccept: onAcceptMinorIssue,
          onDecline: onDeclineMinorIssue,
        );
      case AppConstants.borrowStatusDisputed:
        return _DisputedCard(request: request, onOpenChat: onOpenChat);
      case AppConstants.borrowStatusCompleted:
        return _CompletedCard(
          request: request,
          reviewController: reviewController,
          rating: rating,
          localReviewSubmitted: localReviewSubmitted,
          onRatingChanged: onRatingChanged,
          onSubmitReview: onSubmitReview,
        );
      default:
        return _StateCard(
          icon: Icons.info_outline_rounded,
          title: _statusLabel(request),
          message: 'This request is being updated.',
        );
    }
  }
}

class _CheckoutTitleBar extends StatelessWidget {
  const _CheckoutTitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kBrandTeal,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Divider(
              thickness: 1.4,
              color: context.residentOutline(),
            ),
          ),
        ),
      ],
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
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final Widget? action;

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
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.request,
    required this.onPayment,
  });

  final BorrowRequest request;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final usageFee = request.usageFeeAmount ?? 0;
    final deposit = request.depositAmount ?? 0;
    final total = MarketplaceBorrowFlow.totalDue(
      usageFee: usageFee,
      deposit: deposit,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CheckoutTitleBar(title: 'Checkout'),
        const SizedBox(height: 14),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel('Transaction Summary'),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Item', value: request.itemTitle),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Duration', value: _requestDateRange(request)),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Refundable deposit', value: _money(deposit)),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Item fee', value: _money(usageFee)),
              const Divider(height: 28),
              _SummaryRow(
                label: 'Total Due',
                value: _money(total),
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel('Secure Payment'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _kBrandTeal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xendit will open a secure checkout page with Malaysian payment options. Your deposit is refunded after the return is settled.',
                        style: TextStyle(
                          color: context.appInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Consumer<PaymentProvider>(
          builder: (context, provider, _) {
            return _PrimaryButton(
              icon: Icons.lock_rounded,
              label: provider.isLoading
                  ? 'Processing payment...'
                  : 'Pay Now',
              onTap: provider.isLoading ? null : onPayment,
            );
          },
        ),
      ],
    );
  }
}


class _WaitingForLenderArrivalCard extends StatelessWidget {
  const _WaitingForLenderArrivalCard({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Transaction Tracking'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat with lender',
            message: 'Coordinate the pickup meetup with the lender.',
            action: _SecondaryButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Open Chat',
              onTap: onOpenChat,
            ),
          ),
          const SizedBox(height: 12),
          const _TrackingStepCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Waiting for lender arrival',
            message:
                'When the lender is physically ready to hand over the item, they will tap Arrive / Handover and show you a 4-digit arrival code.',
          ),
        ],
      ),
    );
  }
}

class _ConfirmPickupCodeCard extends StatelessWidget {
  const _ConfirmPickupCodeCard({
    required this.request,
    required this.handoverCodeController,
    required this.onOpenChat,
    required this.onConfirmPickup,
  });

  final BorrowRequest request;
  final TextEditingController handoverCodeController;
  final VoidCallback onOpenChat;
  final VoidCallback onConfirmPickup;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Confirm Pickup'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Enter arrival code',
            message:
                'The lender has started handover. Enter the 4-digit code from their screen after receiving the item.',
            action: Consumer<BorrowRequestProvider>(
              builder: (context, provider, _) {
                return _PrimaryButton(
                  icon: Icons.handshake_rounded,
                  label: provider.isLoading
                      ? 'Confirming...'
                      : 'Confirm Pickup',
                  onTap: provider.isLoading ? null : onConfirmPickup,
                );
              },
            ),
            child: TextField(
              controller: handoverCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              maxLength: 4,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appInk,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              decoration: context.residentInputDecoration(
                label: 'Arrival Code',
                hint: '0000',
              ).copyWith(counterText: ''),
            ),
          ),
          const SizedBox(height: 12),
          if (request.handoverProofImageUrl.trim().isNotEmpty) ...[
            _TrackingStepCard(
              icon: Icons.camera_alt_outlined,
              title: 'Lender proof recorded',
              message:
                  'The lender added a condition proof photo before handover.',
            ),
            const SizedBox(height: 12),
          ],
          _SecondaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Open Chat',
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _ActiveBorrowCard extends StatelessWidget {
  const _ActiveBorrowCard({
    required this.request,
    required this.returnNotesController,
    required this.onOpenChat,
    required this.onSubmitReturn,
  });

  final BorrowRequest request;
  final TextEditingController returnNotesController;
  final VoidCallback onOpenChat;
  final VoidCallback onSubmitReturn;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Active Borrowing'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.inventory_2_outlined,
            title: 'Use item until return date',
            message:
                'Use the item until ${_shortDateFormat.format(request.expectedReturnDate)}. Meet the lender again when you are ready to return it.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: returnNotesController,
            minLines: 2,
            maxLines: 3,
            decoration: context.residentInputDecoration(
              label: 'Return notes',
              hint: 'Optional notes before returning the item',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Open Chat',
                  onTap: onOpenChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Consumer<BorrowRequestProvider>(
                  builder: (context, provider, _) {
                    return _PrimaryButton(
                      icon: Icons.keyboard_return_rounded,
                      label: provider.isLoading ? 'Starting...' : 'Return Item',
                      onTap: provider.isLoading ? null : onSubmitReturn,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnSubmittedCard extends StatelessWidget {
  const _ReturnSubmittedCard({required this.request, required this.onOpenChat});

  final BorrowRequest request;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Return Meetup'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Return code confirmation',
            message:
                'Give this code to the lender after they inspect the item. If there are no issues, the deposit is released back to you.',
            child: _CodeDisplay(label: 'Return Code', code: request.returnCode),
          ),
          const SizedBox(height: 14),
          _SecondaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Open Chat',
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _MinorIssuePromptCard extends StatelessWidget {
  const _MinorIssuePromptCard({
    required this.request,
    required this.onOpenChat,
    required this.onAccept,
    required this.onDecline,
  });

  final BorrowRequest request;
  final VoidCallback onOpenChat;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final deduction = request.minorDeductionAmount ?? 0;
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Minor Issue Review'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.build_circle_outlined,
            title: 'Deduction Requested',
            message:
                'The lender requested ${_money(deduction)} from your refundable deposit for: ${request.minorIssueReason}.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Refundable deposit',
                  value: _money(request.depositAmount ?? 0),
                ),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Requested deduction', value: _money(deduction)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Open Chat',
                  onTap: onOpenChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Consumer<BorrowRequestProvider>(
                  builder: (context, provider, _) {
                    return _PrimaryButton(
                      icon: Icons.check_rounded,
                      label: provider.isLoading ? 'Saving...' : 'Accept',
                      onTap: provider.isLoading ? null : onAccept,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Consumer<BorrowRequestProvider>(
            builder: (context, provider, _) {
              return _DangerButton(
                icon: Icons.gavel_rounded,
                label: provider.isLoading ? 'Escalating...' : 'Decline and Escalate',
                onTap: provider.isLoading ? null : onDecline,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DisputedCard extends StatelessWidget {
  const _DisputedCard({required this.request, required this.onOpenChat});

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
          const _SectionLabel('Admin Review'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.gavel_rounded,
            title: 'Deposit Frozen',
            message:
                'This transaction is paused while admin reviews the dispute evidence. Your deposit will not be released or deducted until admin resolves it.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Reason',
                  value: reason.isEmpty ? 'Waiting for admin review' : reason,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Admin note',
                  value:
                      'An admin will review both sides and send the final deposit decision here.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Open Chat',
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

/// Marketplace borrower UI: completed-state card showing deposit outcome and one-time lender review form.
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({
    required this.request,
    required this.reviewController,
    required this.rating,
    required this.localReviewSubmitted,
    required this.onRatingChanged,
    required this.onSubmitReview,
  });

  final BorrowRequest request;
  final TextEditingController reviewController;
  final int rating;
  final bool localReviewSubmitted;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmitReview;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final depositReleased = MarketplaceBorrowFlow.hasDepositReleased(request);
    final depositSettled =
        request.status == AppConstants.borrowStatusCompleted &&
        request.depositDecision != AppConstants.depositDecisionPending;
    final reviewSubmitted =
        localReviewSubmitted || request.borrowerReviewSubmitted;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            depositReleased
                ? Icons.check_circle_rounded
                : Icons.report_problem_outlined,
            color: depositReleased ? _kBrandTeal : _kWarmAccent,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            depositSettled ? 'Transaction Complete' : 'Deposit Review Pending',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _borrowerDepositMessage(request),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (depositSettled) ...[
            const SizedBox(height: 18),
            if (_hasAdminDepositDecision(request)) ...[
              _AdminDepositDecisionCard(request: request),
              const SizedBox(height: 18),
            ],
            if (reviewSubmitted)
              const _TrackingStepCard(
                icon: Icons.rate_review_rounded,
                title: 'Review Submitted',
                message:
                    'Your review is saved and cannot be changed. It stays hidden until both reviews are submitted or the 3-day grace period ends.',
              )
            else ...[
              Text(
                'Rate the Lender',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Did the item match the description, and was communication easy with ${request.ownerName}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
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
                  itemSize: 34,
                  allowHalfRating: false,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star_rounded, color: _kWarmAccent),
                  onRatingUpdate: (value) => onRatingChanged(value.round()),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reviewController,
                minLines: 3,
                maxLines: 4,
                decoration: context.residentInputDecoration(
                  label: 'Private until published',
                  hint: 'Optional comment about description and communication',
                ),
              ),
              const SizedBox(height: 14),
              Consumer<ReviewProvider>(
                builder: (context, provider, _) {
                  return _PrimaryButton(
                    icon: Icons.rate_review_rounded,
                    label: provider.isSubmitting
                        ? 'Submitting...'
                        : 'Submit Review',
                    onTap: provider.isSubmitting ? null : onSubmitReview,
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Marketplace borrower UI: summarizes admin deposit decision, refund amount, deduction, and admin note.
class _AdminDepositDecisionCard extends StatelessWidget {
  const _AdminDepositDecisionCard({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    return _TrackingStepCard(
      icon: _adminDecisionIcon(request),
      title: _adminDecisionTitle(request),
      message: _depositLedgerMessage(request),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Deposit held',
            value: _money(
              request.depositHeldAmount > 0
                  ? request.depositHeldAmount
                  : request.depositAmount,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Damage deduction',
            value: _money(request.damageDeductionAmount),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Refund amount',
            value: _money(request.depositRefundAmount),
            emphasized: true,
          ),
          if (request.adminResolutionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Admin note',
              value: request.adminResolutionReason.trim(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestThumb(imageUrl: request.itemImageUrl, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.itemTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_compactDateFormat.format(request.requestedStartDate)} - ${_compactDateFormat.format(request.expectedReturnDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusPill(label: _statusLabel(request)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  request.ownerName.isEmpty
                      ? 'Lender profile'
                      : request.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: _kBrandTeal,
                  backgroundColor: _kBrandTeal.withValues(alpha: 0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => PublicResidentProfileView(
                        userId: request.ownerId,
                        fallbackName: request.ownerName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: const Text(
                  'View Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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

/// Marketplace borrower UI: shows progress from approval to payment, handover, and return.
class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;
    final steps = [
      _ProgressStep(
        label: 'Approval',
        icon: Icons.verified_rounded,
        done:
            request.approvedAt != null ||
            request.status == AppConstants.borrowStatusApproved ||
            _isAfterApproval(request.status),
      ),
      _ProgressStep(
        label: 'Payment',
        icon: Icons.payments_rounded,
        done: MarketplaceBorrowFlow.isPaymentComplete(request),
      ),
      _ProgressStep(
        label: 'Handover',
        icon: Icons.handshake_rounded,
        done:
            request.handoverConfirmedAt != null ||
            request.status == AppConstants.borrowStatusActive ||
            request.status == AppConstants.borrowStatusReturnSubmitted ||
            request.status == AppConstants.borrowStatusMinorIssuePending ||
            request.status == AppConstants.borrowStatusDisputed ||
            request.status == AppConstants.borrowStatusCompleted,
      ),
      _ProgressStep(
        label: 'Return',
        icon: Icons.keyboard_return_rounded,
        done:
            request.returnConfirmedAt != null ||
            request.status == AppConstants.borrowStatusCompleted,
      ),
    ];

    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(child: _StepChip(step: steps[i])),
            if (i != steps.length - 1)
              Container(
                width: 14,
                height: 2,
                color: steps[i].done
                    ? _kBrandTeal
                    : muted.withValues(alpha: 0.20),
              ),
          ],
        ],
      ),
    );
  }
}

/// Marketplace money UI: shows borrower deposit status or lender payout summary depending on current user role.
class _FinancialLedgerPanel extends StatelessWidget {
  const _FinancialLedgerPanel({
    required this.request,
    required this.currentUserId,
  });

  final BorrowRequest request;
  final String currentUserId;

  static bool shouldShow(BorrowRequest request, String currentUserId) {
    if (currentUserId.isEmpty) return false;
    if (request.paymentProvider != AppConstants.paymentProviderXendit) {
      return false;
    }
    return request.paymentStatus == AppConstants.paymentStatusCompleted ||
        request.depositStatus.isNotEmpty ||
        request.manualPayoutStatus.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == request.ownerId;
    final title = isOwner ? 'Lender Payout' : 'Deposit Status';
    final icon = isOwner
        ? Icons.account_balance_wallet_outlined
        : Icons.savings_outlined;

    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kBrandTeal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: isOwner
                    ? _manualPayoutStatusLabel(request.manualPayoutStatus)
                    : _depositStatusLabel(request),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOwner) ...[
            _SummaryRow(
              label: 'Item fee',
              value: _money(request.lenderBaseEarning),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Damage deduction',
              value: _money(request.lenderDamageEarning),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Manual payout total',
              value: _money(request.lenderTotalEarning),
              emphasized: true,
            ),
            const SizedBox(height: 8),
            Text(
              _manualPayoutMessage(request),
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ] else ...[
            _SummaryRow(
              label: 'Deposit held',
              value: _money(
                request.depositHeldAmount > 0
                    ? request.depositHeldAmount
                    : request.depositAmount,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Damage deduction',
              value: _money(request.damageDeductionAmount),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Refund amount',
              value: _money(request.depositRefundAmount),
              emphasized: true,
            ),
            const SizedBox(height: 8),
            Text(
              _depositLedgerMessage(request),
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStep {
  const _ProgressStep({
    required this.label,
    required this.icon,
    required this.done,
  });

  final String label;
  final IconData icon;
  final bool done;
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.step});

  final _ProgressStep step;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: step.done ? _kBrandTeal : context.softSurface(),
            shape: BoxShape.circle,
            border: Border.all(
              color: step.done ? _kBrandTeal : context.residentOutline(),
            ),
          ),
          child: Icon(
            step.icon,
            color: step.done
                ? Theme.of(context).colorScheme.onPrimary
                : muted,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: step.done ? _kBrandTeal : muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

