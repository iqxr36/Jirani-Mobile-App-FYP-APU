part of '../resident_item_listing_view.dart';

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
                      _ScreenTitleBar(
                        title: 'My Items',
                        onBack: () => Navigator.of(context).pop(),
                        trailing: _CircleIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Add item',
                            onTap: user == null
                                ? () => _showSnack(
                                    context,
                                    'Sign in before listing an item.',
                                  )
                                : () => _openListingForm(context),
                        ),
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
                onEdit: locked || _itemIsArchived(item)
                    ? null
                    : () => _openListingForm(context, item: item),
                onArchive: _itemIsArchived(item) || locked
                    ? null
                    : () => _confirmArchive(context, item),
                onUnarchive: _itemIsArchived(item) && !locked
                    ? () => _confirmUnarchive(context, item)
                    : null,
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
                onViewBorrowerProfile: () =>
                    _openBorrowerProfile(context, request),
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

  Future<void> _confirmUnarchive(BuildContext context, ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unarchive item?'),
          content: Text(
            '${item.title} will appear in marketplace browsing again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unarchive'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<ItemProvider>();
    await provider.unarchiveItem(item.id);
    if (!context.mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Item unarchived.');
  }

  void _openRequestDetail(BuildContext context, BorrowRequest request) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentLenderRequestDetailView(initialRequest: request),
      ),
    );
  }

  void _openBorrowerProfile(BuildContext context, BorrowRequest request) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublicResidentProfileView(
          userId: request.borrowerId,
          fallbackName: request.borrowerName,
        ),
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
          Text(
            'No items listed yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share tools, electronics, books, and household items with trusted neighbors.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
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
      color: selected
          ? _kBrandTeal.withValues(alpha: 0.14)
          : context.softSurface(),
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

class _MyItemCard extends StatelessWidget {
  const _MyItemCard({
    required this.item,
    required this.pendingRequestCount,
    required this.locked,
    required this.onEdit,
    required this.onArchive,
    required this.onUnarchive,
  });

  final ItemModel item;
  final int pendingRequestCount;
  final bool locked;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

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
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_categoryLabel(item.category)} · ${_conditionLabel(item.condition)}',
                      style: TextStyle(
                        color: muted,
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
                            style: TextStyle(
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
            Text(
              'This listing is locked while a borrower transaction is in progress.',
              style: TextStyle(
                color: context.appMuted,
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
                child: _itemIsArchived(item)
                    ? _SecondaryButton(
                        label: 'Unarchive',
                        icon: Icons.unarchive_outlined,
                        onTap: onUnarchive,
                      )
                    : _DangerButton(
                        label: 'Archive',
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
    required this.onViewBorrowerProfile,
    required this.onApprove,
    required this.onReject,
  });

  final BorrowRequest request;
  final VoidCallback onOpen;
  final VoidCallback onViewBorrowerProfile;
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusPill(
                        label: _requestStatusLabel(request),
                        tone: _requestStatusTone(request),
                      ),
                      const SizedBox(height: 8),
                      _TinyTextButton(
                        label: 'Profile',
                        icon: Icons.person_search_rounded,
                        onTap: onViewBorrowerProfile,
                      ),
                    ],
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
                          style: TextStyle(
                            color: context.appInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _requestDateRange(request),
                          style: TextStyle(
                            color: context.appMuted,
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
                            style: TextStyle(
                              color: context.appMuted,
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
          style: TextStyle(
            color: context.appInk,
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
              color: request.borrowerVerified ? _kBrandTeal : context.appMuted,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                request.borrowerVerified ? 'Verified resident' : 'Resident',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appMuted,
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
              style: TextStyle(
                color: context.appMuted,
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
        style: TextStyle(color: _kBrandTeal, fontWeight: FontWeight.w900),
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

