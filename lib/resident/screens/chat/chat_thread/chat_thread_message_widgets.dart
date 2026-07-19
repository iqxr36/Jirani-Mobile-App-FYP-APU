// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_thread_message_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_chat_thread_view.dart';

class _PinnedMessageBanner extends StatelessWidget {
  const _PinnedMessageBanner({
    required this.pinned,
    required this.onUnpin,
  });

  final PinnedChatMessage pinned;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.residentOutline()),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin, color: _kBrandTeal, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pinned.senderName,
                        style: TextStyle(
                          color: _kBrandTeal,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pinned.previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Unpin',
                  onPressed: onUnpin,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: context.appMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyComposerBar extends StatelessWidget {
  const _ReplyComposerBar({
    required this.senderName,
    required this.preview,
    required this.onCancel,
  });

  final String senderName;
  final String preview;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          Container(width: 3, height: 42, color: _kBrandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    color: _kBrandTeal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
            color: context.appMuted,
          ),
        ],
      ),
    );
  }
}

class _ReplyQuoteStrip extends StatelessWidget {
  const _ReplyQuoteStrip({
    required this.reply,
    required this.isSentByMe,
  });

  final ChatMessageReply reply;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isSentByMe
            ? Colors.white.withValues(alpha: 0.18)
            : _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSentByMe ? Colors.white : _kBrandTeal,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            style: TextStyle(
              color: isSentByMe ? Colors.white : _kBrandTeal,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSentByMe
                  ? Colors.white.withValues(alpha: 0.92)
                  : context.appInk,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({
    required this.message,
    required this.isSentByMe,
  });

  final chat_core.TextMessage message;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final reply = _replyFromMessageMetadata(message.metadata);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSentByMe ? _kBrandTeal : context.softSurface(),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
              bottomRight: Radius.circular(isSentByMe ? 4 : 16),
            ),
            border: isSentByMe
                ? null
                : Border.all(color: context.residentOutline()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reply != null)
                _ReplyQuoteStrip(reply: reply, isSentByMe: isSentByMe),
              Text(
                message.text,
                style: TextStyle(
                  color: isSentByMe ? Colors.white : context.appInk,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.name,
    required this.imageUrl,
    required this.onBack,
    required this.onDetails,
  });

  final String name;
  final String imageUrl;
  final VoidCallback onBack;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: _kBrandTeal,
              size: 32,
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: context.avatarPlaceholder,
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Connected resident',
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chat details',
            onPressed: onDetails,
            icon: const Icon(Icons.more_horiz_rounded, color: _kBrandTeal),
          ),
        ],
      ),
    );
  }
}

