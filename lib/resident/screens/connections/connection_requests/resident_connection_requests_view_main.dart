part of '../resident_connection_requests_view.dart';

class ResidentConnectionRequestsView extends StatefulWidget {
  const ResidentConnectionRequestsView({super.key, this.communityName});

  final String? communityName;

  @override
  State<ResidentConnectionRequestsView> createState() =>
      _ResidentConnectionRequestsViewState();
}

class _ResidentConnectionRequestsViewState
    extends State<ResidentConnectionRequestsView> {
  int _selectedTab = 0;

  Future<void> _accept(
    ConnectionProvider provider,
    ConnectionModel connection,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.acceptRequest(connection);
      messenger.showSnackBar(
        const SnackBar(content: Text('Connection request accepted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to accept this request.',
          ),
        ),
      );
    }
  }

  Future<void> _decline(
    ConnectionProvider provider,
    ConnectionModel connection,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.declineRequest(connection);
      messenger.showSnackBar(
        const SnackBar(content: Text('Connection request declined.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to decline this request.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final activeTabErrorMessage =
        (_selectedTab == 0
                ? provider.incomingRequestsError
                : provider.connectionsError)
            ?.trim();
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : (provider.currentUser?.communityName.trim().isNotEmpty == true
              ? provider.currentUser!.communityName.trim().toUpperCase()
              : 'ONE SOUTH RESIDENCE');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _kPageGutter,
                        8,
                        _kPageGutter,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RequestsHeader(),
                          const SizedBox(height: 18),
                          _CommunityBadge(label: communityName),
                          const SizedBox(height: 18),
                          _SegmentedTabBar(
                            selectedIndex: _selectedTab,
                            onTabChanged: (index) =>
                                setState(() => _selectedTab = index),
                          ),
                          const SizedBox(height: 12),
                          _ConnectionStatusCard(
                            isLoading: provider.isLoading,
                            errorMessage: activeTabErrorMessage,
                            requestCount: provider.incomingRequests.length,
                            neighborCount: provider.connections.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedTab == 0) ..._buildRequestsContent(provider),
              if (_selectedTab == 1) ..._buildNeighborsContent(provider),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestsContent(ConnectionProvider provider) {
    final requests = provider.incomingRequests;
    if (requests.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoRequestsState()),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_kPageGutter, 18, _kPageGutter, 0),
        sliver: SliverList.separated(
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final request = requests[index];
            final requester = provider.userById(request.fromUserId);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                child: _RequestCard(
                  connection: request,
                  requester: requester,
                  submitting: provider.isSubmitting,
                  onAccept: () => _accept(provider, request),
                  onDecline: () => _decline(provider, request),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildNeighborsContent(ConnectionProvider provider) {
    final connections = provider.connections;
    final currentUserId = provider.currentUser?.uid ?? '';
    if (connections.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _NoNeighborsState()),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_kPageGutter, 18, _kPageGutter, 0),
        sliver: SliverList.separated(
          itemCount: connections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final connection = connections[index];
            final neighborId = connection.otherUserId(currentUserId);
            final neighbor = provider.userById(neighborId);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                child: _ConnectedNeighborRow(
                  connection: connection,
                  neighbor: neighbor,
                  fallbackUserId: neighborId,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
