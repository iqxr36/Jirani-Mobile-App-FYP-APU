import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';

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
  int get totalUnreadCount {
    final uid = _currentUser?.uid;
    if (uid == null) return 0;
    return _chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadCountFor(uid),
    );
  }

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

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    final userId = _currentUser?.uid ?? '';
    return _repository.watchMessages(chatId, userId);
  }

  ChatModel? chatById(String chatId) {
    for (final chat in _chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }

  Future<ChatModel> openOrCreateChat(AppUser neighbor) async {
    final currentUser = _requireCurrentUser();
    return _runAction(
      () => _repository.openOrCreateChat(
        currentUser: currentUser,
        neighbor: neighbor,
      ),
    );
  }

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

  Future<void> markChatRead(ChatModel chat) async {
    final user = _requireCurrentUser();
    await _repository.markChatRead(chat: chat, currentUserId: user.uid);
  }

  Future<void> deleteChatForCurrentUser(ChatModel chat) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.deleteChatForUser(chat: chat, currentUserId: user.uid),
    );
  }

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

  Future<void> pinMessage({
    required ChatModel chat,
    required ChatMessageModel message,
  }) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.pinMessage(chat: chat, user: user, message: message),
    );
  }

  Future<void> unpinMessage({required ChatModel chat}) async {
    final user = _requireCurrentUser();
    await _runAction(
      () => _repository.unpinMessage(chat: chat, user: user),
    );
  }

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  AppUser _requireCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('You must be signed in to use chat.');
    }
    return user;
  }

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
