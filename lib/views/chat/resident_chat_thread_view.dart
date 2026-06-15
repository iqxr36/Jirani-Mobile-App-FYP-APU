import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/providers/chat_provider.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF6B7280);

class ResidentChatThreadView extends StatefulWidget {
  const ResidentChatThreadView({super.key, required this.initialChat});

  final ChatModel initialChat;

  @override
  State<ResidentChatThreadView> createState() => _ResidentChatThreadViewState();
}

class _ResidentChatThreadViewState extends State<ResidentChatThreadView> {
  late final chat_core.InMemoryChatController _chatController;
  StreamSubscription<List<ChatMessageModel>>? _messagesSub;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchMessages());
  }

  void _watchMessages() {
    final provider = context.read<ChatProvider>();
    final currentUserId = provider.currentUser?.uid ?? '';
    _messagesSub = provider.watchMessages(widget.initialChat.id).listen((
      messages,
    ) {
      final chatMessages = messages
          .map((message) => message.toChatMessage(currentUserId: currentUserId))
          .toList(growable: false);
      _chatController.setMessages(chatMessages, animated: false);
      final latestChat = provider.chatById(widget.initialChat.id) ??
          widget.initialChat;
      unawaited(provider.markChatRead(latestChat).catchError((_) {}));
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendText(String text) async {
    final provider = context.read<ChatProvider>();
    final chat = provider.chatById(widget.initialChat.id) ?? widget.initialChat;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.sendTextMessage(chat: chat, text: text);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Message not sent.')),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AttachmentPickerSheet(),
    );
    if (action == null || !mounted) return;

    if (action == _AttachmentAction.photo) {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      await _previewAndSendAttachment(
        bytes: bytes,
        fileName: image.name,
        type: AppConstants.chatMessageImage,
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null || !mounted) return;
    await _previewAndSendAttachment(
      bytes: bytes,
      fileName: file.name,
      type: AppConstants.chatMessageFile,
    );
  }

  Future<void> _previewAndSendAttachment({
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaPreviewSheet(
        bytes: bytes,
        fileName: fileName,
        isImage: type == AppConstants.chatMessageImage,
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ChatProvider>();
    final chat = provider.chatById(widget.initialChat.id) ?? widget.initialChat;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.sendAttachmentMessage(
        chat: chat,
        bytes: bytes,
        fileName: fileName,
        type: type,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Attachment not sent.')),
      );
    }
  }

  Future<void> _openMessage(chat_core.Message message) async {
    String source = '';
    if (message is chat_core.ImageMessage) {
      source = message.source;
    } else if (message is chat_core.FileMessage) {
      source = message.source;
    }
    if (source.isEmpty) return;
    final uri = Uri.tryParse(source);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showChatDetails(ChatModel chat, String currentUserId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatDetailsSheet(
        chat: chat,
        currentUserId: currentUserId,
        onDelete: () => _deleteChat(chat),
        onReport: () => _reportChat(chat),
      ),
    );
  }

  Future<void> _deleteChat(ChatModel chat) async {
    Navigator.of(context).pop();
    final provider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteChatForCurrentUser(chat);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Unable to delete chat.')),
      );
    }
  }

  Future<void> _reportChat(ChatModel chat) async {
    Navigator.of(context).pop();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Chat'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tell admins what happened',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;

    final provider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.reportChat(chat: chat, reason: reason);
      messenger.showSnackBar(const SnackBar(content: Text('Chat reported.')));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Unable to report chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentUser = provider.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final chat = provider.chatById(widget.initialChat.id) ?? widget.initialChat;
    final otherUserId = chat.otherParticipantId(currentUserId);
    final otherName = chat.participantName(otherUserId);
    final otherImageUrl = chat.participantImageUrl(otherUserId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ThreadHeader(
                name: otherName,
                imageUrl: otherImageUrl,
                onBack: () => Navigator.of(context).pop(),
                onDetails: () => _showChatDetails(chat, currentUserId),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Chat(
                    currentUserId: currentUserId,
                    resolveUser: (id) async {
                      if (id == currentUserId) {
                        return chat_core.User(
                          id: currentUserId,
                          name: currentUser?.fullName,
                          imageSource: currentUser?.profileImageUrl,
                        );
                      }
                      return chat_core.User(
                        id: otherUserId,
                        name: otherName,
                        imageSource: otherImageUrl,
                      );
                    },
                    chatController: _chatController,
                    onMessageSend: _sendText,
                    onAttachmentTap: _pickAttachment,
                    onMessageTap: (context, message, {required index, required details}) {
                      _openMessage(message);
                    },
                    builders: chat_core.Builders(
                      chatAnimatedListBuilder: (context, itemBuilder) {
                        return ChatAnimatedListReversed(
                          itemBuilder: itemBuilder,
                          bottomPadding: 86,
                        );
                      },
                      emptyChatListBuilder: (context) => const _EmptyThread(),
                    ),
                    theme: chat_core.ChatTheme.fromThemeData(
                      Theme.of(context),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                  ),
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
            backgroundColor: const Color(0xFFCFE4E9),
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
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Connected resident',
                  style: TextStyle(
                    color: _kMutedText,
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

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Text(
            'Send Attachment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _SheetAction(
            icon: Icons.image_outlined,
            title: 'Photo',
            subtitle: 'Choose an image from gallery',
            onTap: () => Navigator.of(context).pop(_AttachmentAction.photo),
          ),
          const SizedBox(height: 10),
          _SheetAction(
            icon: Icons.attach_file_rounded,
            title: 'File',
            subtitle: 'Send a document or other file',
            onTap: () => Navigator.of(context).pop(_AttachmentAction.file),
          ),
        ],
      ),
    );
  }
}

class _MediaPreviewSheet extends StatelessWidget {
  const _MediaPreviewSheet({
    required this.bytes,
    required this.fileName,
    required this.isImage,
  });

  final Uint8List bytes;
  final String fileName;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Text(
            'Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(bytes, height: 220, fit: BoxFit.cover),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBrandTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: _kBrandTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: _kBrandTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

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
            backgroundColor: const Color(0xFFCFE4E9),
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty
                ? const Icon(Icons.person_outline, color: _kBrandTeal, size: 34)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Private chat with a connected resident',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMutedText,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
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
          color: Colors.black.withValues(alpha: 0.15),
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
                      style: const TextStyle(
                        color: _kMutedText,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No messages yet. Start the conversation below.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kMutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _AttachmentAction { photo, file }
