import 'package:flutter/material.dart';
import 'package:jirani/providers/chat_provider.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/views/chat/resident_chat_thread_view.dart';
import 'package:jirani/views/chat/resident_new_chat_view.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 420;

class ResidentMessagesView extends StatelessWidget {
  const ResidentMessagesView({super.key});

  void _openNewChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResidentNewChatView()),
    );
  }

  void _openThread(BuildContext context, ChatModel chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResidentChatThreadView(initialChat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final chats = provider.chats;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewChat(context),
        backgroundColor: _kBrandTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New Chat'),
      ),
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _MessagesHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                      child: _InboxSummary(
                        isLoading: provider.isLoading,
                        unreadCount: provider.totalUnreadCount,
                        chatCount: chats.length,
                        errorMessage: provider.errorMessage,
                      ),
                    ),
                  ),
                  if (chats.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyInbox(
                        onStartChat: () => _openNewChat(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                      sliver: SliverList.separated(
                        itemCount: chats.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _ChatTile(
                            chat: chats[index],
                            currentUserId: provider.currentUser?.uid ?? '',
                            onTap: () => _openThread(context, chats[index]),
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

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

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
              'Messages',
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

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({
    required this.isLoading,
    required this.unreadCount,
    required this.chatCount,
    required this.errorMessage,
  });

  final bool isLoading;
  final int unreadCount;
  final int chatCount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage?.trim().isNotEmpty == true
        ? errorMessage!.trim()
        : isLoading
        ? 'Loading your conversations...'
        : unreadCount > 0
        ? '$unreadCount unread message${unreadCount == 1 ? '' : 's'}'
        : '$chatCount conversation${chatCount == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined, color: _kBrandTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          if (isLoading)
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.otherParticipantId(currentUserId);
    final name = chat.participantName(otherUserId);
    final imageUrl = chat.participantImageUrl(otherUserId);
    final unread = chat.unreadCountFor(currentUserId);
    final subtitle = chat.lastMessageText.trim().isEmpty
        ? 'Say hello to $name'
        : chat.lastSenderId == currentUserId
        ? 'You: ${chat.lastMessageText}'
        : chat.lastMessageText;
    final time = chat.lastMessageAt == null
        ? ''
        : timeago.format(chat.lastMessageAt!, allowFromNow: true);

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ResidentAvatar(name: name, imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              color: unread > 0 ? _kBrandTeal : _kMutedText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread > 0
                                  ? const Color(0xFF1F2937)
                                  : _kMutedText,
                              fontSize: 12,
                              fontWeight: unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: unread),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResidentAvatar extends StatelessWidget {
  const _ResidentAvatar({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'R'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.substring(0, 1).toUpperCase())
              .join();

    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFCFE4E9),
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: _kBrandTeal,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF90170B),
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, color: _kBrandTeal),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a simple private chat with one of your connected residents.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Start Chat'),
            style: FilledButton.styleFrom(
              backgroundColor: _kBrandTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
