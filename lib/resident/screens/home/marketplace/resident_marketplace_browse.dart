// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_marketplace_browse.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_marketplace_view.dart';

// Marketplace browse feature: shows available items, resident borrow requests, filters, and add-item entrypoint.
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

  // Marketplace browse feature: refreshes available listings and borrower request streams for the current resident.
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
        : bottomSafeArea + JiraniResponsive.scaled(context, 20);

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

  // Marketplace lender feature: opens the listing form only for verified residents with marketplace access.
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

