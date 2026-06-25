import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/agent_debug_log.dart';
import 'package:jirani/resident/screens/chat/chat_message_action_menu.dart';
import 'package:jirani/resident/screens/chat/chat_report_sheet.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/models/pinned_chat_message.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const int _kMaxImageBytes = 10 * 1024 * 1024;
const int _kMaxFileBytes = 25 * 1024 * 1024;
const int _kMaxVideoBytes = 50 * 1024 * 1024;

const Set<String> _kImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
const Set<String> _kVideoExtensions = {'mp4', 'mov', 'm4v', 'webm'};
const Set<String> _kDocumentExtensions = {
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
};

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
  if (bytes >= 1024) {
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  }
  return '$bytes B';
}

class _PickedChatAttachment {
  const _PickedChatAttachment({
    required this.fileName,
    required this.type,
    required this.fileSize,
    this.bytes,
    this.localFilePath,
  });

  final String fileName;
  final String type;
  final int fileSize;
  final Uint8List? bytes;
  final String? localFilePath;

  bool get isImage => type == AppConstants.chatMessageImage;
}

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
  Map<String, ChatMessageModel> _messagesById = const {};
  ChatMessageModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_watchMessages());
    });
  }

  Future<void> _watchMessages() async {
    await _messagesSub?.cancel();
    if (!mounted) return;

    final provider = context.read<ChatProvider>();
    final currentUserId = provider.currentUser?.uid ?? '';
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix-freeze',
        hypothesisId: 'H6',
        location: 'lib/views/chat/resident_chat_thread_view.dart:46',
        message: 'Entering chat message watcher',
        data: <String, Object?>{
          'chatId': agentDebugId(widget.initialChat.id),
          'hasCurrentUser': provider.currentUser != null,
          'currentUserId': agentDebugId(currentUserId),
          'participantCount': widget.initialChat.participantIds.length,
        },
      ),
    );
    // #endregion
    _messagesSub = provider.watchMessages(widget.initialChat.id).listen((
      messages,
    ) {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H5',
          location: 'lib/views/chat/resident_chat_thread_view.dart:49',
          message: 'Received chat messages before UI conversion',
          data: <String, Object?>{
            'chatId': agentDebugId(widget.initialChat.id),
            'messageCount': messages.length,
            'attachmentCount': messages
                .where((message) => message.isImage || message.isFile)
                .length,
            'hasEmptyMediaUrl': messages.any(
              (message) =>
                  (message.isImage || message.isFile) &&
                  message.mediaUrl.isEmpty,
            ),
          },
        ),
      );
      // #endregion
      final chatMessages = messages
          .map((message) => message.toChatMessage(currentUserId: currentUserId))
          .toList(growable: false);
      _messagesById = {
        for (final message in messages) message.id: message,
      };
      _chatController.setMessages(chatMessages, animated: false);
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix-freeze',
          hypothesisId: 'H7,H9',
          location: 'lib/views/chat/resident_chat_thread_view.dart:82',
          message: 'Chat messages converted and set on controller',
          data: <String, Object?>{
            'chatId': agentDebugId(widget.initialChat.id),
            'messageCount': messages.length,
            'convertedCount': chatMessages.length,
            'lastMessageType': messages.isEmpty ? 'none' : messages.last.type,
            'lastHasMediaUrl':
                messages.isNotEmpty &&
                (messages.last.isImage || messages.last.isFile) &&
                messages.last.mediaUrl.isNotEmpty,
          },
        ),
      );
      // #endregion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // #region agent log
        unawaited(
          agentDebugLog(
            runId: 'pre-fix-freeze',
            hypothesisId: 'H7',
            location: 'lib/views/chat/resident_chat_thread_view.dart:101',
            message: 'Post-frame reached after setting chat messages',
            data: <String, Object?>{
              'chatId': agentDebugId(widget.initialChat.id),
              'messageCount': chatMessages.length,
              'attachmentCount': messages
                  .where((message) => message.isImage || message.isFile)
                  .length,
            },
          ),
        );
        // #endregion
      });
      final latestChat =
          provider.chatById(widget.initialChat.id) ?? widget.initialChat;
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix-freeze',
          hypothesisId: 'H8',
          location: 'lib/views/chat/resident_chat_thread_view.dart:99',
          message: 'Scheduling markChatRead from message watcher',
          data: <String, Object?>{
            'chatId': agentDebugId(latestChat.id),
            'currentUserId': agentDebugId(currentUserId),
            'unreadForCurrentUser': latestChat.unreadCountFor(currentUserId),
          },
        ),
      );
      // #endregion
      unawaited(
        provider
            .markChatRead(latestChat)
            .then((_) {
              // #region agent log
              unawaited(
                agentDebugLog(
                  runId: 'pre-fix-freeze',
                  hypothesisId: 'H8',
                  location: 'lib/views/chat/resident_chat_thread_view.dart:132',
                  message: 'markChatRead completed from message watcher',
                  data: <String, Object?>{
                    'chatId': agentDebugId(latestChat.id),
                    'currentUserId': agentDebugId(currentUserId),
                  },
                ),
              );
              // #endregion
            })
            .catchError((Object error) {
              // #region agent log
              unawaited(
                agentDebugLog(
                  runId: 'pre-fix-freeze',
                  hypothesisId: 'H8',
                  location: 'lib/views/chat/resident_chat_thread_view.dart:147',
                  message: 'markChatRead failed from message watcher',
                  data: <String, Object?>{
                    'chatId': agentDebugId(latestChat.id),
                    'errorType': error.runtimeType.toString(),
                    'error': error.toString(),
                  },
                ),
              );
              // #endregion
            }),
      );
    });
  }

  Future<void> _refreshMessages() async {
    await _watchMessages();
    await Future<void>.delayed(const Duration(milliseconds: 300));
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
    final replyTo = _replyingTo;
    try {
      await provider.sendTextMessage(
        chat: chat,
        text: text,
        replyTo: replyTo,
      );
      if (replyTo != null && mounted) {
        setState(() => _replyingTo = null);
      }
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
      final fileSize = await image.length();
      final validationError = _validateAttachment(
        fileName: image.name,
        fileSize: fileSize,
        isPhotoPicker: true,
      );
      if (validationError != null) {
        _showAttachmentError(validationError);
        return;
      }

      final bytes = await image.readAsBytes();
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H1,H3',
          location: 'lib/views/chat/resident_chat_thread_view.dart:93',
          message: 'Picked chat photo attachment',
          data: <String, Object?>{
            'byteLength': bytes.length,
            'fileSize': fileSize,
            'nameLength': image.name.length,
            'extension': p.extension(image.name).toLowerCase(),
          },
        ),
      );
      // #endregion
      if (!mounted) return;
      await _previewAndSendAttachment(
        _PickedChatAttachment(
          bytes: bytes,
          fileName: image.name,
          fileSize: fileSize,
          type: AppConstants.chatMessageImage,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(withData: false);
    final file = result?.files.single;
    if (file == null || !mounted) return;

    final validationError = _validateAttachment(
      fileName: file.name,
      fileSize: file.size,
      isPhotoPicker: false,
    );
    if (validationError != null) {
      _showAttachmentError(validationError);
      return;
    }

    final bytes = file.bytes;
    final localFilePath = file.path;
    if (bytes == null && (localFilePath == null || localFilePath.isEmpty)) {
      _showAttachmentError('This file could not be read. Please try another.');
      return;
    }

    final type = _isImageFile(file.name)
        ? AppConstants.chatMessageImage
        : AppConstants.chatMessageFile;
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H1,H3',
        location: 'lib/views/chat/resident_chat_thread_view.dart:119',
        message: 'Picked chat file attachment',
        data: <String, Object?>{
          'byteLength': bytes?.length,
          'fileSize': file.size,
          'hasLocalPath': localFilePath?.isNotEmpty == true,
          'nameLength': file.name.length,
          'extension': p.extension(file.name).toLowerCase(),
        },
      ),
    );
    // #endregion
    await _previewAndSendAttachment(
      _PickedChatAttachment(
        bytes: bytes,
        fileName: file.name,
        fileSize: file.size,
        localFilePath: localFilePath,
        type: type,
      ),
    );
  }

  Future<void> _previewAndSendAttachment(
    _PickedChatAttachment attachment,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaPreviewSheet(attachment: attachment),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ChatProvider>();
    final chat = provider.chatById(widget.initialChat.id) ?? widget.initialChat;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H1,H2,H3,H4',
          location: 'lib/views/chat/resident_chat_thread_view.dart:157',
          message: 'Sending confirmed chat attachment',
          data: <String, Object?>{
            'chatId': agentDebugId(chat.id),
            'byteLength': attachment.bytes?.length,
            'fileSize': attachment.fileSize,
            'hasLocalPath': attachment.localFilePath?.isNotEmpty == true,
            'nameLength': attachment.fileName.length,
            'extension': p.extension(attachment.fileName).toLowerCase(),
            'type': attachment.type,
          },
        ),
      );
      // #endregion
      final replyTo = _replyingTo;
      await provider.sendAttachmentMessage(
        chat: chat,
        bytes: attachment.bytes,
        localFilePath: attachment.localFilePath,
        fileName: attachment.fileName,
        type: attachment.type,
        fileSize: attachment.fileSize,
        replyTo: replyTo,
      );
      if (replyTo != null && mounted) {
        setState(() => _replyingTo = null);
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Attachment not sent.'),
        ),
      );
    }
  }

  String? _validateAttachment({
    required String fileName,
    required int fileSize,
    required bool isPhotoPicker,
  }) {
    final extension = _extensionFor(fileName);
    if (extension.isEmpty) {
      return 'This file has no extension. Please choose another file.';
    }

    final isImage = _kImageExtensions.contains(extension);
    final isVideo = _kVideoExtensions.contains(extension);
    final isDocument = _kDocumentExtensions.contains(extension);
    if (isPhotoPicker && !isImage) {
      return 'Please choose a supported image file.';
    }
    if (!isPhotoPicker && !isImage && !isVideo && !isDocument) {
      return 'Unsupported file type. Use an image, video, PDF, or document.';
    }

    final maxSize = isImage
        ? _kMaxImageBytes
        : isVideo
        ? _kMaxVideoBytes
        : _kMaxFileBytes;
    if (fileSize > maxSize) {
      return 'File is too large. Maximum allowed size is ${_formatBytes(maxSize)}.';
    }
    return null;
  }

  void _showAttachmentError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isImageFile(String fileName) {
    return _kImageExtensions.contains(_extensionFor(fileName));
  }

  String _extensionFor(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    return extension.startsWith('.') ? extension.substring(1) : extension;
  }

  Future<void> _openMessage(chat_core.Message message) async {
    if (message is chat_core.ImageMessage) {
      _openImagePreview(message);
      return;
    }

    if (message is! chat_core.FileMessage) return;
    final messenger = ScaffoldMessenger.of(context);
    final storagePath = _storagePathFor(message);
    if (storagePath.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Attachment file reference is missing.')),
      );
      return;
    }

    _showAttachmentProgress('Downloading ${message.name}...');
    try {
      final localFile = await _downloadAttachment(
        storagePath: storagePath,
        fileName: message.name,
        messageId: message.id,
        expectedSize: message.size,
      );
      if (!mounted) return;
      _hideAttachmentProgress();

      if (_isPdfFile(message.name, message.mimeType)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _PdfAttachmentPreviewScreen(
              filePath: localFile.path,
              fileName: message.name.trim().isEmpty
                  ? 'Attachment.pdf'
                  : message.name.trim(),
            ),
          ),
        );
        return;
      }

      final launched = await launchUrl(Uri.file(localFile.path));
      if (!mounted || launched) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded ${message.name.trim().isEmpty ? 'attachment' : message.name.trim()} locally.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _hideAttachmentProgress();
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not download this attachment.')),
      );
    }
  }

  void _openImagePreview(chat_core.ImageMessage message) {
    if (message.source.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImageAttachmentPreviewScreen(message: message),
      ),
    );
  }

  String _storagePathFor(chat_core.Message message) {
    final value = message.metadata?['storagePath'];
    return value is String ? value.trim() : '';
  }

  bool _isPdfFile(String fileName, String? mimeType) {
    return mimeType?.toLowerCase() == 'application/pdf' ||
        _extensionFor(fileName) == 'pdf';
  }

  Future<File> _downloadAttachment({
    required String storagePath,
    required String fileName,
    required String messageId,
    int? expectedSize,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final attachmentsDir = Directory(p.join(cacheDir.path, 'chat_attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final safeFileName = _safeLocalFileName(fileName);
    final localFile = File(
      p.join(attachmentsDir.path, '${messageId}_$safeFileName'),
    );
    if (await localFile.exists()) {
      final localSize = await localFile.length();
      if (expectedSize == null ||
          expectedSize == 0 ||
          localSize == expectedSize) {
        return localFile;
      }
    }

    await FirebaseStorage.instance.ref(storagePath).writeToFile(localFile);
    return localFile;
  }

  String _safeLocalFileName(String fileName) {
    final baseName = p.basename(fileName.trim()).replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );
    return baseName.isEmpty ? 'attachment' : baseName;
  }

  void _showAttachmentProgress(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AttachmentProgressDialog(message: message),
    );
  }

  void _hideAttachmentProgress() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
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
        SnackBar(
          content: Text(provider.errorMessage ?? 'Unable to delete chat.'),
        ),
      );
    }
  }

  Future<void> _reportChat(ChatModel chat, {ChatMessageModel? message}) async {
    if (message == null) {
      Navigator.of(context).pop();
    }
    final submission = await showChatReportSheet(
      context,
      title: message == null ? 'Report Chat' : 'Report Message',
      subtitle: message == null
          ? 'Send this conversation to admins for review.'
          : 'Send this message to admins for review.',
      highlightedMessage: message,
    );
    if (submission == null || !mounted) return;

    final provider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.reportChat(
        chat: chat,
        category: submission.category,
        note: submission.note,
        reportedMessages: message == null ? const [] : [message],
        reportEntireConversation: message == null,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message == null ? 'Chat reported.' : 'Message reported.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Unable to submit report.'),
        ),
      );
    }
  }

  Future<void> _showMessageActionMenu(
    ChatModel chat,
    String currentUserId,
    chat_core.Message message,
  ) async {
    final model = _messagesById[message.id];
    if (model == null) return;
    final isPinned = chat.pinnedMessage?.messageId == model.id;
    final action = await showChatMessageActionMenu(
      context,
      message: model,
      isPinned: isPinned,
      showReport: model.senderId != currentUserId,
    );
    if (action == null || !mounted) return;

    if (action == ChatMessageAction.reply) {
      setState(() => _replyingTo = model);
    } else if (action == ChatMessageAction.pin) {
      await _togglePin(chat, model, isPinned);
    } else if (action == ChatMessageAction.deleteForYou) {
      await _confirmDeleteMessage(chat, model);
    } else if (action == ChatMessageAction.report) {
      await _reportChat(chat, message: model);
    }
  }

  Future<void> _togglePin(
    ChatModel chat,
    ChatMessageModel? message,
    bool isPinned,
  ) async {
    final provider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (isPinned) {
        await provider.unpinMessage(chat: chat);
      } else if (message != null) {
        await provider.pinMessage(chat: chat, message: message);
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to update pinned message.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteMessage(
    ChatModel chat,
    ChatMessageModel message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete for you?'),
        content: const Text(
          'This message will be removed from your chat view. The other resident will still see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteMessageForUser(chat: chat, messageId: message.id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to delete message.',
          ),
        ),
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
              if (chat.pinnedMessage != null)
                _PinnedMessageBanner(
                  pinned: chat.pinnedMessage!,
                  onUnpin: () => _togglePin(chat, null, true),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: RefreshIndicator(
                    color: _kBrandTeal,
                    onRefresh: _refreshMessages,
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
                      onMessageTap:
                          (
                            context,
                            message, {
                            required index,
                            required details,
                          }) {
                            _openMessage(message);
                          },
                      onMessageLongPress:
                          (
                            context,
                            message, {
                            required index,
                            required details,
                          }) {
                            _showMessageActionMenu(
                              chat,
                              currentUserId,
                              message,
                            );
                          },
                      builders: chat_core.Builders(
                        composerBuilder: (context) {
                          return Composer(
                            topWidget: _replyingTo == null
                                ? null
                                : _ReplyComposerBar(
                                    senderName: chat.participantName(
                                      _replyingTo!.senderId,
                                    ),
                                    preview: _replyingTo!.previewText,
                                    onCancel: () =>
                                        setState(() => _replyingTo = null),
                                  ),
                          );
                        },
                        textMessageBuilder:
                            (
                              context,
                              message,
                              index, {
                              required isSentByMe,
                              groupStatus,
                            }) {
                              return _TextMessageBubble(
                                message: message,
                                isSentByMe: isSentByMe,
                              );
                            },
                        chatAnimatedListBuilder: (context, itemBuilder) {
                          return ChatAnimatedListReversed(
                            itemBuilder: itemBuilder,
                            bottomPadding: 86,
                          );
                        },
                        imageMessageBuilder:
                            (
                              context,
                              message,
                              index, {
                              required isSentByMe,
                              groupStatus,
                            }) {
                              final reply = _replyFromMessageMetadata(
                                message.metadata,
                              );
                              return Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (reply != null)
                                    _ReplyQuoteStrip(
                                      reply: reply,
                                      isSentByMe: isSentByMe,
                                    ),
                                  _SafeImageMessageCard(
                                    message: message,
                                    isSentByMe: isSentByMe,
                                  ),
                                ],
                              );
                            },
                        fileMessageBuilder:
                            (
                              context,
                              message,
                              index, {
                              required isSentByMe,
                              groupStatus,
                            }) {
                              final reply = _replyFromMessageMetadata(
                                message.metadata,
                              );
                              return Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (reply != null)
                                    _ReplyQuoteStrip(
                                      reply: reply,
                                      isSentByMe: isSentByMe,
                                    ),
                                  _SafeFileMessageCard(
                                    name: message.name,
                                    mimeType: message.mimeType,
                                    size: message.size,
                                    isSentByMe: isSentByMe,
                                  ),
                                ],
                              );
                            },
                        emptyChatListBuilder: (context) => const _EmptyThread(),
                      ),
                      theme: chat_core.ChatTheme.fromThemeData(
                        Theme.of(context),
                      ),
                      backgroundColor: context.glassFill(lightAlpha: 0.92),
                    ),
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

ChatMessageReply? _replyFromMessageMetadata(Map<String, Object?>? metadata) {
  if (metadata == null) return null;
  final messageId = metadata['replyToMessageId']?.toString() ?? '';
  if (messageId.isEmpty) return null;
  return ChatMessageReply(
    messageId: messageId,
    senderId: metadata['replyToSenderId']?.toString() ?? '',
    senderName: metadata['replyToSenderName']?.toString() ?? '',
    type: metadata['replyToType']?.toString() ?? AppConstants.chatMessageText,
    text: metadata['replyToText']?.toString() ?? '',
  );
}

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

class _SafeImageMessageCard extends StatelessWidget {
  const _SafeImageMessageCard({
    required this.message,
    required this.isSentByMe,
  });

  final chat_core.ImageMessage message;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: isSentByMe
            ? _kBrandTeal.withValues(alpha: 0.12)
            : context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Image.network(
              message.source,
              fit: BoxFit.cover,
              cacheWidth: 520,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: _kBrandTeal),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: _kBrandTeal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text?.trim().isNotEmpty == true
                        ? message.text!.trim()
                        : 'Photo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (message.size != null)
                  Text(
                    _formatBytes(message.size!),
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeFileMessageCard extends StatelessWidget {
  const _SafeFileMessageCard({
    required this.name,
    required this.mimeType,
    required this.size,
    required this.isSentByMe,
  });

  final String name;
  final String? mimeType;
  final int? size;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isSentByMe
            ? _kBrandTeal.withValues(alpha: 0.12)
            : context.glassFill(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBrandTeal.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForMimeType(mimeType, name), color: _kBrandTeal),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? 'Attachment' : name.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (mimeType?.trim().isNotEmpty == true) mimeType!.trim(),
                    if (size != null) _formatBytes(size!),
                  ].join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new_rounded, color: _kBrandTeal, size: 18),
        ],
      ),
    );
  }

  IconData _iconForMimeType(String? mimeType, String name) {
    final mime = mimeType?.toLowerCase() ?? '';
    final extension = p.extension(name).toLowerCase();
    if (mime.startsWith('video/') ||
        ['.mp4', '.mov', '.webm'].contains(extension)) {
      return Icons.play_circle_outline_rounded;
    }
    if (mime == 'application/pdf' || extension == '.pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

class _ImageAttachmentPreviewScreen extends StatelessWidget {
  const _ImageAttachmentPreviewScreen({required this.message});

  final chat_core.ImageMessage message;

  @override
  Widget build(BuildContext context) {
    final label = message.text?.trim().isNotEmpty == true
        ? message.text!.trim()
        : 'Photo';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            message.source,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfAttachmentPreviewScreen extends StatefulWidget {
  const _PdfAttachmentPreviewScreen({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  State<_PdfAttachmentPreviewScreen> createState() =>
      _PdfAttachmentPreviewScreenState();
}

class _PdfAttachmentPreviewScreenState
    extends State<_PdfAttachmentPreviewScreen> {
  late final PdfControllerPinch _pdfController;
  int _currentPage = 1;
  int? _pagesCount;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesCount = _pagesCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _kBrandTeal,
        foregroundColor: Colors.white,
        actions: [
          if (pagesCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $pagesCount',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        onDocumentLoaded: (document) {
          setState(() => _pagesCount = document.pagesCount);
        },
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        onDocumentError: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this PDF.')),
          );
        },
      ),
    );
  }
}

class _AttachmentProgressDialog extends StatelessWidget {
  const _AttachmentProgressDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
          Text(
            'Send Attachment',
            style: TextStyle(
              color: context.appInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
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
  const _MediaPreviewSheet({required this.attachment});

  final _PickedChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final bytes = attachment.bytes;
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
          if (attachment.isImage && bytes != null)
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
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: _kBrandTeal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatBytes(attachment.fileSize),
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

enum _AttachmentAction { photo, file }
