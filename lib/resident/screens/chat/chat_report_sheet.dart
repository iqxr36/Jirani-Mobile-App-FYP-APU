import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/utils/chat_report_formatters.dart';

const Color _kBrandTeal = Color(0xFF006D77);

// Report UI feature: carries the chat report category, note, and message-selection choice back to the thread screen.
class ChatReportSubmission {
  const ChatReportSubmission({
    required this.category,
    required this.note,
  });

  final String category;
  final String note;
}

Future<ChatReportSubmission?> showChatReportSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  ChatMessageModel? highlightedMessage,
}) {
  return showDialog<ChatReportSubmission>(
    context: context,
    builder: (context) => _ChatReportDialog(
      title: title,
      subtitle: subtitle,
      highlightedMessage: highlightedMessage,
    ),
  );
}

// Report UI feature: dialog used to submit chat/message reports to admin.
class _ChatReportDialog extends StatefulWidget {
  const _ChatReportDialog({
    required this.title,
    required this.subtitle,
    required this.highlightedMessage,
  });

  final String title;
  final String subtitle;
  final ChatMessageModel? highlightedMessage;

  @override
  State<_ChatReportDialog> createState() => _ChatReportDialogState();
}

class _ChatReportDialogState extends State<_ChatReportDialog> {
  String? _selectedCategory;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Report UI feature: validates the report form and returns the report submission data.
  void _submit() {
    final category = _selectedCategory;
    if (category == null) return;
    Navigator.of(context).pop(
      ChatReportSubmission(
        category: category,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.highlightedMessage;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.subtitle,
                style: TextStyle(color: context.appMuted, height: 1.4),
              ),
              if (message != null) ...[
                const SizedBox(height: 14),
                _MessagePreviewCard(message: message),
              ],
              const SizedBox(height: 16),
              Text(
                'What is the issue?',
                style: TextStyle(
                  color: context.appInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in AppConstants.chatReportCategories)
                    ChoiceChip(
                      label: Text(chatReportCategoryLabel(category)),
                      selected: _selectedCategory == category,
                      selectedColor: _kBrandTeal.withValues(alpha: 0.18),
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Tell admins anything else they should know',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedCategory == null ? null : _submit,
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final body = switch (message.type) {
      AppConstants.chatMessageImage => message.text.trim().isEmpty
          ? 'Image attachment'
          : message.text.trim(),
      AppConstants.chatMessageFile =>
        message.fileName.trim().isEmpty
            ? 'File attachment'
            : message.fileName.trim(),
      _ => message.text.trim().isEmpty ? 'Message' : message.text.trim(),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported message',
            style: TextStyle(
              color: _kBrandTeal,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: context.appInk,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
