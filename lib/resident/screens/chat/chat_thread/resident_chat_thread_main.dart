part of '../resident_chat_thread_view.dart';

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

