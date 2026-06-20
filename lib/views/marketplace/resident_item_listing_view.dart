import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/item_listing_form.dart';
import 'package:jirani/core/utils/marketplace_borrow_flow.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/providers/borrow_request_provider.dart';
import 'package:jirani/providers/chat_provider.dart';
import 'package:jirani/providers/item_provider.dart';
import 'package:jirani/providers/review_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/chat/resident_chat_thread_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kDanger = Color(0xFFB00020);
const Color _kInk = Color(0xFF1F2937);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 440;
const int _kMaxPhotos = 5;
final DateFormat _shortDateFormat = DateFormat('MMM d');

enum _LenderDashboardTab { listed, incoming }

class ResidentMyItemsView extends StatefulWidget {
  const ResidentMyItemsView({super.key});

  @override
  State<ResidentMyItemsView> createState() => _ResidentMyItemsViewState();
}

class _ResidentMyItemsViewState extends State<ResidentMyItemsView> {
  String? _watchingUid;
  _LenderDashboardTab _selectedTab = _LenderDashboardTab.listed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || _watchingUid == user.uid) return;
    _watchingUid = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemProvider>().watchMyItems();
      context.read<BorrowRequestProvider>().watchIncomingRequests(user.uid);
    });
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
          child: CustomScrollView(
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
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'My Items',
                              style: TextStyle(
                                color: _kInk,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _CircleIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Add item',
                            onTap: user == null
                                ? () => _showSnack(
                                    context,
                                    'Sign in before listing an item.',
                                  )
                                : () => _openListingForm(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ProfileListingSummary(user: user),
                      const SizedBox(height: 14),
                      _LenderDashboardTabs(
                        selected: _selectedTab,
                        onChanged: (tab) => setState(() => _selectedTab = tab),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (_selectedTab == _LenderDashboardTab.listed)
                _buildListedItemsSliver(sideInset: sideInset, user: user)
              else
                _buildIncomingRequestsSliver(sideInset: sideInset, user: user),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListedItemsSliver({
    required double sideInset,
    required AppUser? user,
  }) {
    return Consumer2<ItemProvider, BorrowRequestProvider>(
      builder: (context, itemProvider, requestProvider, _) {
        if (itemProvider.isLoading && itemProvider.myItems.isEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: const _StateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading your items',
                message: 'Checking your active and archived listings.',
              ),
            ),
          );
        }

        final error = itemProvider.errorMessage;
        if (error != null && error.isNotEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: _StateCard(
                icon: Icons.error_outline_rounded,
                title: 'Items unavailable',
                message: error.replaceFirst('Exception: ', ''),
              ),
            ),
          );
        }

        final items = itemProvider.myItems;
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: _EmptyMyItemsCard(
                onAdd: user == null ? null : () => _openListingForm(context),
              ),
            ),
          );
        }

        return SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = items[index];
            final pendingCount = _pendingRequestCountForItem(
              item.id,
              requestProvider.incomingRequests,
            );
            final locked = _listingHasLiveBorrow(item);
            return _InsetContent(
              sideInset: sideInset,
              child: _MyItemCard(
                item: item,
                pendingRequestCount: pendingCount,
                locked: locked,
                onEdit: locked
                    ? null
                    : () => _openListingForm(context, item: item),
                onArchive: item.isArchived || locked
                    ? null
                    : () => _confirmArchive(context, item),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestsSliver({
    required double sideInset,
    required AppUser? user,
  }) {
    return Consumer<BorrowRequestProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.incomingRequests.isEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: const _StateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading requests',
                message: 'Checking borrower requests for your listed items.',
              ),
            ),
          );
        }

        final error = provider.errorMessage;
        if (error != null && error.isNotEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: _StateCard(
                icon: Icons.error_outline_rounded,
                title: 'Requests unavailable',
                message: error.replaceFirst('Exception: ', ''),
              ),
            ),
          );
        }

        final requests = provider.incomingRequests;
        if (requests.isEmpty) {
          return SliverToBoxAdapter(
            child: _InsetContent(
              sideInset: sideInset,
              child: const _StateCard(
                icon: Icons.mark_email_unread_outlined,
                title: 'No incoming requests yet',
                message:
                    'Borrow requests from residents will appear here for approval.',
              ),
            ),
          );
        }

        return SliverList.separated(
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _InsetContent(
              sideInset: sideInset,
              child: _IncomingRequestCard(
                request: request,
                onOpen: () => _openRequestDetail(context, request),
                onApprove: user == null || !_requestIsPending(request)
                    ? null
                    : () => _approveRequest(context, request, user),
                onReject: user == null || !_requestIsPending(request)
                    ? null
                    : () => _rejectRequest(context, request, user),
              ),
            );
          },
        );
      },
    );
  }

  void _openListingForm(BuildContext context, {ItemModel? item}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentItemListingFormView(item: item),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive item?'),
          content: Text(
            '${item.title} will disappear from marketplace browsing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kDanger),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<ItemProvider>();
    await provider.archiveItem(item.id);
    if (!context.mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Item archived.');
  }

  void _openRequestDetail(BuildContext context, BorrowRequest request) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentLenderRequestDetailView(initialRequest: request),
      ),
    );
  }

  Future<void> _approveRequest(
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

  Future<void> _rejectRequest(
    BuildContext context,
    BorrowRequest request,
    AppUser user,
  ) async {
    final reason = await _showRejectReasonSheet(context);
    if (reason == null || !context.mounted) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.rejectBorrowRequest(
      requestId: request.id,
      ownerId: user.uid,
      rejectionReason: reason,
    );
    if (!context.mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Request rejected.');
  }
}

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
  final TextEditingController _depositReasonController =
      TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  String _conditionBefore = AppConstants.borrowConditionBeforeGood;
  String _conditionAfter = AppConstants.borrowConditionAfterSame;
  String _depositDecision = AppConstants.depositDecisionReturnDeposit;
  int _rating = 5;
  bool _localReviewSubmitted = false;
  String? _reviewReleaseCheckedRequestId;
  XFile? _handoverProof;

  @override
  void dispose() {
    _returnCodeController.dispose();
    _ownerReturnNotesController.dispose();
    _depositReasonController.dispose();
    _reviewController.dispose();
    super.dispose();
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
              _publishEligibleReviewsOnce(request);
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
                          Row(
                            children: [
                              _CircleIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Back',
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tracking
                                      ? 'Transaction Tracking'
                                      : 'Request Details',
                                  style: const TextStyle(
                                    color: _kInk,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
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
                                            style: const TextStyle(
                                              color: _kInk,
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
                                  style: const TextStyle(
                                    color: _kMutedText,
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
                              depositReasonController: _depositReasonController,
                              reviewController: _reviewController,
                              handoverProofName: _handoverProof?.name,
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
                              onConfirmHandover: () =>
                                  _confirmHandover(request, user),
                              onConfirmReturn: () =>
                                  _confirmReturn(request, user),
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

  Future<void> _rejectRequestFromDetail(
    BuildContext context,
    BorrowRequest request,
    AppUser user,
  ) async {
    final reason = await _showRejectReasonSheet(context);
    if (reason == null || !context.mounted) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.rejectBorrowRequest(
      requestId: request.id,
      ownerId: user.uid,
      rejectionReason: reason,
    );
    if (!context.mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Request rejected.');
  }

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

  Future<void> _pickHandoverProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
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
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Add Handover Proof',
                  style: TextStyle(
                    color: _kInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Optional photo before handing the item to the borrower.',
                  style: TextStyle(
                    color: _kMutedText,
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

  Future<void> _confirmReturn(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final code = _returnCodeController.text.trim();
    if (!_isFourDigitCode(code)) {
      _showSnack(context, 'Enter the 4-digit return code from the borrower.');
      return;
    }
    final issue = _conditionAfter != AppConstants.borrowConditionAfterSame;
    if (issue && _ownerReturnNotesController.text.trim().isEmpty) {
      _showSnack(context, 'Add owner notes for damaged or lost items.');
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.confirmReturn(
      requestId: request.id,
      ownerId: user.uid,
      conditionAfter: _conditionAfter,
      ownerReturnNotes: _ownerReturnNotesController.text.trim(),
      returnCode: code,
    );
    if (!mounted) return;
    _showSnack(
      context,
      provider.errorMessage ??
          (issue
              ? 'Return confirmed. Deposit decision is now required.'
              : 'Return confirmed. Deposit was released automatically.'),
    );
  }

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

  void _publishEligibleReviewsOnce(BorrowRequest request) {
    if (request.status != AppConstants.borrowStatusCompleted ||
        _reviewReleaseCheckedRequestId == request.id) {
      return;
    }
    _reviewReleaseCheckedRequestId = request.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<ReviewProvider>().publishEligibleReviewsForBorrowRequest(
          request,
        ),
      );
    });
  }
}

class _LenderTransactionBody extends StatelessWidget {
  const _LenderTransactionBody({
    required this.request,
    required this.provider,
    required this.conditionBefore,
    required this.conditionAfter,
    required this.depositDecision,
    required this.returnCodeController,
    required this.ownerReturnNotesController,
    required this.depositReasonController,
    required this.reviewController,
    required this.handoverProofName,
    required this.rating,
    required this.localReviewSubmitted,
    required this.onConditionBeforeChanged,
    required this.onConditionAfterChanged,
    required this.onDepositDecisionChanged,
    required this.onRatingChanged,
    required this.onOpenChat,
    required this.onPickHandoverProof,
    required this.onConfirmHandover,
    required this.onConfirmReturn,
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
  final TextEditingController depositReasonController;
  final TextEditingController reviewController;
  final String? handoverProofName;
  final int rating;
  final bool localReviewSubmitted;
  final ValueChanged<String> onConditionBeforeChanged;
  final ValueChanged<String> onConditionAfterChanged;
  final ValueChanged<String> onDepositDecisionChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onOpenChat;
  final VoidCallback onPickHandoverProof;
  final VoidCallback onConfirmHandover;
  final VoidCallback onConfirmReturn;
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
          isLoading: provider.isLoading,
          onConditionAfterChanged: onConditionAfterChanged,
          onOpenChat: onOpenChat,
          onConfirmReturn: onConfirmReturn,
        );
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
                    style: const TextStyle(
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
            style: const TextStyle(
              color: _kMutedText,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 24,
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
    required this.isLoading,
    required this.onConditionAfterChanged,
    required this.onOpenChat,
    required this.onConfirmReturn,
  });

  final BorrowRequest request;
  final String conditionAfter;
  final TextEditingController returnCodeController;
  final TextEditingController ownerReturnNotesController;
  final bool isLoading;
  final ValueChanged<String> onConditionAfterChanged;
  final VoidCallback onOpenChat;
  final VoidCallback onConfirmReturn;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Return Completion'),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Meet Borrower',
            message: 'Inspect the returned item and confirm the return code.',
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
            title: 'Returned Condition',
            message:
                'Choose same condition for automatic deposit release, or report an issue for owner decision.',
            child: _OptionWrap(
              options: _returnConditionOptions,
              selectedValue: conditionAfter,
              onChanged: onConditionAfterChanged,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ownerReturnNotesController,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Owner notes',
              hint: 'Add notes about returned condition',
            ),
          ),
          const SizedBox(height: 12),
          _TrackingStepCard(
            icon: Icons.pin_rounded,
            title: 'Return Code Confirmation',
            message: 'Enter the 4-digit code the borrower shares at return.',
            action: _PrimaryButton(
              label: isLoading ? 'Confirming...' : 'Confirm Return',
              icon: Icons.assignment_return_rounded,
              onTap: isLoading ? null : onConfirmReturn,
            ),
            child: _CodeTextField(
              controller: returnCodeController,
              label: 'Return Code',
            ),
          ),
        ],
      ),
    );
  }
}

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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Rate the Borrower',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Did ${request.borrowerName} treat the item safely and return it on time?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMutedText,
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
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  onRatingUpdate: (value) => onRatingChanged(value.round()),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                minLines: 3,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Private until published',
                  hint: 'Optional comment about item care and punctuality',
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ReviewProvider>(
                builder: (context, provider, _) {
                  return _PrimaryButton(
                    label: localReviewSubmitted
                        ? 'Review Submitted'
                        : provider.isSubmitting
                        ? 'Submitting...'
                        : 'Submit Review',
                    icon: Icons.rate_review_rounded,
                    onTap: localReviewSubmitted || provider.isSubmitting
                        ? null
                        : onSubmitReview,
                  );
                },
              ),
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
              decoration: _inputDecoration(
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: const TextStyle(
                        color: _kMutedText,
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
      color: selected ? _kBrandTeal.withValues(alpha: 0.12) : Colors.white,
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
              color: selected ? _kBrandTeal : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kBrandTeal : _kMutedText,
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
      maxLength: 4,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _kInk,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: '0000',
      ).copyWith(counterText: ''),
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
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _kMutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class ResidentItemListingFormView extends StatefulWidget {
  const ResidentItemListingFormView({super.key, this.item});

  final ItemModel? item;

  @override
  State<ResidentItemListingFormView> createState() =>
      _ResidentItemListingFormViewState();
}

class _ResidentItemListingFormViewState
    extends State<ResidentItemListingFormView> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final List<XFile> _newPhotos = <XFile>[];

  String _category = AppConstants.itemCategoryTools;
  String _condition = AppConstants.itemConditionGood;
  ItemListingPricingType _pricingType = ItemListingPricingType.free;
  int _step = 0;
  bool _submitting = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _category = item.category;
    _condition = item.condition;
    _feeController.text = item.feeAmount == null
        ? ''
        : _amountText(item.feeAmount);
    _depositController.text = item.depositAmount == null
        ? ''
        : _amountText(item.depositAmount);
    _pickupController.text = item.pickupInstructions;
    _pricingType = _pricingTypeFromItem(item);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _depositController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  int get _photoCount =>
      (widget.item?.imageUrls.length ?? 0) + _newPhotos.length;

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    final title = _step == 0
        ? (_isEditing ? 'Edit Item' : 'Add New Item')
        : 'Financial Details';

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: JiraniBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: _step == 0 ? 'Back' : 'Item details',
                            onTap: _submitting
                                ? null
                                : () {
                                    if (_step == 0) {
                                      Navigator.of(context).pop();
                                    } else {
                                      setState(() => _step = 0);
                                    }
                                  },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kBrandTeal,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(sideInset, 10, sideInset, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _step == 0
                              ? _DetailsStep(
                                  key: const ValueKey('details'),
                                  titleController: _titleController,
                                  descriptionController: _descriptionController,
                                  existingImageUrls:
                                      widget.item?.imageUrls ?? const [],
                                  newPhotos: _newPhotos,
                                  category: _category,
                                  condition: _condition,
                                  onPickPhotos: _pickPhotos,
                                  onRemoveNewPhoto: (index) {
                                    setState(() => _newPhotos.removeAt(index));
                                  },
                                  onCategoryChanged: (value) {
                                    if (value != null) {
                                      setState(() => _category = value);
                                    }
                                  },
                                  onConditionChanged: (value) {
                                    if (value != null) {
                                      setState(() => _condition = value);
                                    }
                                  },
                                )
                              : _FinancialStep(
                                  key: const ValueKey('financial'),
                                  pricingType: _pricingType,
                                  feeController: _feeController,
                                  depositController: _depositController,
                                  pickupController: _pickupController,
                                  onPricingTypeChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _pricingType = value;
                                      if (!value.requiresFee) {
                                        _feeController.clear();
                                      }
                                      if (!value.requiresDeposit) {
                                        _depositController.clear();
                                      }
                                    });
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SecondaryButton(
                                label: 'Cancel',
                                icon: Icons.close_rounded,
                                onTap: _submitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PrimaryButton(
                                label: _step == 0
                                    ? 'Next'
                                    : _submitting
                                    ? 'Saving...'
                                    : _isEditing
                                    ? 'Save Item'
                                    : 'List Item',
                                icon: _step == 0
                                    ? Icons.arrow_forward_rounded
                                    : Icons.inventory_2_rounded,
                                onTap: _submitting
                                    ? null
                                    : _step == 0
                                    ? _goToFinancialStep
                                    : _submit,
                              ),
                            ),
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
    );
  }

  Future<void> _pickPhotos() async {
    final remaining = _kMaxPhotos - _photoCount;
    if (remaining <= 0) {
      _showSnack(context, 'You can upload up to $_kMaxPhotos photos.');
      return;
    }
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1440,
      maxHeight: 1440,
      imageQuality: 84,
    );
    if (picked.isEmpty) return;
    setState(() {
      _newPhotos.addAll(picked.take(remaining));
    });
    if (picked.length > remaining && mounted) {
      _showSnack(context, 'Only $remaining more photos were added.');
    }
  }

  void _goToFinancialStep() {
    final error = ItemListingFormValidator.validateDetails(
      title: _titleController.text,
      category: _category,
      condition: _condition,
      description: _descriptionController.text,
      imageCount: _photoCount,
    );
    if (error != null) {
      _showSnack(context, error);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      _showSnack(context, 'Sign in before listing an item.');
      return;
    }
    if (!user.isVerifiedResident) {
      _showSnack(
        context,
        'Only verified residents can list marketplace items.',
      );
      return;
    }

    final error = ItemListingFormValidator.validateFinancial(
      pricingType: _pricingType,
      feeText: _feeController.text,
      depositText: _depositController.text,
    );
    if (error != null) {
      _showSnack(context, error);
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<ItemProvider>();
    final fee = _pricingType.requiresFee
        ? ItemListingFormValidator.parseAmount(_feeController.text)
        : null;
    final deposit = _pricingType.requiresDeposit
        ? ItemListingFormValidator.parseAmount(_depositController.text)
        : null;
    final imagePaths = _newPhotos.map((photo) => photo.path).toList();

    if (_isEditing) {
      await provider.updateItem(
        itemId: widget.item!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        condition: _condition,
        hasUsageFee: _pricingType.requiresFee,
        feeAmount: fee,
        hasDeposit: _pricingType.requiresDeposit,
        depositAmount: deposit,
        pickupInstructions: _pickupController.text,
        newImagePaths: imagePaths.isEmpty ? null : imagePaths,
      );
    } else {
      await provider.addItem(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        condition: _condition,
        imagePaths: imagePaths,
        hasUsageFee: _pricingType.requiresFee,
        feeAmount: fee,
        hasDeposit: _pricingType.requiresDeposit,
        depositAmount: deposit,
        pickupInstructions: _pickupController.text,
        currentUser: user,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    final providerError = provider.errorMessage;
    if (providerError != null && providerError.isNotEmpty) {
      _showSnack(context, providerError.replaceFirst('Exception: ', ''));
      return;
    }
    _showSnack(context, _isEditing ? 'Item updated.' : 'Item listed.');
    Navigator.of(context).pop();
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.existingImageUrls,
    required this.newPhotos,
    required this.category,
    required this.condition,
    required this.onPickPhotos,
    required this.onRemoveNewPhoto,
    required this.onCategoryChanged,
    required this.onConditionChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<String> existingImageUrls;
  final List<XFile> newPhotos;
  final String category;
  final String condition;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemoveNewPhoto;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onConditionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Item Photos'),
        const SizedBox(height: 8),
        _PhotoPickerPanel(
          existingImageUrls: existingImageUrls,
          newPhotos: newPhotos,
          onPickPhotos: onPickPhotos,
          onRemoveNewPhoto: onRemoveNewPhoto,
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Item Details'),
        const SizedBox(height: 8),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Item Name',
                  hint: 'e.g. Book, Ladder...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Category',
                        hint: 'Select a category',
                      ),
                      items: _categoryOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onCategoryChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: condition,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Condition',
                        hint: 'Select condition',
                      ),
                      items: _conditionOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onConditionChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                minLines: 5,
                maxLines: 7,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint:
                      'Describe the item, what is included, and any special rules for borrowing.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialStep extends StatelessWidget {
  const _FinancialStep({
    super.key,
    required this.pricingType,
    required this.feeController,
    required this.depositController,
    required this.pickupController,
    required this.onPricingTypeChanged,
  });

  final ItemListingPricingType pricingType;
  final TextEditingController feeController;
  final TextEditingController depositController;
  final TextEditingController pickupController;
  final ValueChanged<ItemListingPricingType?> onPricingTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<ItemListingPricingType>(
            initialValue: pricingType,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Pricing Type',
              hint: 'Select a pricing type',
            ),
            items: ItemListingPricingType.values
                .map(
                  (type) => DropdownMenuItem<ItemListingPricingType>(
                    value: type,
                    child: Text(
                      type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onPricingTypeChanged,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MoneyField(
                  label: 'Daily Fee',
                  controller: feeController,
                  enabled: pricingType.requiresFee,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyField(
                  label: 'Deposit',
                  controller: depositController,
                  enabled: pricingType.requiresDeposit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pickupController,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Pickup Instructions',
              hint: 'e.g. Meet at lobby after owner confirmation.',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Set the daily fee. Hourly borrowing is calculated automatically from this price and capped at the daily rate.',
              style: TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPickerPanel extends StatelessWidget {
  const _PhotoPickerPanel({
    required this.existingImageUrls,
    required this.newPhotos,
    required this.onPickPhotos,
    required this.onRemoveNewPhoto,
  });

  final List<String> existingImageUrls;
  final List<XFile> newPhotos;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemoveNewPhoto;

  int get _photoCount => existingImageUrls.length + newPhotos.length;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 212),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _photoCount == 0
                ? Colors.black.withValues(alpha: 0.30)
                : _kBrandTeal.withValues(alpha: 0.20),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _photoCount == 0
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CameraBadge(),
                  SizedBox(height: 12),
                  Text(
                    'Upload your Item (Up to 5)',
                    style: TextStyle(
                      color: _kInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to choose your photo.',
                    style: TextStyle(
                      color: _kMutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _CameraBadge(size: 42),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_photoCount of $_kMaxPhotos photos selected',
                          style: const TextStyle(
                            color: _kInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onPickPhotos,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 102,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index < existingImageUrls.length) {
                          return _PhotoThumb(url: existingImageUrls[index]);
                        }
                        final newIndex = index - existingImageUrls.length;
                        return _PhotoThumb(
                          localPath: newPhotos[newIndex].path,
                          onRemove: () => onRemoveNewPhoto(newIndex),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({this.url, this.localPath, this.onRemove});

  final String? url;
  final String? localPath;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (localPath != null && localPath!.isNotEmpty) {
      image = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      image = CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover);
    } else {
      image = const Icon(Icons.inventory_2_rounded, color: _kBrandTeal);
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 102,
            height: 102,
            color: _kBrandTeal.withValues(alpha: 0.08),
            child: image,
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 6,
            top: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.56),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFCFE5E9),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        color: Colors.black,
        size: size * 0.58,
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: label, hint: '0.00').copyWith(
        prefixIcon: Container(
          width: 44,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: enabled ? 0.10 : 0.05),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
          ),
          child: Text(
            'RM',
            style: TextStyle(
              color: enabled ? _kInk : _kMutedText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileListingSummary extends StatelessWidget {
  const _ProfileListingSummary({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.storefront_rounded, color: _kBrandTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName.trim().isNotEmpty == true
                      ? '${user!.fullName} can lend items'
                      : 'List items for your neighbors',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Published items appear in marketplace for residents in your community.',
                  style: TextStyle(
                    color: _kMutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _EmptyMyItemsCard extends StatelessWidget {
  const _EmptyMyItemsCard({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: _kBrandTeal, size: 46),
          const SizedBox(height: 12),
          const Text(
            'No items listed yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share tools, electronics, books, and household items with trusted neighbors.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'Add Item',
            icon: Icons.add_rounded,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _LenderDashboardTabs extends StatelessWidget {
  const _LenderDashboardTabs({required this.selected, required this.onChanged});

  final _LenderDashboardTab selected;
  final ValueChanged<_LenderDashboardTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _DashboardTabButton(
              label: 'My Listed Items',
              selected: selected == _LenderDashboardTab.listed,
              onTap: () => onChanged(_LenderDashboardTab.listed),
            ),
          ),
          Expanded(
            child: _DashboardTabButton(
              label: 'Incoming Requests',
              selected: selected == _LenderDashboardTab.incoming,
              onTap: () => onChanged(_LenderDashboardTab.incoming),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTabButton extends StatelessWidget {
  const _DashboardTabButton({
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
      color: selected ? _kBrandTeal.withValues(alpha: 0.14) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: _kBrandTeal) : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kBrandTeal : _kMutedText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyItemCard extends StatelessWidget {
  const _MyItemCard({
    required this.item,
    required this.pendingRequestCount,
    required this.locked,
    required this.onEdit,
    required this.onArchive,
  });

  final ItemModel item;
  final int pendingRequestCount;
  final bool locked;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ItemThumb(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_categoryLabel(item.category)} · ${_conditionLabel(item.condition)}',
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          label: _statusLabel(item),
                          tone: _itemStatusTone(item),
                        ),
                        const SizedBox(width: 8),
                        if (pendingRequestCount > 0) ...[
                          _StatusPill(
                            label: '$pendingRequestCount pending',
                            tone: _StatusTone.warning,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            item.hasUsageFee
                                ? '${_money(item.feeAmount)} / day'
                                : 'Free',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kBrandTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ListingMoneyRow(item: item),
          if (locked) ...[
            const SizedBox(height: 10),
            const Text(
              'This listing is locked while a borrower transaction is in progress.',
              style: TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DangerButton(
                  label: item.isArchived ? 'Archived' : 'Archive',
                  icon: Icons.archive_outlined,
                  onTap: onArchive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 82,
        height: 82,
        color: _kBrandTeal.withValues(alpha: 0.10),
        child: imageUrl.isEmpty
            ? const Icon(Icons.inventory_2_rounded, color: _kBrandTeal)
            : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

class _ListingMoneyRow extends StatelessWidget {
  const _ListingMoneyRow({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniInfoTile(
            label: 'Daily fee',
            value: item.hasUsageFee ? _money(item.feeAmount) : 'Free',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniInfoTile(
            label: 'Deposit',
            value: item.hasDeposit ? _money(item.depositAmount) : 'None',
          ),
        ),
      ],
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final BorrowRequest request;
  final VoidCallback onOpen;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: _GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequestBorrowerAvatar(request: request, radius: 22),
                  const SizedBox(width: 10),
                  Expanded(child: _BorrowerSummary(request: request)),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: _requestStatusLabel(request),
                    tone: _requestStatusTone(request),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _RequestItemThumb(request: request, size: 74),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.itemTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _requestDateRange(request),
                          style: const TextStyle(
                            color: _kMutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (request.pickupTime.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Pickup: ${request.pickupTime.trim()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kMutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RequestMoneyRow(request: request),
              if (_requestIsPending(request)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DangerButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        onTap: onReject,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer<BorrowRequestProvider>(
                        builder: (context, provider, _) {
                          return _PrimaryButton(
                            label: provider.isLoading
                                ? 'Approving...'
                                : 'Approve',
                            icon: Icons.check_rounded,
                            onTap: provider.isLoading ? null : onApprove,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BorrowerSummary extends StatelessWidget {
  const _BorrowerSummary({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.borrowerName.isEmpty ? 'Resident' : request.borrowerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kInk,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(
              request.borrowerVerified
                  ? Icons.verified_user_rounded
                  : Icons.person_outline_rounded,
              color: request.borrowerVerified ? _kBrandTeal : _kMutedText,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                request.borrowerVerified ? 'Verified resident' : 'Resident',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kMutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, color: Color(0xFFE5A500), size: 14),
            const SizedBox(width: 2),
            Text(
              request.borrowerReputationScore.toStringAsFixed(1),
              style: const TextStyle(
                color: _kMutedText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestBorrowerAvatar extends StatelessWidget {
  const _RequestBorrowerAvatar({required this.request, this.radius = 24});

  final BorrowRequest request;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = request.borrowerName.trim();
    final initial = name.isEmpty ? 'R' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _kBrandTeal.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: const TextStyle(color: _kBrandTeal, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RequestItemThumb extends StatelessWidget {
  const _RequestItemThumb({required this.request, required this.size});

  final BorrowRequest request;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: _kBrandTeal.withValues(alpha: 0.10),
        child: request.itemImageUrl.isEmpty
            ? const Icon(Icons.inventory_2_rounded, color: _kBrandTeal)
            : CachedNetworkImage(
                imageUrl: request.itemImageUrl,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _RequestMoneyRow extends StatelessWidget {
  const _RequestMoneyRow({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniInfoTile(
            label: 'Fee',
            value: request.hasUsageFee
                ? _money(request.usageFeeAmount)
                : 'Free',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniInfoTile(
            label: 'Deposit',
            value: request.hasDeposit ? _money(request.depositAmount) : 'None',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniInfoTile(
            label: 'Total',
            value: _money(
              MarketplaceBorrowFlow.totalDue(
                usageFee: request.usageFeeAmount,
                deposit: request.depositAmount,
              ),
            ),
            emphasized: true,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? _kBrandTeal.withValues(alpha: 0.10)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized ? _kBrandTeal : _kInk,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _kInk,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _InsetContent extends StatelessWidget {
  const _InsetContent({required this.sideInset, required this.child});

  final double sideInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _kInk,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? const Color(0xFF9CA3AF) : _kBrandTeal,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _kBrandTeal, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontWeight: FontWeight.w900,
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

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? const Color(0xFFF3F4F6) : _DangerColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: disabled ? const Color(0xFFE5E7EB) : _kDanger,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: disabled ? _kMutedText : _kDanger, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? _kMutedText : _kDanger,
                    fontWeight: FontWeight.w900,
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

class _DangerColors {
  static const Color surface = Color(0xFFFFF1F2);
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.90),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: onTap == null ? _kMutedText : _kInk),
          ),
        ),
      ),
    );
  }
}

enum _StatusTone { neutral, success, warning, danger }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.tone = _StatusTone.success});

  final String label;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _StatusTone.success => (
        background: _kBrandTeal.withValues(alpha: 0.10),
        foreground: _kBrandTeal,
      ),
      _StatusTone.warning => (
        background: const Color(0xFFFFF7ED),
        foreground: const Color(0xFFB45309),
      ),
      _StatusTone.danger => (
        background: _DangerColors.surface,
        foreground: _kDanger,
      ),
      _StatusTone.neutral => (
        background: _kMutedText.withValues(alpha: 0.12),
        foreground: _kMutedText,
      ),
    };
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ).copyWith(color: colors.foreground),
      ),
    );
  }
}

class _Option {
  const _Option(this.label, this.value);

  final String label;
  final String value;
}

const List<_Option> _categoryOptions = [
  _Option('Tools', AppConstants.itemCategoryTools),
  _Option('Kitchen', AppConstants.itemCategoryKitchen),
  _Option('Electronics', AppConstants.itemCategoryElectronics),
  _Option('Cleaning', AppConstants.itemCategoryCleaning),
  _Option('Study', AppConstants.itemCategoryStudy),
  _Option('Event Items', AppConstants.itemCategoryEventItems),
  _Option('Other', AppConstants.itemCategoryOther),
];

const List<_Option> _conditionOptions = [
  _Option('New', AppConstants.itemConditionNew),
  _Option('Good', AppConstants.itemConditionGood),
  _Option('Used', AppConstants.itemConditionUsed),
];

const List<_Option> _handoverConditionOptions = [
  _Option('Excellent', AppConstants.borrowConditionBeforeExcellent),
  _Option('Good', AppConstants.borrowConditionBeforeGood),
  _Option('Fair', AppConstants.borrowConditionBeforeFair),
  _Option('Damaged', AppConstants.borrowConditionBeforeDamaged),
];

const List<_Option> _returnConditionOptions = [
  _Option('Same condition', AppConstants.borrowConditionAfterSame),
  _Option('Minor issue', AppConstants.borrowConditionAfterMinor),
  _Option('Major damage', AppConstants.borrowConditionAfterMajor),
  _Option('Lost', AppConstants.borrowConditionAfterLost),
];

const List<_Option> _depositDecisionOptions = [
  _Option('Release deposit', AppConstants.depositDecisionReturnDeposit),
  _Option('Withhold deposit', AppConstants.depositDecisionWithholdDeposit),
];

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kBrandTeal, width: 1.4),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
  );
}

ItemListingPricingType _pricingTypeFromItem(ItemModel item) {
  if (item.hasUsageFee && item.hasDeposit) {
    return ItemListingPricingType.feeAndDeposit;
  }
  if (item.hasUsageFee) return ItemListingPricingType.feeOnly;
  if (item.hasDeposit) return ItemListingPricingType.depositOnly;
  return ItemListingPricingType.free;
}

String _amountText(double? amount) {
  if (amount == null) return '';
  return amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

String _money(double? amount) {
  return 'RM ${_amountText(amount ?? 0)}';
}

String _categoryLabel(String category) {
  for (final option in _categoryOptions) {
    if (option.value == category) return option.label;
  }
  return 'Other';
}

String _conditionLabel(String condition) {
  for (final option in _conditionOptions) {
    if (option.value == condition) return option.label;
  }
  return 'Used';
}

String _handoverConditionLabel(String condition) {
  for (final option in _handoverConditionOptions) {
    if (option.value == condition) return option.label;
  }
  return condition.trim().isEmpty ? 'Not recorded' : condition;
}

String _returnConditionLabel(String condition) {
  for (final option in _returnConditionOptions) {
    if (option.value == condition) return option.label;
  }
  return condition.trim().isEmpty ? 'Not recorded' : condition;
}

String _depositDecisionLabel(String decision) {
  for (final option in _depositDecisionOptions) {
    if (option.value == decision) return option.label;
  }
  if (decision == AppConstants.depositDecisionNotRequired) {
    return 'No deposit required';
  }
  if (decision == AppConstants.depositDecisionPending) {
    return 'Pending decision';
  }
  return decision.trim().isEmpty ? 'Not recorded' : decision;
}

String _statusLabel(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return 'Archived';
  }
  if (item.status == AppConstants.itemStatusAvailable) return 'Available';
  if (item.status == AppConstants.itemStatusUnavailable) return 'Unavailable';
  if (item.status == AppConstants.itemStatusBorrowed) return 'Borrowed';
  return item.status;
}

_StatusTone _itemStatusTone(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return _StatusTone.neutral;
  }
  if (item.status == AppConstants.itemStatusAvailable) {
    return _StatusTone.success;
  }
  return _StatusTone.warning;
}

bool _listingHasLiveBorrow(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return false;
  }
  return item.status != AppConstants.itemStatusAvailable;
}

int _pendingRequestCountForItem(String itemId, List<BorrowRequest> requests) {
  return requests
      .where(
        (request) => request.itemId == itemId && _requestIsPending(request),
      )
      .length;
}

bool _requestIsPending(BorrowRequest request) {
  return request.status == AppConstants.borrowStatusPending;
}

String _requestDateRange(BorrowRequest request) {
  final start = _shortDateFormat.format(request.requestedStartDate);
  final end = _shortDateFormat.format(request.expectedReturnDate);
  return start == end ? start : '$start - $end';
}

String _requestStatusLabel(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return 'Pending';
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'Paid'
          : 'Approved';
    case AppConstants.borrowStatusRejected:
      return 'Rejected';
    case AppConstants.borrowStatusCancelled:
      return 'Cancelled';
    case AppConstants.borrowStatusPickupReady:
      return 'Handover Started';
    case AppConstants.borrowStatusHandedOver:
    case AppConstants.borrowStatusActive:
      return 'Active';
    case AppConstants.borrowStatusReturnSubmitted:
      return 'Returning';
    case AppConstants.borrowStatusCompleted:
      return 'Completed';
    default:
      return request.status;
  }
}

_StatusTone _requestStatusTone(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return _StatusTone.warning;
    case AppConstants.borrowStatusRejected:
    case AppConstants.borrowStatusCancelled:
      return _StatusTone.danger;
    case AppConstants.borrowStatusCompleted:
      return _StatusTone.success;
    default:
      return _StatusTone.neutral;
  }
}

String _requestReadOnlyMessage(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'The borrower has paid. Start handover when you meet them in person.'
          : 'Request approved. The borrower must complete payment before pickup coordination continues.';
    case AppConstants.borrowStatusRejected:
      return request.rejectionReason.isEmpty
          ? 'This request has been rejected.'
          : request.rejectionReason;
    case AppConstants.borrowStatusCancelled:
      return 'The borrower cancelled this request.';
    case AppConstants.borrowStatusCompleted:
      return 'This borrowing transaction is complete.';
    default:
      return 'This request is no longer pending, so approval actions are locked.';
  }
}

String _depositSummaryMessage(BorrowRequest request) {
  if (!request.hasDeposit) {
    return 'The return is confirmed. No deposit was required for this item.';
  }
  if (request.depositDecision == AppConstants.depositDecisionReturnDeposit) {
    return 'The return is confirmed and the deposit was released automatically.';
  }
  if (request.depositDecision == AppConstants.depositDecisionWithholdDeposit) {
    final reason = request.depositDecisionReason.trim();
    return reason.isEmpty
        ? 'The return is confirmed and the deposit was withheld.'
        : 'The return is confirmed and the deposit was withheld. Reason: $reason';
  }
  return 'The return is confirmed. Deposit decision is pending.';
}

bool _isFourDigitCode(String value) {
  return RegExp(r'^\d{4}$').hasMatch(value.trim());
}

AppUser _borrowerFromRequest({
  required BorrowRequest request,
  required AppUser currentUser,
}) {
  final names = _splitName(request.borrowerName);
  final now = DateTime.now();
  return AppUser(
    uid: request.borrowerId,
    firstName: names.$1,
    lastName: names.$2,
    email: request.borrowerEmail,
    phoneNumber: request.borrowerPhoneNumber,
    emailVerified: true,
    phoneVerified: request.borrowerPhoneNumber.trim().isNotEmpty,
    role: AppConstants.roleResident,
    verificationStatus: request.borrowerVerified
        ? AppConstants.verificationVerified
        : AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: currentUser.communityId,
    communityName: currentUser.communityName,
    unitNumber: '',
    reputationScore: request.borrowerReputationScore,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

(String, String) _splitName(String fullName) {
  final clean = fullName.trim();
  if (clean.isEmpty) return ('Resident', '');
  final parts = clean.split(RegExp(r'\s+'));
  if (parts.length == 1) return (parts.first, '');
  return (parts.first, parts.skip(1).join(' '));
}

Future<String?> _showRejectReasonSheet(BuildContext context) async {
  final controller = TextEditingController();
  String? errorText;
  try {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Reject Request',
                      style: TextStyle(
                        color: _kInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add a short reason so the borrower understands your decision.',
                      style: TextStyle(
                        color: _kMutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        label: 'Reason',
                        hint: 'Example: Item is unavailable that day',
                      ).copyWith(errorText: errorText),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: 'Cancel',
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DangerButton(
                            label: 'Reject',
                            icon: Icons.block_rounded,
                            onTap: () {
                              final reason = controller.text.trim();
                              if (reason.isEmpty) {
                                setSheetState(() {
                                  errorText = 'Reason is required.';
                                });
                                return;
                              }
                              Navigator.of(context).pop(reason);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
