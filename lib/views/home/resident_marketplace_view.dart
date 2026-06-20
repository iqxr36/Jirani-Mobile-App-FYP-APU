import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:jirani/core/constants/app_constants.dart';
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
import 'package:jirani/views/marketplace/resident_item_listing_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFE29578);
const Color _kInk = Color(0xFF1F2937);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 440;

final DateFormat _shortDateFormat = DateFormat('d MMM yyyy');
final DateFormat _compactDateFormat = DateFormat('MMM d');

enum _MarketplaceSection { browse, requests }

enum _RentalMode { daily, hourly }

enum _PaymentMethod { googlePay, card }

class _CategoryFilter {
  const _CategoryFilter(this.label, this.value);

  final String label;
  final String value;
}

const List<_CategoryFilter> _categoryFilters = [
  _CategoryFilter('All Items', 'all'),
  _CategoryFilter('Tools', AppConstants.itemCategoryTools),
  _CategoryFilter('Kitchen', AppConstants.itemCategoryKitchen),
  _CategoryFilter('Electronics', AppConstants.itemCategoryElectronics),
  _CategoryFilter('Cleaning', AppConstants.itemCategoryCleaning),
  _CategoryFilter('Study', AppConstants.itemCategoryStudy),
  _CategoryFilter('Events', AppConstants.itemCategoryEventItems),
  _CategoryFilter('Other', AppConstants.itemCategoryOther),
];

class ResidentMarketplaceView extends StatefulWidget {
  const ResidentMarketplaceView({super.key});

  @override
  State<ResidentMarketplaceView> createState() =>
      _ResidentMarketplaceViewState();
}

class _ResidentMarketplaceViewState extends State<ResidentMarketplaceView> {
  final TextEditingController _searchController = TextEditingController();
  _MarketplaceSection _section = _MarketplaceSection.browse;
  String? _watchingUserId;
  String? _watchingCommunityId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) return;
    if (_watchingUserId == user.uid &&
        _watchingCommunityId == user.communityId) {
      return;
    }
    _watchingUserId = user.uid;
    _watchingCommunityId = user.communityId;
    final itemProvider = context.read<ItemProvider>();
    final requestProvider = context.read<BorrowRequestProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      itemProvider.watchAvailableItems(communityId: user.communityId);
      requestProvider.watchMyBorrowRequests(user.uid);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(AppUser? user) async {
    if (user == null) return;
    context.read<ItemProvider>().watchAvailableItems(
      communityId: user.communityId,
    );
    context.read<BorrowRequestProvider>().watchMyBorrowRequests(user.uid);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final addButtonBottom = keyboardInset > 0
        ? keyboardInset + JiraniResponsive.scaled(context, 16)
        : bottomSafeArea + JiraniResponsive.scaled(context, 104);

    return JiraniBackground(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: _kBrandTeal,
              onRefresh: () => _refresh(user),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideInset),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _kMaxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              const _PageHeader(
                                title: 'Marketplace',
                                subtitle:
                                    'Borrow useful items from trusted neighbors nearby.',
                              ),
                              const SizedBox(height: 18),
                              _SectionSwitch(
                                selected: _section,
                                onChanged: (section) =>
                                    setState(() => _section = section),
                              ),
                              const SizedBox(height: 18),
                              if (_section == _MarketplaceSection.browse) ...[
                                _SearchField(
                                  controller: _searchController,
                                  hint: 'Search in marketplace...',
                                  onChanged: context
                                      .read<ItemProvider>()
                                      .setSearchQuery,
                                ),
                                const SizedBox(height: 14),
                                const _CategoryChips(),
                              ],
                              const SizedBox(height: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (user == null)
                    SliverToBoxAdapter(
                      child: _InsetContent(
                        sideInset: sideInset,
                        child: const _StateCard(
                          icon: Icons.lock_outline_rounded,
                          title: 'Sign in required',
                          message:
                              'Your resident profile is needed before using marketplace.',
                        ),
                      ),
                    )
                  else if (_section == _MarketplaceSection.browse)
                    ..._buildBrowseSlivers(context, sideInset)
                  else
                    ..._buildRequestSlivers(context, sideInset, user),
                  const SliverToBoxAdapter(child: SizedBox(height: 112)),
                ],
              ),
            ),
            Positioned(
              right: sideInset,
              bottom: addButtonBottom,
              child: _AddButton(onTap: () => _openAddItemFlow(context, user)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddItemFlow(BuildContext context, AppUser? user) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before listing an item.')),
      );
      return;
    }

    if (!user.isVerifiedResident) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only verified residents can list marketplace items.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentItemListingFormView(),
      ),
    );
    if (!context.mounted) return;
    context.read<ItemProvider>().watchAvailableItems(
      communityId: user.communityId,
    );
  }

  List<Widget> _buildBrowseSlivers(BuildContext context, double sideInset) {
    return [
      Consumer<ItemProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.availableItems.isEmpty) {
            return SliverList.separated(
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, _) => _InsetContent(
                sideInset: sideInset,
                child: const _MarketplaceSkeletonCard(),
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
                  title: 'Marketplace unavailable',
                  message: error.replaceFirst('Exception: ', ''),
                ),
              ),
            );
          }

          final items = provider.availableItems;
          if (items.isEmpty) {
            return SliverToBoxAdapter(
              child: _InsetContent(
                sideInset: sideInset,
                child: const _StateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'No items found',
                  message:
                      'Try another search or category. New listings will appear here.',
                ),
              ),
            );
          }

          return SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final item = items[index];
              return _InsetContent(
                sideInset: sideInset,
                child: _MarketplaceCard(
                  item: item,
                  onTap: () {
                    provider.selectItem(item);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MarketplaceItemDetailView(item: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    ];
  }

  List<Widget> _buildRequestSlivers(
    BuildContext context,
    double sideInset,
    AppUser user,
  ) {
    return [
      Consumer<BorrowRequestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myBorrowRequests.isEmpty) {
            return SliverToBoxAdapter(
              child: _InsetContent(
                sideInset: sideInset,
                child: const _StateCard(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Loading requests',
                  message: 'Checking your marketplace activity.',
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
                  message: error,
                ),
              ),
            );
          }

          final requests = provider.myBorrowRequests;
          if (requests.isEmpty) {
            return SliverToBoxAdapter(
              child: _InsetContent(
                sideInset: sideInset,
                child: const _StateCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'No borrow requests yet',
                  message:
                      'Request an item from Browse and it will continue here.',
                ),
              ),
            );
          }

          return SliverList.separated(
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _InsetContent(
                sideInset: sideInset,
                child: _BorrowRequestCard(
                  request: request,
                  onTap: () {
                    provider.selectRequest(request);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MarketplaceTransactionView(initialRequest: request),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    ];
  }
}

class MarketplaceItemDetailView extends StatelessWidget {
  const MarketplaceItemDetailView({super.key, required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);

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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ItemImageGallery(item: item),
                      const SizedBox(height: 18),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: _kInk,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const _StatusPill(label: 'Available'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_categoryLabel(item.category)} · ${_conditionLabel(item.condition)}',
                              style: const TextStyle(
                                color: _kMutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Deposit is held securely and refunded in full when the item is returned in good condition.',
                              style: TextStyle(
                                color: _kMutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassPanel(
                        child: Row(
                          children: [
                            Expanded(
                              child: _AmountTile(
                                label: 'Daily Fee',
                                value: item.hasUsageFee
                                    ? _money(item.feeAmount)
                                    : 'Free',
                                helper: item.hasUsageFee
                                    ? 'Hourly is derived and capped'
                                    : 'No fee',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AmountTile(
                                label: 'Refundable Deposit',
                                value: item.hasDeposit
                                    ? _money(item.depositAmount)
                                    : 'None',
                                helper: item.hasDeposit
                                    ? 'Returned after inspection'
                                    : 'Not required',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('Lender'),
                            const SizedBox(height: 10),
                            _OwnerRow(item: item),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Description'),
                            const SizedBox(height: 8),
                            Text(
                              item.description.trim().isEmpty
                                  ? 'No description has been added yet.'
                                  : item.description.trim(),
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.pickupInstructions.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const _SectionLabel('Pickup Notes'),
                              const SizedBox(height: 8),
                              Text(
                                item.pickupInstructions.trim(),
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Message Owner',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Chat with the owner unlocks after approval and payment are completed.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PrimaryButton(
                              icon: Icons.calendar_month_rounded,
                              label: 'Request',
                              onTap: () => _showBorrowRequestSheet(
                                context: context,
                                item: item,
                              ),
                            ),
                          ),
                        ],
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
}

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
  _PaymentMethod _paymentMethod = _PaymentMethod.googlePay;
  int _rating = 5;
  bool _localReviewSubmitted = false;
  String? _reviewReleaseCheckedRequestId;

  @override
  void dispose() {
    _handoverCodeController.dispose();
    _returnNotesController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

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
    _publishEligibleReviewsOnce(request);

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
                              'Borrowing',
                              style: TextStyle(
                                color: _kInk,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TransactionHeader(request: request),
                      const SizedBox(height: 14),
                      _ProgressPanel(request: request),
                      const SizedBox(height: 14),
                      _TransactionBody(
                        request: request,
                        returnNotesController: _returnNotesController,
                        reviewController: _reviewController,
                        handoverCodeController: _handoverCodeController,
                        rating: _rating,
                        paymentMethod: _paymentMethod,
                        localReviewSubmitted: _localReviewSubmitted,
                        onRatingChanged: (rating) =>
                            setState(() => _rating = rating),
                        onPaymentMethodChanged: (method) =>
                            setState(() => _paymentMethod = method),
                        onPayment: () => _completePayment(request, user),
                        onOpenChat: () => _openChat(request, user),
                        onPickupReady: () => _confirmPickupReady(request, user),
                        onSubmitReturn: () => _submitReturn(request, user),
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

  Future<void> _completePayment(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final requestProvider = context.read<BorrowRequestProvider>();

    try {
      final ok = await requestProvider.completeManualPayment(
        requestId: request.id,
        borrowerId: user.uid,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Payment completed. Chat and handover code are unlocked.'
                : requestProvider.errorMessage ?? 'Payment could not complete.',
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

  Future<void> _confirmPickupReady(BorrowRequest request, AppUser? user) async {
    if (user == null) return;
    final code = _handoverCodeController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit arrival code.')),
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

class _TransactionBody extends StatelessWidget {
  const _TransactionBody({
    required this.request,
    required this.returnNotesController,
    required this.reviewController,
    required this.handoverCodeController,
    required this.rating,
    required this.paymentMethod,
    required this.localReviewSubmitted,
    required this.onRatingChanged,
    required this.onPaymentMethodChanged,
    required this.onPayment,
    required this.onOpenChat,
    required this.onPickupReady,
    required this.onSubmitReturn,
    required this.onSubmitReview,
  });

  final BorrowRequest request;
  final TextEditingController returnNotesController;
  final TextEditingController reviewController;
  final TextEditingController handoverCodeController;
  final int rating;
  final _PaymentMethod paymentMethod;
  final bool localReviewSubmitted;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<_PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onPayment;
  final VoidCallback onOpenChat;
  final VoidCallback onPickupReady;
  final VoidCallback onSubmitReturn;
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
            paymentMethod: paymentMethod,
            onPaymentMethodChanged: onPaymentMethodChanged,
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
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 14),
            child: Divider(thickness: 1.4, color: Color(0xFFCFE5E9)),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _kBrandTeal.withValues(alpha: 0.10)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kBrandTeal : const Color(0xFFE5E7EB),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
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
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _kBrandTeal : _kMutedText,
              ),
            ],
          ),
        ),
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
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final Widget? action;

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
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.request,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onPayment,
  });

  final BorrowRequest request;
  final _PaymentMethod paymentMethod;
  final ValueChanged<_PaymentMethod> onPaymentMethodChanged;
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
              const _SectionLabel('Payment Method'),
              const SizedBox(height: 4),
              const Text(
                'Choose a payment method',
                style: TextStyle(
                  color: _kMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _PaymentMethodTile(
                icon: Icons.phone_iphone_rounded,
                title: 'Google Pay',
                subtitle: 'Fast in-app payment',
                selected: paymentMethod == _PaymentMethod.googlePay,
                onTap: () => onPaymentMethodChanged(_PaymentMethod.googlePay),
              ),
              const SizedBox(height: 10),
              _PaymentMethodTile(
                icon: Icons.credit_card_rounded,
                title: 'Credit / Debit Card',
                subtitle: 'Visa or Mastercard',
                selected: paymentMethod == _PaymentMethod.card,
                onTap: () => onPaymentMethodChanged(_PaymentMethod.card),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kWarmAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Temporary in-app payment. Stripe will replace this action later.',
                  style: TextStyle(
                    color: _kInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Consumer<BorrowRequestProvider>(
          builder: (context, provider, _) {
            return _PrimaryButton(
              icon: Icons.lock_open_rounded,
              label: provider.isLoading ? 'Processing...' : 'Pay Now',
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
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kInk,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              decoration: _inputDecoration(
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
            decoration: _inputDecoration(
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
    final depositReleased = MarketplaceBorrowFlow.hasDepositReleased(request);

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
            depositReleased ? 'Transaction Complete' : 'Deposit Review Pending',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            depositReleased
                ? 'Your ${_money(request.depositAmount ?? 0)} deposit has been released back to you.'
                : 'The lender reported an issue. Deposit release will wait for the owner decision.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMutedText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (depositReleased) ...[
            const SizedBox(height: 18),
            Text(
              'Rate the Lender',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Did the item match the description, and was communication easy with ${request.ownerName}?',
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
              decoration: _inputDecoration(
                label: 'Private until published',
                hint: 'Optional comment about description and communication',
              ),
            ),
            const SizedBox(height: 14),
            Consumer<ReviewProvider>(
              builder: (context, provider, _) {
                return _PrimaryButton(
                  icon: Icons.rate_review_rounded,
                  label: localReviewSubmitted
                      ? 'Review Submitted'
                      : provider.isSubmitting
                      ? 'Submitting...'
                      : 'Submit Review',
                  onTap: localReviewSubmitted || provider.isSubmitting
                      ? null
                      : onSubmitReview,
                );
              },
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
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _RequestThumb(imageUrl: request.itemImageUrl, size: 72),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_compactDateFormat.format(request.requestedStartDate)} - ${_compactDateFormat.format(request.expectedReturnDate)}',
                  style: const TextStyle(
                    color: _kMutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusPill(label: _statusLabel(request)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lender profile view is coming soon.'),
                ),
              );
            },
            child: const Text(
              'View Profile',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.request});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
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
                    : _kMutedText.withValues(alpha: 0.20),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: step.done ? _kBrandTeal : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: step.done ? _kBrandTeal : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            step.icon,
            color: step.done ? Colors.white : _kMutedText,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: step.done ? _kBrandTeal : _kMutedText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({required this.request, required this.onTap});

  final BorrowRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = MarketplaceBorrowFlow.totalDue(
      usageFee: request.usageFeeAmount,
      deposit: request.depositAmount,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: _GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RequestThumb(imageUrl: request.itemImageUrl, size: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_compactDateFormat.format(request.requestedStartDate)} - ${_compactDateFormat.format(request.expectedReturnDate)}',
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(label: _statusLabel(request)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _money(total),
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
              const Icon(Icons.chevron_right_rounded, color: _kMutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({required this.item, required this.onTap});

  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        child: _GlassPanel(
          padding: JiraniResponsive.scaledEdgeInsets(
            context,
            left: 14,
            top: 14,
            right: 14,
            bottom: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardImageStrip(item: item),
              SizedBox(height: JiraniResponsive.scaled(context, 14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _kInk,
                        height: 1.15,
                      ),
                    ),
                  ),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  const _StatusPill(label: 'Available'),
                ],
              ),
              SizedBox(height: JiraniResponsive.scaled(context, 4)),
              Text(
                _categoryLabel(item.category),
                style: const TextStyle(
                  color: _kMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: JiraniResponsive.scaled(context, 12)),
              Row(
                children: [
                  _Avatar(photoUrl: item.ownerPhotoUrl, name: item.ownerName),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.ownerVerified ? 'Verified resident' : 'Resident',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: JiraniResponsive.scaled(context, 8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.hasUsageFee
                            ? '${_money(item.feeAmount)} / day'
                            : 'Free',
                        style: const TextStyle(
                          color: _kBrandTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.hasDeposit
                            ? '${_money(item.depositAmount)} Deposit'
                            : 'No deposit',
                        style: const TextStyle(
                          color: _kMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImageStrip extends StatelessWidget {
  const _CardImageStrip({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.scaled(context, 124),
      child: Row(
        children: [
          Expanded(flex: 3, child: _ItemImage(url: _imageAt(item, 0))),
          SizedBox(width: JiraniResponsive.scaled(context, 10)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 1), compact: true),
                ),
                SizedBox(height: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 2), compact: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImageGallery extends StatelessWidget {
  const _ItemImageGallery({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: JiraniResponsive.scaled(context, 220),
      child: Row(
        children: [
          Expanded(flex: 4, child: _ItemImage(url: _imageAt(item, 0))),
          SizedBox(width: JiraniResponsive.scaled(context, 10)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 1), compact: true),
                ),
                SizedBox(height: JiraniResponsive.scaled(context, 10)),
                Expanded(
                  child: _ItemImage(url: _imageAt(item, 2), compact: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.url, this.compact = false});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = JiraniResponsive.scaledRadius(context, 18);
    if (url.trim().isEmpty) {
      return _ImagePlaceholder(compact: compact, radius: radius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            _ImagePlaceholder(compact: compact, radius: radius),
        errorWidget: (context, _, _) =>
            _ImagePlaceholder(compact: compact, radius: radius),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.compact, required this.radius});

  final bool compact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.08)),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: JiraniResponsive.scaled(context, compact ? 28 : 50),
        color: _kBrandTeal.withValues(alpha: 0.72),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _Avatar(
            photoUrl: item.ownerPhotoUrl,
            name: item.ownerName,
            radius: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.ownerVerified ? 'Verified resident' : 'Resident'} · ${item.ownerReputationScore.toStringAsFixed(1)} rating',
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
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name, this.radius = 17});

  final String photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'R'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.characters.first.toUpperCase())
              .join();
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFCFE5E9),
      child: Text(
        initials,
        style: const TextStyle(color: _kBrandTeal, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _BorrowRequestSheet extends StatefulWidget {
  const _BorrowRequestSheet({required this.item});

  final ItemModel item;

  @override
  State<_BorrowRequestSheet> createState() => _BorrowRequestSheetState();
}

class _BorrowRequestSheetState extends State<_BorrowRequestSheet> {
  final TextEditingController _messageController = TextEditingController();
  _RentalMode _mode = _RentalMode.daily;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _dailyDuration =>
      MarketplaceBorrowFlow.dailyDurationDays(_startDate, _endDate);

  int get _hourlyDuration {
    return MarketplaceBorrowFlow.hourlyDurationHours(
      DateTime(0, 1, 1, _startTime.hour, _startTime.minute),
      DateTime(0, 1, 1, _endTime.hour, _endTime.minute),
    );
  }

  double get _dailyRate =>
      widget.item.hasUsageFee ? widget.item.feeAmount ?? 0 : 0;

  double get _hourlyRate => MarketplaceBorrowFlow.derivedHourlyRate(_dailyRate);

  double get _usageFee {
    if (!widget.item.hasUsageFee) return 0;
    return _mode == _RentalMode.daily
        ? MarketplaceBorrowFlow.dailyUsageFee(
            dailyFee: _dailyRate,
            start: _startDate,
            end: _endDate,
          )
        : MarketplaceBorrowFlow.hourlyUsageFee(
            dailyFee: _dailyRate,
            hours: _hourlyDuration,
          );
  }

  bool get _hourlyFeeCapped =>
      _mode == _RentalMode.hourly &&
      widget.item.hasUsageFee &&
      _hourlyRate * _hourlyDuration > _dailyRate;

  double get _deposit =>
      widget.item.hasDeposit ? widget.item.depositAmount ?? 0 : 0;

  String get _durationLabel => _mode == _RentalMode.daily
      ? '$_dailyDuration days'
      : '$_hourlyDuration hours';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Choose Borrowing Dates',
              style: TextStyle(
                color: _kInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daily fee is set by the lender. Hourly borrowing is calculated from that daily price.',
              style: TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Select Rental Type'),
            const SizedBox(height: 8),
            _ModeSelector(
              selected: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: 14),
            if (_mode == _RentalMode.daily) ...[
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Start Date',
                      value: _shortDateFormat.format(_startDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      label: 'End Date',
                      value: _shortDateFormat.format(_endDate),
                      icon: Icons.event_available_rounded,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Duration', value: _durationLabel),
            ] else ...[
              _PickerTile(
                label: 'Borrow Date',
                value: _shortDateFormat.format(_startDate),
                icon: Icons.calendar_today_rounded,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Start Time',
                      value: _startTime.format(context),
                      icon: Icons.schedule_rounded,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      label: 'End Time',
                      value: _endTime.format(context),
                      icon: Icons.schedule_send_rounded,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Duration', value: _durationLabel),
            ],
            const SizedBox(height: 12),
            if (widget.item.hasUsageFee) ...[
              _SummaryRow(label: 'Daily rate', value: _money(_dailyRate)),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Hourly rate',
                value: '${_money(_hourlyRate)} / hour',
              ),
              if (_mode == _RentalMode.hourly) ...[
                const SizedBox(height: 8),
                _PricingNote(capped: _hourlyFeeCapped),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 3,
              decoration: _inputDecoration(
                label: 'Message to owner',
                hint: 'Optional meetup note or reason for borrowing',
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: _mode == _RentalMode.daily
                  ? 'Item fee'
                  : _hourlyFeeCapped
                  ? 'Item fee (daily cap)'
                  : 'Item fee',
              value: _money(_usageFee),
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Refundable deposit', value: _money(_deposit)),
            const Divider(height: 26),
            _SummaryRow(
              label: 'Total after approval',
              value: _money(
                MarketplaceBorrowFlow.totalDue(
                  usageFee: _usageFee,
                  deposit: _deposit,
                ),
              ),
              emphasized: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Consumer<BorrowRequestProvider>(
                    builder: (context, provider, _) {
                      return _PrimaryButton(
                        icon: Icons.check_rounded,
                        label: provider.isLoading
                            ? 'Sending...'
                            : 'Confirm to Checkout',
                        onTap: provider.isLoading ? null : _submitRequest,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submitRequest() async {
    final user = context.read<AuthViewModel>().currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in before requesting.')),
      );
      return;
    }

    final requestedStart = _mode == _RentalMode.daily
        ? DateTime(_startDate.year, _startDate.month, _startDate.day)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    var expectedReturn = _mode == _RentalMode.daily
        ? DateTime(_endDate.year, _endDate.month, _endDate.day)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _endTime.hour,
            _endTime.minute,
          );
    if (!expectedReturn.isAfter(requestedStart)) {
      expectedReturn = requestedStart.add(const Duration(hours: 1));
    }
    final pickupTime = _mode == _RentalMode.daily
        ? 'Daily rental'
        : '${_startTime.format(context)} - ${_endTime.format(context)}';

    final provider = context.read<BorrowRequestProvider>();
    await provider.createBorrowRequest(
      item: widget.item,
      borrower: user,
      requestedStartDate: requestedStart,
      expectedReturnDate: expectedReturn,
      pickupTime: pickupTime,
      message: _messageController.text,
      usageFeeAmount: _usageFee,
      rentalMode: _mode == _RentalMode.daily
          ? AppConstants.rentalModeDaily
          : AppConstants.rentalModeHourly,
      rentalUnitCount: _mode == _RentalMode.daily
          ? _dailyDuration
          : _hourlyDuration,
      dailyRateSnapshot: widget.item.hasUsageFee ? _dailyRate : null,
      hourlyRateSnapshot: widget.item.hasUsageFee ? _hourlyRate : null,
    );

    if (!mounted) return;
    final error = provider.errorMessage;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null || error.isEmpty
              ? 'Borrow request sent. Watch My Requests for approval.'
              : error,
        ),
      ),
    );
    if (error == null || error.isEmpty) {
      Navigator.of(context).pop();
    }
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});

  final _RentalMode selected;
  final ValueChanged<_RentalMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Daily',
              selected: selected == _RentalMode.daily,
              onTap: () => onChanged(_RentalMode.daily),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Hourly',
              selected: selected == _RentalMode.hourly,
              onTap: () => onChanged(_RentalMode.hourly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingNote extends StatelessWidget {
  const _PricingNote({required this.capped});

  final bool capped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            capped ? Icons.savings_outlined : Icons.schedule_rounded,
            color: _kBrandTeal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              capped
                  ? 'Hourly total reached the same-day daily cap, so you will not pay more than the daily rate.'
                  : 'Hourly borrowing uses the daily fee divided by ${MarketplaceBorrowFlow.hourlyBillingHoursPerDay}.',
              style: const TextStyle(
                color: _kInk,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kBrandTeal : _kMutedText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kBrandTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kMutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 54,
          decoration: BoxDecoration(
            color: _kBrandTeal,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF59666B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({required this.selected, required this.onChanged});

  final _MarketplaceSection selected;
  final ValueChanged<_MarketplaceSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SectionButton(
              label: 'Browse',
              icon: Icons.storefront_rounded,
              selected: selected == _MarketplaceSection.browse,
              onTap: () => onChanged(_MarketplaceSection.browse),
            ),
          ),
          Expanded(
            child: _SectionButton(
              label: 'My Requests',
              icon: Icons.receipt_long_rounded,
              selected: selected == _MarketplaceSection.requests,
              onTap: () => onChanged(_MarketplaceSection.requests),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBrandTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : _kMutedText),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _kInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: JiraniResponsive.scaled(context, 56),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 20),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: JiraniResponsive.scaled(context, 22),
            offset: Offset(0, JiraniResponsive.scaled(context, 10)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: JiraniResponsive.scaled(context, 16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _kBrandTeal,
            size: JiraniResponsive.scaled(context, 22),
          ),
          SizedBox(width: JiraniResponsive.scaled(context, 12)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: const TextStyle(
                  color: Color(0xFF59666B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: const TextStyle(
                color: _kInk,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ItemProvider>().selectedCategoryFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < _categoryFilters.length; i++) ...[
            _CategoryChip(
              label: _categoryFilters[i].label,
              selected: selected == _categoryFilters[i].value,
              onTap: () => context.read<ItemProvider>().setCategoryFilter(
                _categoryFilters[i].value,
              ),
            ),
            if (i != _categoryFilters.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: JiraniResponsive.scaled(context, 40),
        constraints: const BoxConstraints(minWidth: 56),
        padding: EdgeInsets.symmetric(
          horizontal: JiraniResponsive.scaled(context, 16),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kBrandTeal : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _kBrandTeal
                : Colors.white.withValues(alpha: 0.88),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.12 : 0.05),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _kInk,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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

class _MarketplaceSkeletonCard extends StatelessWidget {
  const _MarketplaceSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 124,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 18,
            width: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
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

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kBrandTeal,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? _kInk : _kMutedText,
              fontSize: emphasized ? 15 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasized ? _kBrandTeal : _kInk,
              fontSize: emphasized ? 17 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  const _CodeDisplay({required this.label, required this.code});

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _kBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

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
            child: Icon(icon, color: _kInk),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = JiraniResponsive.scaled(context, 56);
    return Material(
      color: _kBrandTeal,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: JiraniResponsive.scaled(context, 30),
          ),
        ),
      ),
    );
  }
}

class _RequestThumb extends StatelessWidget {
  const _RequestThumb({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _ItemImage(url: imageUrl, compact: true),
    );
  }
}

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
  );
}

void _showBorrowRequestSheet({
  required BuildContext context,
  required ItemModel item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BorrowRequestSheet(item: item),
  );
}

AppUser _ownerFromRequest({
  required BorrowRequest request,
  required AppUser currentUser,
}) {
  final names = _splitName(request.ownerName);
  final now = DateTime.now();
  return AppUser(
    uid: request.ownerId,
    firstName: names.$1,
    lastName: names.$2,
    email: request.ownerEmail,
    phoneNumber: '',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationVerified,
    profileImageUrl: '',
    communityId: currentUser.communityId,
    communityName: currentUser.communityName,
    unitNumber: '',
    reputationScore: 0,
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

String _imageAt(ItemModel item, int index) {
  return index < item.imageUrls.length ? item.imageUrls[index] : '';
}

String _money(double? value) {
  final amount = value ?? 0;
  final text = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'RM $text';
}

String _requestDateRange(BorrowRequest request) {
  final start = _shortDateFormat.format(request.requestedStartDate);
  final end = _shortDateFormat.format(request.expectedReturnDate);
  return start == end ? start : '$start - $end';
}

String _categoryLabel(String category) {
  switch (category) {
    case AppConstants.itemCategoryTools:
      return 'Tools';
    case AppConstants.itemCategoryKitchen:
      return 'Kitchen';
    case AppConstants.itemCategoryElectronics:
      return 'Electronics';
    case AppConstants.itemCategoryCleaning:
      return 'Cleaning';
    case AppConstants.itemCategoryStudy:
      return 'Study';
    case AppConstants.itemCategoryEventItems:
      return 'Event Items';
    default:
      return 'Other';
  }
}

String _conditionLabel(String condition) {
  switch (condition) {
    case AppConstants.itemConditionNew:
      return 'New';
    case AppConstants.itemConditionGood:
      return 'Good condition';
    default:
      return 'Used';
  }
}

String _statusLabel(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return 'Pending';
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'Paid'
          : 'Checkout';
    case AppConstants.borrowStatusRejected:
      return 'Rejected';
    case AppConstants.borrowStatusCancelled:
      return 'Cancelled';
    case AppConstants.borrowStatusPickupReady:
      return 'Handover';
    case AppConstants.borrowStatusActive:
    case AppConstants.borrowStatusHandedOver:
      return 'Active';
    case AppConstants.borrowStatusReturnSubmitted:
      return 'Returning';
    case AppConstants.borrowStatusCompleted:
      return 'Complete';
    default:
      return request.status;
  }
}

bool _isAfterApproval(String status) {
  return status == AppConstants.borrowStatusPickupReady ||
      status == AppConstants.borrowStatusActive ||
      status == AppConstants.borrowStatusHandedOver ||
      status == AppConstants.borrowStatusReturnSubmitted ||
      status == AppConstants.borrowStatusCompleted;
}
