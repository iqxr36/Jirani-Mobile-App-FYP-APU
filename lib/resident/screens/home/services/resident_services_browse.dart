// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_services_browse.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,09-July-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_services_view.dart';

enum _ServiceSection { discover, bookings }

const _serviceSectionOptions = [
  ResidentSectionOption(
    value: _ServiceSection.discover,
    label: 'Browse',
    icon: Icons.home_repair_service_outlined,
  ),
  ResidentSectionOption(
    value: _ServiceSection.bookings,
    label: 'My Requests',
    icon: Icons.receipt_long_rounded,
  ),
];

// Services UI feature: Firestore-backed service discovery, booking, escrow, and handshake workspace.
class ResidentServicesView extends StatefulWidget {
  const ResidentServicesView({super.key});

  @override
  State<ResidentServicesView> createState() => _ResidentServicesViewState();
}

class _ResidentServicesViewState extends State<ResidentServicesView> {
  _ServiceSection _section = _ServiceSection.discover;
  String _query = '';
  String _category = 'all';

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final addButtonBottom = keyboardInset > 0
        ? keyboardInset + JiraniResponsive.scaled(context, 16)
        : bottomSafeArea + JiraniResponsive.scaled(context, 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
            RefreshIndicator(
              color: residentBrandTeal,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ResidentInsetContent(
                      sideInset: sideInset,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ResidentPageHeader(
                              title: 'Services',
                              subtitle:
                                  'Book help from trusted neighbors nearby.',
                            ),
                            const SizedBox(height: 18),
                            ResidentSectionSwitch<_ServiceSection>(
                              selected: _section,
                              options: _serviceSectionOptions,
                              onChanged: (value) =>
                                  setState(() => _section = value),
                            ),
                            if (_section == _ServiceSection.discover) ...[
                              const SizedBox(height: 16),
                              ResidentSearchField(
                                hint: 'Search services',
                                onChanged: (value) =>
                                    setState(() => _query = value),
                              ),
                              const SizedBox(height: 12),
                              ResidentCategoryChips(
                                options: _serviceCategoryOptions,
                                selected: _category,
                                onSelected: (value) =>
                                    setState(() => _category = value),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (user == null)
                    const SliverToBoxAdapter(child: _SignedOutState())
                  else if (_section == _ServiceSection.discover)
                    _DiscoverServicesSliver(
                      query: _query,
                      category: _category,
                      user: user,
                      sideInset: sideInset,
                    )
                  else
                    _ServiceRequestsSliver(
                      user: user,
                      requesterView: true,
                      sideInset: sideInset,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 112)),
                ],
              ),
            ),
            Positioned(
              right: sideInset,
              bottom: addButtonBottom,
              child: _ServiceAddButton(
                onTap: () => _openAddServiceFlow(context, user),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _openAddServiceFlow(BuildContext context, AppUser? user) async {
    if (user == null) {
      _showSnack(context, 'Sign in before listing a service.');
      return;
    }
    if (!user.isVerifiedResident) {
      _showSnack(context, 'Only verified residents can list services.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentAddNewServiceView(user: user),
      ),
    );
  }
}
class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    return Padding(
      padding: EdgeInsets.fromLTRB(sideInset, 12, sideInset, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: residentMaxContentWidth),
          child: const ResidentStateCard(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in required',
            message: 'Sign in to browse and manage resident services.',
          ),
        ),
      ),
    );
  }
}
class _DiscoverServicesSliver extends StatelessWidget {
  const _DiscoverServicesSliver({
    required this.query,
    required this.category,
    required this.user,
    required this.sideInset,
  });

  final String query;
  final String category;
  final AppUser user;
  final double sideInset;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceModel>>(
      stream: provider.activeServicesStream(communityId: user.communityId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _ServiceInsetCard(
              sideInset: sideInset,
              child: ResidentStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load services',
                message: _friendlyServiceError(snapshot.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, _) => _ServiceInsetCard(
              sideInset: sideInset,
              child: const _ServiceSkeletonCard(),
            ),
          );
        }
        final servicesList = (snapshot.data ?? const <ServiceModel>[])
            .where((service) => service.providerId != user.uid)
            .where((service) => category == 'all' || service.category == category)
            .where((service) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return service.title.toLowerCase().contains(q) ||
                  service.providerName.toLowerCase().contains(q) ||
                  service.description.toLowerCase().contains(q);
            })
            .toList();
        if (servicesList.isEmpty) {
          return SliverToBoxAdapter(
            child: _ServiceInsetCard(
              sideInset: sideInset,
              child: const ResidentStateCard(
                icon: Icons.home_repair_service_outlined,
                title: 'No services found',
                message: 'Try another search or create the first listing.',
              ),
            ),
          );
        }
        return SliverList.separated(
          itemCount: servicesList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final service = servicesList[index];
            return _ServiceInsetCard(
              sideInset: sideInset,
              child: _ServiceListingCard(
                service: service,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceDetailView(
                      user: user,
                      service: service,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceRequestsSliver extends StatelessWidget {
  const _ServiceRequestsSliver({
    required this.user,
    required this.requesterView,
    required this.sideInset,
  });

  final AppUser user;
  final bool requesterView;
  final double sideInset;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<services.ServiceProvider>();
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: requesterView
          ? provider.myRequestsStream(user.uid)
          : provider.incomingRequestsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _ServiceInsetCard(
              sideInset: sideInset,
              child: ResidentStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load requests',
                message: _friendlyServiceError(snapshot.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, _) => _ServiceInsetCard(
              sideInset: sideInset,
              child: const _ServiceSkeletonCard(),
            ),
          );
        }
        final requests = snapshot.data ?? const <ServiceRequestModel>[];
        if (requests.isEmpty) {
          return SliverToBoxAdapter(
            child: _ServiceInsetCard(
              sideInset: sideInset,
              child: ResidentStateCard(
                icon: requesterView
                    ? Icons.event_available_outlined
                    : Icons.inbox_outlined,
                title: requesterView ? 'No requests yet' : 'No incoming requests',
                message: requesterView
                    ? 'Request a service from Browse and it will continue here.'
                    : 'Bookings from requesters will appear here.',
              ),
            ),
          );
        }
        return SliverList.separated(
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _ServiceInsetCard(
              sideInset: sideInset,
              child: _ServiceRequestSummaryListCard(
                request: request,
                user: user,
                requesterView: requesterView,
                onViewProfile: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PublicResidentProfileView(
                      userId: requesterView
                          ? request.providerId
                          : request.requesterId,
                      fallbackName: requesterView
                          ? request.providerName
                          : request.requesterName,
                    ),
                  ),
                ),
                onOpen: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceTransactionView(
                      initialRequest: request,
                      user: user,
                      requesterView: requesterView,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceInsetCard extends StatelessWidget {
  const _ServiceInsetCard({required this.sideInset, required this.child});

  final double sideInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: residentMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
