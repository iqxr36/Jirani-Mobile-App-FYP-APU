import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/models/chat_message_model.dart';

const Color _kReportRed = Color(0xFFE53935);

enum ChatMessageAction { reply, pin, deleteForYou, report }

Future<ChatMessageAction?> showChatMessageActionMenu(
  BuildContext context, {
  required ChatMessageModel message,
  required bool isPinned,
  required bool showReport,
}) {
  final timeLabel = DateFormat.jm().format(message.createdAt);
  return showModalBottomSheet<ChatMessageAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChatMessageActionSheet(
      timeLabel: timeLabel,
      isPinned: isPinned,
      showReport: showReport,
    ),
  );
}

class _ChatMessageActionSheet extends StatelessWidget {
  const _ChatMessageActionSheet({
    required this.timeLabel,
    required this.isPinned,
    required this.showReport,
  });

  final String timeLabel;
  final bool isPinned;
  final bool showReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.residentOutline()),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    color: context.appMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () => Navigator.pop(context, ChatMessageAction.reply),
            ),
            _ActionRow(
              icon: Icons.push_pin_outlined,
              label: isPinned ? 'Unpin' : 'Pin',
              onTap: () => Navigator.pop(context, ChatMessageAction.pin),
            ),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for you',
              onTap: () =>
                  Navigator.pop(context, ChatMessageAction.deleteForYou),
            ),
            if (showReport) ...[
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.report_outlined,
                label: 'Report',
                color: _kReportRed,
                onTap: () => Navigator.pop(context, ChatMessageAction.report),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.appInk;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 18),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
