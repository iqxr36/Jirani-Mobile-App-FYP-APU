part of '../resident_chat_thread_view.dart';

class _ChatDetailsSheet extends StatelessWidget {
  const _ChatDetailsSheet({
    required this.chat,
    required this.currentUserId,
    required this.onDelete,
    required this.onReport,
  });

  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.otherParticipantId(currentUserId);
    final name = chat.participantName(otherUserId);
    final imageUrl = chat.participantImageUrl(otherUserId);

    return _SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          CircleAvatar(
            radius: 34,
            backgroundColor: context.avatarPlaceholder,
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty
                ? const Icon(Icons.person_outline, color: _kBrandTeal, size: 34)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Private chat with a connected resident',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _SheetAction(
            icon: Icons.flag_outlined,
            title: 'Report Chat',
            subtitle: 'Send this conversation to admins for review',
            onTap: onReport,
          ),
          const SizedBox(height: 10),
          _SheetAction(
            icon: Icons.delete_outline_rounded,
            title: 'Delete Chat',
            subtitle: 'Remove this chat from your inbox',
            destructive: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: context.residentScheme.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.18, blurRadius: 32, dy: 18),
        ),
        child: child,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.residentOutline(lightAlpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFF90170B) : _kBrandTeal;
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
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

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No messages yet. Start the conversation below.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
