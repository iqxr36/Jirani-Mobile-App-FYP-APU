part of '../resident_services_view.dart';

class ServiceTransactionView extends StatefulWidget {
  const ServiceTransactionView({
    super.key,
    required this.initialRequest,
    required this.user,
    required this.requesterView,
  });

  final ServiceRequestModel initialRequest;
  final AppUser user;
  final bool requesterView;

  @override
  State<ServiceTransactionView> createState() => _ServiceTransactionViewState();
}

class _ServiceTransactionViewState extends State<ServiceTransactionView> {
  final TextEditingController _arrivalCodeController = TextEditingController();
  final TextEditingController _completionCodeController =
      TextEditingController();
  String _generatedArrivalCode = '';
  String _generatedCompletionCode = '';

  @override
  void dispose() {
    _arrivalCodeController.dispose();
    _completionCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 28;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  sideInset,
                  8,
                  sideInset,
                  bottomInset,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StreamBuilder<ServiceRequestModel?>(
                        stream: context
                            .read<services.ServiceProvider>()
                            .requestStream(widget.initialRequest.id),
                        initialData: widget.initialRequest,
                        builder: (context, snapshot) {
                          final request = snapshot.data ?? widget.initialRequest;
                          return ResidentScreenTitleBar(
                            title: _transactionScreenTitle(
                              request: request,
                              requesterView: widget.requesterView,
                            ),
                            onBack: () => Navigator.of(context).pop(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<ServiceRequestModel?>(
                        stream: context
                            .read<services.ServiceProvider>()
                            .requestStream(widget.initialRequest.id),
                        initialData: widget.initialRequest,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return ResidentStateCard(
                              icon: Icons.error_outline_rounded,
                              title: 'Tracking unavailable',
                              message: _friendlyServiceError(snapshot.error),
                            );
                          }
                          final request = snapshot.data;
                          if (request == null) {
                            return const ResidentStateCard(
                              icon: Icons.receipt_long_outlined,
                              title: 'Request not found',
                              message:
                                  'This service request may have been removed.',
                            );
                          }
                          return _ServiceTransactionBody(
                            request: request,
                            user: widget.user,
                            requesterView: widget.requesterView,
                            arrivalCodeController: _arrivalCodeController,
                            completionCodeController: _completionCodeController,
                            generatedArrivalCode: _generatedArrivalCode,
                            generatedCompletionCode: _generatedCompletionCode,
                            onGenerateArrivalCode: () =>
                                _generateArrivalCode(request),
                            onSubmitArrivalCode: () =>
                                _submitArrivalCode(request),
                            onGenerateCompletionCode: () =>
                                _generateCompletionCode(request),
                            onSubmitCompletionCode: () =>
                                _submitCompletionCode(request),
                          );
                        },
                      ),
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

  Future<void> _generateArrivalCode(ServiceRequestModel request) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await context
          .read<services.ServiceProvider>()
          .generateArrivalCode(
            requestId: request.id,
            providerId: widget.user.uid,
          );
      if (!mounted) return;
      final cleanCode = code?.trim() ?? '';
      if (cleanCode.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not generate arrival code.')),
        );
        return;
      }
      setState(() => _generatedArrivalCode = cleanCode);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Arrival code generated. Show it to the requester.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _submitArrivalCode(ServiceRequestModel request) async {
    final messenger = ScaffoldMessenger.of(context);
    final code = _arrivalCodeController.text.trim();
    final codeError = Validators.validateFourDigitCode(code);
    if (codeError != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(codeError.replaceFirst('Code', 'Arrival code'))),
      );
      return;
    }
    try {
      await context.read<services.ServiceProvider>().submitArrivalCode(
        requestId: request.id,
        requesterId: widget.user.uid,
        code: code,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Arrival confirmed. Work is now in progress.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _generateCompletionCode(ServiceRequestModel request) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code =
          await context.read<services.ServiceProvider>().generateCompletionCode(
                requestId: request.id,
                requesterId: widget.user.uid,
              );
      if (!mounted) return;
      final cleanCode = code?.trim() ?? '';
      if (cleanCode.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not generate completion code.')),
        );
        return;
      }
      setState(() => _generatedCompletionCode = cleanCode);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Completion code generated. Show it to the provider.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _submitCompletionCode(ServiceRequestModel request) async {
    final messenger = ScaffoldMessenger.of(context);
    final code = _completionCodeController.text.trim();
    final codeError = Validators.validateFourDigitCode(code);
    if (codeError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(codeError.replaceFirst('Code', 'Completion code')),
        ),
      );
      return;
    }
    try {
      await context.read<services.ServiceProvider>().submitCompletionCode(
            requestId: request.id,
            providerId: widget.user.uid,
            code: code,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Completion confirmed. Payout processing can begin.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _ServiceTransactionBody extends StatelessWidget {
  const _ServiceTransactionBody({
    required this.request,
    required this.user,
    required this.requesterView,
    required this.arrivalCodeController,
    required this.completionCodeController,
    required this.generatedArrivalCode,
    required this.generatedCompletionCode,
    required this.onGenerateArrivalCode,
    required this.onSubmitArrivalCode,
    required this.onGenerateCompletionCode,
    required this.onSubmitCompletionCode,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;
  final TextEditingController arrivalCodeController;
  final TextEditingController completionCodeController;
  final String generatedArrivalCode;
  final String generatedCompletionCode;
  final VoidCallback onGenerateArrivalCode;
  final VoidCallback onSubmitArrivalCode;
  final VoidCallback onGenerateCompletionCode;
  final VoidCallback onSubmitCompletionCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ServiceTransactionHeader(
          request: request,
          requesterView: requesterView,
        ),
        const SizedBox(height: 12),
        ResidentProgressPanel(steps: _requestProgressSteps(request)),
        const SizedBox(height: 12),
        _ServiceLedgerPanel(request: request, requesterView: requesterView),
        const SizedBox(height: 12),
        _ServiceActionPanel(
          request: request,
          user: user,
          requesterView: requesterView,
          arrivalCodeController: arrivalCodeController,
          completionCodeController: completionCodeController,
          generatedArrivalCode: generatedArrivalCode,
          generatedCompletionCode: generatedCompletionCode,
          onGenerateArrivalCode: onGenerateArrivalCode,
          onSubmitArrivalCode: onSubmitArrivalCode,
          onGenerateCompletionCode: onGenerateCompletionCode,
          onSubmitCompletionCode: onSubmitCompletionCode,
        ),
      ],
    );
  }
}

class _ServiceTransactionHeader extends StatelessWidget {
  const _ServiceTransactionHeader({
    required this.request,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final personId = requesterView ? request.providerId : request.requesterId;
    final personName = requesterView
        ? request.providerName
        : request.requesterName;
    final personRole = requesterView ? 'Service provider' : 'Requester';

    return ResidentGlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceRequestThumb(
                serviceId: request.serviceId,
                serviceTitle: request.serviceTitle,
                size: 76,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.serviceTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _requestScheduleLabel(request),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ResidentStatusPill(
                          label: _requestStatusLabel(request.status),
                        ),
                        Text(
                          _requestAmountLabel(request),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: residentBrandTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PanelLabel(requesterView ? 'Provider' : 'Requester'),
          const SizedBox(height: 10),
          Row(
            children: [
              ResidentAvatar(name: personName, photoUrl: ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName.trim().isEmpty ? 'Resident' : personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      personRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: residentBrandTeal,
                backgroundColor:
                    residentBrandTeal.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: personId.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => PublicResidentProfileView(
                            userId: personId,
                            fallbackName: personName,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text(
                'View Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceLedgerPanel extends StatelessWidget {
  const _ServiceLedgerPanel({
    required this.request,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final bool requesterView;

  @override
  Widget build(BuildContext context) {
    final total = request.amount ?? 0;
    final payout = request.providerPayoutAmount > 0
        ? request.providerPayoutAmount
        : total;
    return ResidentGlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ResidentIconTile(
                icon: requesterView
                    ? Icons.savings_outlined
                    : Icons.account_balance_wallet_outlined,
                size: 34,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  requesterView ? 'Escrow Payment' : 'Provider Payout',
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ResidentStatusPill(
                label: requesterView
                    ? _paymentStatusLabel(request)
                    : _payoutStatusLabel(request),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResidentSummaryRow(
            label: requesterView ? 'Amount held' : 'Service amount',
            value: request.amount == null ? 'Free' : _money(total),
          ),
          if (request.isHourlyService) ...[
            const SizedBox(height: 8),
            ResidentSummaryRow(
              label: 'Booked duration',
              value:
                  '${request.durationHours} h at ${_money(request.hourlyRate!)} / hour',
            ),
          ],
          const SizedBox(height: 8),
          ResidentSummaryRow(
            label: 'Platform fee',
            value: _money(request.platformFeeAmount),
          ),
          const Divider(height: 24),
          ResidentSummaryRow(
            label: requesterView ? 'Total paid' : 'Expected payout',
            value: request.amount == null ? 'Free' : _money(payout),
            emphasized: true,
          ),
          const SizedBox(height: 8),
          Text(
            _ledgerMessage(request, requesterView),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceActionPanel extends StatelessWidget {
  const _ServiceActionPanel({
    required this.request,
    required this.user,
    required this.requesterView,
    required this.arrivalCodeController,
    required this.completionCodeController,
    required this.generatedArrivalCode,
    required this.generatedCompletionCode,
    required this.onGenerateArrivalCode,
    required this.onSubmitArrivalCode,
    required this.onGenerateCompletionCode,
    required this.onSubmitCompletionCode,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;
  final TextEditingController arrivalCodeController;
  final TextEditingController completionCodeController;
  final String generatedArrivalCode;
  final String generatedCompletionCode;
  final VoidCallback onGenerateArrivalCode;
  final VoidCallback onSubmitArrivalCode;
  final VoidCallback onGenerateCompletionCode;
  final VoidCallback onSubmitCompletionCode;

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.read<services.ServiceProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final busy =
        context.watch<services.ServiceProvider>().isLoading ||
        paymentProvider.isLoading;

    if (requesterView &&
        request.status == AppConstants.serviceRequestStatusPending) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResidentTrackingStepCard(
              icon: Icons.pending_actions_rounded,
              title: 'Waiting for provider approval',
              message:
                  'The provider will review your request. Checkout unlocks once they accept it.',
            ),
            const SizedBox(height: 14),
            ResidentDangerButton(
              icon: Icons.close_rounded,
              label: busy ? 'Working...' : 'Cancel Request',
              onTap: busy
                  ? null
                  : () => _confirmCancelServiceRequest(
                        context,
                        request: request,
                        user: user,
                      ),
            ),
          ],
        ),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusPending) {
      return ResidentGlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelLabel('Request Review'),
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.fact_check_outlined,
              title: 'Accept or reject booking',
              message:
                  'Accepting a paid service asks the requester to complete Xendit checkout before work can begin.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ResidentDangerButton(
                    icon: Icons.close_rounded,
                    label: 'Reject',
                    onTap: busy
                        ? null
                        : () => _guard(
                              context,
                              () => serviceProvider.rejectServiceRequest(
                                requestId: request.id,
                                providerId: user.uid,
                              ),
                              successMessage: 'Booking rejected.',
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ResidentPrimaryButton(
                    icon: Icons.check_rounded,
                    label: busy ? 'Working...' : 'Accept',
                    onTap: busy
                        ? null
                        : () => _guard(
                              context,
                              () => serviceProvider.acceptServiceRequest(
                                requestId: request.id,
                                providerId: user.uid,
                              ),
                              successMessage: 'Booking accepted.',
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (requesterView &&
        request.status ==
            AppConstants.serviceRequestStatusAcceptedAwaitingPayment) {
      return _CheckoutPanel(
        request: request,
        busy: busy,
        onPayment: () => _payForService(context, request),
        onCancel: () => _confirmCancelServiceRequest(
          context,
          request: request,
          user: user,
        ),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusPaidHeld) {
      return _ProviderArrivalCodePanel(
        busy: busy,
        generatedArrivalCode: generatedArrivalCode,
        onGenerateArrivalCode: onGenerateArrivalCode,
      );
    }

    if (requesterView &&
        request.status == AppConstants.serviceRequestStatusPaidHeld) {
      return _RequesterArrivalCodePanel(
        busy: busy,
        arrivalCodeController: arrivalCodeController,
        onSubmitArrivalCode: onSubmitArrivalCode,
      );
    }

    if (requesterView &&
        request.status == AppConstants.serviceRequestStatusInProgress) {
      return _RequesterCompletionCodePanel(
        busy: busy,
        generatedCompletionCode: generatedCompletionCode,
        onGenerateCompletionCode: onGenerateCompletionCode,
        onDispute: () => _showDisputeDialog(context, request.id, user.uid),
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusInProgress) {
      return _ProviderCompletionCodePanel(
        busy: busy,
        completionCodeController: completionCodeController,
        onSubmitCompletionCode: onSubmitCompletionCode,
      );
    }

    if (!requesterView &&
        request.status == AppConstants.serviceRequestStatusAccepted &&
        !request.isPaidService) {
      return ResidentGlassPanel(
        child: ResidentTrackingStepCard(
          icon: Icons.task_alt_rounded,
          title: 'Complete free service',
          message:
              'This request does not require escrow. Mark it complete once the work is done.',
          action: ResidentPrimaryButton(
            icon: Icons.check_rounded,
            label: busy ? 'Completing...' : 'Complete Free Service',
            onTap: busy
                ? null
                : () => _guard(
                      context,
                      () => serviceProvider.completeServiceRequest(
                        requestId: request.id,
                        providerId: user.uid,
                      ),
                    ),
          ),
        ),
      );
    }

    if (request.status == AppConstants.serviceRequestStatusDisputed) {
      return _DisputedPanel(request: request);
    }

    if (request.status == AppConstants.serviceRequestStatusRejected) {
      return const ResidentStateCard(
        icon: Icons.cancel_outlined,
        title: 'Request declined',
        message: 'The provider declined this service request.',
      );
    }

    if (request.status == AppConstants.serviceRequestStatusCancelled) {
      return const ResidentStateCard(
        icon: Icons.block_rounded,
        title: 'Request cancelled',
        message: 'This service request is no longer active.',
      );
    }

    if (request.status == AppConstants.serviceRequestStatusPaymentFailed) {
      return ResidentStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Payment failed',
        message: requesterView
            ? 'Payment did not complete. Try checkout again or cancel the request.'
            : 'The requester payment failed. Waiting for them to retry or cancel.',
        action: requesterView
            ? ResidentPrimaryButton(
                icon: Icons.lock_rounded,
                label: 'Retry Payment',
                onTap: busy ? null : () => _payForService(context, request),
              )
            : null,
      );
    }

    if (request.status ==
            AppConstants.serviceRequestStatusCompletedPayoutPending ||
        request.status == AppConstants.serviceRequestStatusCompletedPayoutSent ||
        request.status == AppConstants.serviceRequestStatusCompleted) {
      return _CompletedPanel(
        request: request,
        user: user,
        requesterView: requesterView,
      );
    }

    return ResidentGlassPanel(
      child: ResidentTrackingStepCard(
        icon: Icons.info_outline_rounded,
        title: _requestStatusLabel(request.status),
        message: _statusHelp(request),
      ),
    );
  }
}

class _ProviderArrivalCodePanel extends StatelessWidget {
  const _ProviderArrivalCodePanel({
    required this.busy,
    required this.generatedArrivalCode,
    required this.onGenerateArrivalCode,
  });

  final bool busy;
  final String generatedArrivalCode;
  final VoidCallback onGenerateArrivalCode;

  @override
  Widget build(BuildContext context) {
    final hasCode = generatedArrivalCode.trim().isNotEmpty;
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Handover Completion'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.pin_rounded,
            title: hasCode ? 'Arrival Code' : 'Arrive / Handover',
            message: hasCode
                ? 'Show or read this code to the requester after arriving. The service starts when they enter it.'
                : 'Generate this when you are physically with the requester and ready to begin the service.',
            action: hasCode
                ? null
                : ResidentPrimaryButton(
                    icon: Icons.qr_code_2_rounded,
                    label: busy ? 'Starting...' : 'Arrive / Handover',
                    onTap: busy ? null : onGenerateArrivalCode,
                  ),
            child: hasCode
                ? _ServiceArrivalCodeDisplay(
                    label: 'Arrival Code',
                    code: generatedArrivalCode,
                  )
                : null,
          ),
          if (hasCode) ...[
            const SizedBox(height: 12),
            ResidentTrackingStepCard(
              icon: Icons.fact_check_outlined,
              title: 'Provider arrival recorded',
              message:
                  'Stay with the requester while they enter the code from your screen.',
            ),
          ],
        ],
      ),
    );
  }
}

class _RequesterArrivalCodePanel extends StatelessWidget {
  const _RequesterArrivalCodePanel({
    required this.busy,
    required this.arrivalCodeController,
    required this.onSubmitArrivalCode,
  });

  final bool busy;
  final TextEditingController arrivalCodeController;
  final VoidCallback onSubmitArrivalCode;

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Confirm Arrival'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Enter arrival code',
            message:
                'The provider has arrived. Enter the 4-digit code from their screen when they are ready to begin.',
            action: ResidentPrimaryButton(
              icon: Icons.handshake_rounded,
              label: busy ? 'Confirming...' : 'Confirm Arrival',
              onTap: busy ? null : onSubmitArrivalCode,
            ),
            child: TextField(
              controller: arrivalCodeController,
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
                  .residentInputDecoration(label: 'Arrival Code', hint: '0000')
                  .copyWith(counterText: ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceArrivalCodeDisplay extends StatelessWidget {
  const _ServiceArrivalCodeDisplay({
    required this.label,
    required this.code,
  });

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    final cleanCode = code.trim().isEmpty ? '----' : code.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: residentBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: residentBrandTeal.withValues(alpha: 0.12)),
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

class _RequesterCompletionCodePanel extends StatelessWidget {
  const _RequesterCompletionCodePanel({
    required this.busy,
    required this.generatedCompletionCode,
    required this.onGenerateCompletionCode,
    required this.onDispute,
  });

  final bool busy;
  final String generatedCompletionCode;
  final VoidCallback onGenerateCompletionCode;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final hasCode = generatedCompletionCode.trim().isNotEmpty;
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Work Completion'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.task_alt_rounded,
            title: hasCode ? 'Completion Code' : 'Approve completed work',
            message: hasCode
                ? 'Give this code to the provider after you approve the completed service. Payout starts when they enter it.'
                : 'Inspect the work. Generate the completion code only when you are satisfied.',
            action: hasCode
                ? null
                : ResidentPrimaryButton(
                    icon: Icons.verified_rounded,
                    label: busy ? 'Generating...' : 'Generate Completion Code',
                    onTap: busy ? null : onGenerateCompletionCode,
                  ),
            child: hasCode
                ? _ServiceArrivalCodeDisplay(
                    label: 'Completion Code',
                    code: generatedCompletionCode,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (hasCode)
            ResidentTrackingStepCard(
              icon: Icons.fact_check_outlined,
              title: 'Approval recorded',
              message:
                  'Stay with the provider while they enter the completion code from your screen.',
            )
          else
            ResidentDangerButton(
              icon: Icons.gavel_rounded,
              label: 'Dispute',
              onTap: busy ? null : onDispute,
            ),
        ],
      ),
    );
  }
}

class _ProviderCompletionCodePanel extends StatelessWidget {
  const _ProviderCompletionCodePanel({
    required this.busy,
    required this.completionCodeController,
    required this.onSubmitCompletionCode,
  });

  final bool busy;
  final TextEditingController completionCodeController;
  final VoidCallback onSubmitCompletionCode;

  @override
  Widget build(BuildContext context) {
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Proof of Work'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Enter completion code',
            message:
                'After the requester approves the work, enter their 4-digit completion code to release payout.',
            action: ResidentPrimaryButton(
              icon: Icons.assignment_turned_in_rounded,
              label: busy ? 'Confirming...' : 'Confirm Completion',
              onTap: busy ? null : onSubmitCompletionCode,
            ),
            child: TextField(
              controller: completionCodeController,
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
                  .residentInputDecoration(
                    label: 'Completion Code',
                    hint: '0000',
                  )
                  .copyWith(counterText: ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.request,
    required this.busy,
    required this.onPayment,
    required this.onCancel,
  });

  final ServiceRequestModel request;
  final bool busy;
  final VoidCallback onPayment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final amount = request.amount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidentGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PanelLabel('Transaction Summary'),
              const SizedBox(height: 12),
              ResidentSummaryRow(label: 'Service', value: request.serviceTitle),
              const SizedBox(height: 8),
              ResidentSummaryRow(
                label: 'Date',
                value: DateFormat('MMM d, yyyy').format(request.preferredDate),
              ),
              const SizedBox(height: 8),
              ResidentSummaryRow(label: 'Time', value: request.preferredTime),
              if (request.isHourlyService) ...[
                const SizedBox(height: 8),
                ResidentSummaryRow(
                  label: 'Duration',
                  value:
                      '${request.durationHours} h at ${_money(request.hourlyRate!)} / hour',
                ),
              ],
              const Divider(height: 28),
              ResidentSummaryRow(
                label: 'Total Due',
                value: _money(amount),
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResidentGlassPanel(
          child: ResidentTrackingStepCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Secure Xendit checkout',
            message:
                'Xendit will open a secure checkout page with Malaysian payment options. Your payment is held until completion is verified.',
            action: ResidentPrimaryButton(
              icon: Icons.lock_rounded,
              label: busy ? 'Opening checkout...' : 'Pay with Xendit',
              onTap: busy ? null : onPayment,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ResidentDangerButton(
          icon: Icons.close_rounded,
          label: busy ? 'Working...' : 'Cancel Request',
          onTap: busy ? null : onCancel,
        ),
      ],
    );
  }
}

class _DisputedPanel extends StatelessWidget {
  const _DisputedPanel({required this.request});

  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    final summary = serviceDisputeSummary(request);
    final typeLabel = request.disputeType.trim().isEmpty
        ? 'Not specified'
        : serviceDisputeTypeLabel(request.disputeType);
    final details = request.disputeReason.trim();
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel('Admin Review'),
          const SizedBox(height: 12),
          ResidentTrackingStepCard(
            icon: Icons.gavel_rounded,
            title: 'Escrow Frozen',
            message:
                'This service is paused while admin reviews the dispute. Funds remain held until admin decides payout or refund.',
            child: Column(
              children: [
                ResidentSummaryRow(
                  label: 'Dispute type',
                  value: typeLabel,
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ResidentSummaryRow(
                    label: 'Details',
                    value: details,
                  ),
                ],
                const SizedBox(height: 8),
                ResidentSummaryRow(
                  label: 'Summary',
                  value: summary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedPanel extends StatefulWidget {
  const _CompletedPanel({
    required this.request,
    required this.user,
    required this.requesterView,
  });

  final ServiceRequestModel request;
  final AppUser user;
  final bool requesterView;

  @override
  State<_CompletedPanel> createState() => _CompletedPanelState();
}

class _CompletedPanelState extends State<_CompletedPanel> {
  late Future<bool> _reviewedFuture;
  final _reviewController = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _reviewedFuture = _loadReviewed();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<bool> _loadReviewed() {
    if (!widget.requesterView) return Future.value(false);
    return context.read<ReviewProvider>().hasUserReviewedServiceRequest(
      serviceRequestId: widget.request.id,
      reviewerId: widget.user.uid,
    );
  }

  Future<void> _submitReview() async {
    await _guard(context, () async {
      await context.read<ReviewProvider>().createServiceReview(
        serviceRequest: widget.request,
        reviewerId: widget.user.uid,
        reviewerName: widget.user.fullName,
        rating: _rating,
        comment: _reviewController.text,
      );
      if (!mounted) return;
      setState(() {
        _reviewedFuture = Future.value(true);
      });
      _showSnack(context, 'Service review submitted.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPayoutSent =
        widget.request.status ==
            AppConstants.serviceRequestStatusCompletedPayoutSent ||
        widget.request.status == AppConstants.serviceRequestStatusCompleted;
    return ResidentGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            isPayoutSent ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: isPayoutSent ? residentBrandTeal : residentWarmAccent,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            isPayoutSent ? 'Service Complete' : 'Payout Processing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.requesterView
                ? 'Completion was verified face to face.'
                : isPayoutSent
                    ? widget.request.settlementMode ==
                            AppConstants.settlementModeSimulated
                        ? 'Test payout recorded for this completed service.'
                        : 'The service payout has been sent.'
                    : 'Completion is verified and payout is being processed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (widget.requesterView)
            FutureBuilder<bool>(
              future: _reviewedFuture,
              builder: (context, snapshot) {
                final reviewed = snapshot.data == true;
                if (reviewed) {
                  return const ResidentTrackingStepCard(
                    icon: Icons.rate_review_rounded,
                    title: 'Review Submitted',
                    message:
                        'Your service review is published to the provider reputation profile.',
                  );
                }
                return _ServiceReviewCard(
                  request: widget.request,
                  rating: _rating,
                  controller: _reviewController,
                  onRatingChanged: (value) => setState(() => _rating = value),
                  onSubmit: _submitReview,
                );
              },
            )
          else
            const ResidentTrackingStepCard(
              icon: Icons.rate_review_rounded,
              title: 'Review Ready',
              message:
                  'The requester can review the completed service from their booking history.',
            ),
        ],
      ),
    );
  }
}

class _ServiceReviewCard extends StatelessWidget {
  const _ServiceReviewCard({
    required this.request,
    required this.rating,
    required this.controller,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final ServiceRequestModel request;
  final int rating;
  final TextEditingController controller;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ResidentTrackingStepCard(
      icon: Icons.rate_review_rounded,
      title: 'Rate the Provider',
      message:
          'How was the service quality, punctuality, and communication with ${request.providerName}?',
      child: Column(
        children: [
          RatingBar.builder(
            initialRating: rating.toDouble(),
            minRating: 1,
            itemSize: 34,
            allowHalfRating: false,
            itemBuilder: (context, _) =>
                const Icon(Icons.star_rounded, color: residentWarmAccent),
            onRatingUpdate: (value) => onRatingChanged(value.round()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            decoration: context.residentInputDecoration(
              label: 'Public review',
              hint: 'Optional comment about quality and communication',
            ),
          ),
          const SizedBox(height: 14),
          Consumer<ReviewProvider>(
            builder: (context, provider, _) {
              return ResidentPrimaryButton(
                icon: Icons.rate_review_rounded,
                label: provider.isSubmitting ? 'Submitting...' : 'Submit Review',
                onTap: provider.isSubmitting ? null : onSubmit,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.appMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

Future<void> _showDisputeDialog(
  BuildContext context,
  String requestId,
  String requesterId,
) async {
  final pageContext = context;
  final detailsController = TextEditingController();
  var selectedType = '';
  try {
    final confirmed = await showDialog<bool>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final detailsRequired = serviceDisputeDetailsRequired(selectedType);
            final canSubmit = selectedType.isNotEmpty &&
                (!detailsRequired || detailsController.text.trim().isNotEmpty);
            final screenWidth = MediaQuery.sizeOf(dialogContext).width;
            final maxDialogWidth =
                JiraniResponsive.maxWidth(JiraniContentWidth.dialog);
            final dialogWidth = screenWidth - 48 < maxDialogWidth
                ? screenWidth - 48
                : maxDialogWidth;
            return AlertDialog(
              title: const Text('Raise Dispute'),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tell us what went wrong so an admin can review your case.',
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(
                              color: dialogContext.appMuted,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedType.isEmpty ? null : selectedType,
                        isExpanded: true,
                        decoration: context.residentInputDecoration(
                          label: 'Dispute type',
                          hint: 'Choose what went wrong',
                        ),
                        items: [
                          for (final option in serviceDisputeTypeOptions)
                            DropdownMenuItem<String>(
                              value: option.key,
                              child: Text(
                                option.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        selectedItemBuilder: (context) {
                          return [
                            for (final option in serviceDisputeTypeOptions)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  option.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ];
                        },
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsController,
                        minLines: 3,
                        maxLines: 5,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: context.residentInputDecoration(
                          label: detailsRequired
                              ? 'Details (required)'
                              : 'Details (optional)',
                          hint: detailsRequired
                              ? 'Explain the issue for admin review'
                              : 'Add more context if helpful',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: !canSubmit
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !pageContext.mounted) return;

    await _guard(pageContext, () async {
      await pageContext.read<services.ServiceProvider>().disputeServiceRequest(
            requestId: requestId,
            requesterId: requesterId,
            disputeType: selectedType,
            details: detailsController.text.trim(),
          );
    });
  } finally {
    detailsController.dispose();
  }
}

Future<void> _payForService(
  BuildContext context,
  ServiceRequestModel request,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final paymentProvider = context.read<PaymentProvider>();
  final result = await paymentProvider.createXenditServicePayment(
    request: request,
    successRedirectUrl:
        'https://final-year-project-faisal.web.app/xendit-payment-success',
    failureRedirectUrl:
        'https://final-year-project-faisal.web.app/xendit-payment-failed',
  );
  if (!context.mounted) return;
  if (result == null || result.checkoutUrl.isEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          paymentProvider.errorMessage ?? 'Could not open Xendit checkout.',
        ),
      ),
    );
    return;
  }
  final opened = await launchUrl(
    Uri.parse(result.checkoutUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!context.mounted) return;
  if (!opened) {
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
  if (!context.mounted) return;
  final feedback = _servicePaymentFeedback(status, paymentProvider);
  messenger.showSnackBar(
    SnackBar(content: Text(feedback.message), duration: feedback.duration),
  );
}

({String message, Duration duration}) _servicePaymentFeedback(
  String? status,
  PaymentProvider provider,
) {
  switch (status) {
    case AppConstants.paymentStatusSucceeded:
      return (
        message: 'Payment received. Arrival verification unlocks shortly.',
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
