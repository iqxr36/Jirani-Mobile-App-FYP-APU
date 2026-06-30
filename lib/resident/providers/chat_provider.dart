import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';

// Chat feature: keeps resident chat inbox/message actions in Provider state and calls ChatRepository for Firestore work.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  final ChatRepository _repository;

  StreamSubscription<List<ChatModel>>? _chatsSub;
  AppUser? _currentUser;
  List<ChatModel> _chats = const <ChatModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  // Chat feature: totals unread messages across the resident's visible conversations for badges.
  int get totalUnreadCount {
    final uid = _currentUser?.uid;
    if (uid == null) return 0;
    return _chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadCountFor(uid),
    );
  }

  // Chat feature: starts or resets the chat inbox stream when the signed-in resident/community changes.
  void watchForUser(AppUser? user, {bool force = false}) {
    final sameUser = user?.uid == _currentUser?.uid;
    final sameCommunity = user?.communityId == _currentUser?.communityId;
    if (!force && sameUser && sameCommunity) return;
    _currentUser = user;
    _chatsSub?.cancel();

    if (user == null) {
      _chats = const <ChatModel>[];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _chatsSub = _repository
        .watchChats(user)
        .listen(
          (chats) {
            _chats = chats;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Chat feature: streams messages for the opened thread while hiding messages deleted for this user.
  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    final userId = _currentUser?.uid ?? '';
    return _repository.watchMessages(chatId, userId);
  }

  // Chat feature: finds a chat already loaded in the inbox for notification routing and detail reuse.
  ChatModel? chatById(String chatId) {
    for (final chat in _chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }

  // Chat feature: creates or reopens the deterministic one-to-one chat with a neighbor.
  Future<ChatModel> openOrCreateChat(AppUser neighbor) async {
    final currentUser = _requireCurrentUser();
    return _runAction(
      () => _repository.openOrCreateChat(
        currentUser: currentUser,
        neighbor: neighbor,
      ),
    );
  }

  // Chat feature: sends a text message and optional reply reference to the active conversation.
  Future<void> sendTextMessage({
    required ChatModel chat,
    required String text,
    ChatMessageModel? replyTo,
  }) async {
    final sender = _requireCurrentUser();
    await _runAction(
      () => _repository.sendTextMessage(
        chat: chat,
        sender: sender,
        text: text,
        replyTo: replyTo,
      ),
    );
  }

  // Chat feature: uploads and sends an image/document attachment through the active conversation.
  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    Uint8List? bytes,
    String? localFilePath,
    required String fileName,
    required String type,
    required int fileSize,
    ChatMessageModel? replyTo,
  }) async {
    final sender = _requireCurrentUser();
    await _runAction(
      () => _repository.sendAttachmentMessage(
        chat: chat,
        sender: sender,
        bytes: bytes,
        localFilePath: localFilePath,
        fileName: fileName,
        type: type,
        fileSize: fileSize,
        replyTo: replyTo,
      ),
    );
  }

  // Chat feature: marks the opened conversation as read for the current resident.
  Future<void> markChatRead(ChatModel chat) async {
    final user = _requireCurrentUser();
    await _repository.markChatRead(chat: chat, currentUserId: user.uid);
  }

  // Chat feature: hides a conversation only for the current resident without deleting it for the other participant.
  Future<void> deleteChatForCurrentUser(ChatModel chat) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.deleteChatForUser(chat: chat, currentUserId: user.uid),
    );
  }

  // Report feature: creates an admin report from a whole chat or selected chat messages.
  Future<void> reportChat({
    required ChatModel chat,
    required String category,
    required String note,
    List<ChatMessageModel> reportedMessages = const [],
    bool reportEntireConversation = false,
  }) async {
    final reporter = _requireCurrentUser();
    await _runAction(
      () => _repository.reportChat(
        chat: chat,
        reporter: reporter,
        category: category,
        note: note,
        reportedMessages: reportedMessages,
        reportEntireConversation: reportEntireConversation,
      ),
    );
  }

  // Chat feature: pins one message at the top of the conversation for both participants.
  Future<void> pinMessage({
    required ChatModel chat,
    required ChatMessageModel message,
  }) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.pinMessage(chat: chat, user: user, message: message),
    );
  }

  // Chat feature: removes the pinned message marker from the conversation.
  Future<void> unpinMessage({required ChatModel chat}) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.unpinMessage(chat: chat, user: user),
    );
  }

  // Chat feature: hides one message for the current resident while preserving audit history.
  Future<void> deleteMessageForUser({
    required ChatModel chat,
    required String messageId,
  }) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.deleteMessageForUser(
        chat: chat,
        messageId: messageId,
        userId: user.uid,
      ),
    );
  }

  // Chat UI state: clears the latest provider error after a SnackBar or inline error displays it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Chat feature: guards chat actions so anonymous/null user state cannot write messages.
  AppUser _requireCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('You must be signed in to use chat.');
    }
    return user;
  }

  // Chat UI state: wraps chat writes with submitting/error flags for buttons and forms.
  Future<T> _runAction<T>(Future<T> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    super.dispose();
  }
}
