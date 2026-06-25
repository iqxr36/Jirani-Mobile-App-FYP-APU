part of '../resident_connections_view.dart';

class _ResidentConnectionsViewState extends State<ResidentConnectionsView> {
  void _openConnectionRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResidentConnectionRequestsView(communityName: widget.communityName),
      ),
    );
  }

  Future<void> _handleNeighborAction(AppUser neighbor) async {
    final provider = context.read<ConnectionProvider>();
    final connection = provider.connectionWith(neighbor.uid);
    final messenger = ScaffoldMessenger.of(context);
    final name = neighbor.fullName.isNotEmpty ? neighbor.fullName : 'neighbor';

    try {
      if (provider.hasIncomingRequest(neighbor.uid)) {
        _openConnectionRequests();
        return;
      }
      if (provider.hasOutgoingRequest(neighbor.uid) && connection != null) {
        await provider.withdrawRequest(connection);
        messenger.showSnackBar(
          SnackBar(content: Text('Connection request to $name withdrawn.')),
        );
        return;
      }
      if (provider.isConnected(neighbor.uid)) {
        messenger.showSnackBar(
          SnackBar(content: Text('You are already connected with $name.')),
        );
        return;
      }

      await provider.sendRequest(neighbor);
      messenger.showSnackBar(
        SnackBar(content: Text('Connection request sent to $name.')),
      );
    } catch (_) {
      final message =
          provider.errorMessage ?? 'Unable to update this connection.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final communityName = widget.communityName?.trim().isNotEmpty == true
        ? widget.communityName!.trim().toUpperCase()
        : (provider.currentUser?.communityName.trim().isNotEmpty == true
              ? provider.currentUser!.communityName.trim().toUpperCase()
              : 'ONE SOUTH RESIDENCE');

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _BottomActionBar(
        onShowAll: () {},
        onMyConnections: _openConnectionRequests,
        pendingCount: provider.incomingRequestCount,
      ),
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
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ConnectionsHeader(),
                          const SizedBox(height: 20),
                          _CommunityPill(label: communityName),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: _kPageGutter),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kCardMaxWidth,
                      ),
                      child: _NeighborGrid(
                        neighbors: provider.communityResidents,
                        connectionProvider: provider,
                        onNeighborAction: _handleNeighborAction,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 124)),
            ],
          ),
        ),
      ),
    );
  }
}
