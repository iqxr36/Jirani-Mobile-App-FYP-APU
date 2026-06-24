import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/connection_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/resident/screens/chat/resident_chat_thread_view.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

class ResidentNewChatView extends StatelessWidget {
  const ResidentNewChatView({super.key});

  Future<void> _startChat(BuildContext context, AppUser neighbor) async {
    final chatProvider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final chat = await chatProvider.openOrCreateChat(neighbor);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResidentChatThreadView(initialChat: chat),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage ?? 'Unable to start chat.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final neighbors = connectionProvider.acceptedNeighbors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _NewChatHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                      child: _NewChatIntro(
                        loading:
                            connectionProvider.isLoading ||
                            chatProvider.isSubmitting,
                        count: neighbors.length,
                      ),
                    ),
                  ),
                  if (neighbors.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoConnectedResidents(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverList.separated(
                        itemCount: neighbors.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _NeighborChatTile(
                            neighbor: neighbors[index],
                            disabled: chatProvider.isSubmitting,
                            onTap: () => _startChat(context, neighbors[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewChatHeader extends StatelessWidget {
  const _NewChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: _kBrandTeal,
                  size: 32,
                ),
              ),
            ),
            const Text(
              'New Chat',
              style: TextStyle(
                color: _kBrandTeal,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewChatIntro extends StatelessWidget {
  const _NewChatIntro({required this.loading, required this.count});

  final bool loading;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: _kBrandTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0
                  ? 'Connect with residents first, then chat safely.'
                  : 'Choose from $count connected resident${count == 1 ? '' : 's'}.',
              style: TextStyle(
                color: context.appInk,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _NeighborChatTile extends StatelessWidget {
  const _NeighborChatTile({
    required this.neighbor,
    required this.disabled,
    required this.onTap,
  });

  final AppUser neighbor;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = neighbor.fullName.trim().isNotEmpty
        ? neighbor.fullName.trim()
        : 'Resident';

    return Material(
      color: context.glassFill(lightAlpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: context.avatarPlaceholder,
                backgroundImage: neighbor.profileImageUrl.isEmpty
                    ? null
                    : NetworkImage(neighbor.profileImageUrl),
                child: neighbor.profileImageUrl.isEmpty
                    ? const Icon(Icons.person_outline, color: _kBrandTeal)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _neighborDetail(neighbor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chat_bubble_outline, color: _kBrandTeal),
            ],
          ),
        ),
      ),
    );
  }

  String _neighborDetail(AppUser neighbor) {
    if (neighbor.unitNumber.trim().isNotEmpty) {
      return 'Unit ${neighbor.unitNumber.trim()}';
    }
    if (neighbor.communityName.trim().isNotEmpty) {
      return neighbor.communityName.trim();
    }
    return 'Connected resident';
  }
}

class _NoConnectedResidents extends StatelessWidget {
  const _NoConnectedResidents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 54, color: _kBrandTeal),
          const SizedBox(height: 14),
          Text(
            'No connected residents yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open My Community, connect with a verified neighbor, then start chatting here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
