import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:jirani/data/repositories/chat_repository.dart';
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
    return _chats.fold<int>(0, (total, chat) => total + chat.unreadCountFor(uid));
  }

  void watchForUser(AppUser? user) {
    if (user?.uid == _currentUser?.uid) return;
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

    _chatsSub = _repository.watchChats(user.uid).listen(
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
    return _repository.watchMessages(chatId);
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
  }) async {
    final sender = _requireCurrentUser();
    await _runAction(
      () => _repository.sendTextMessage(chat: chat, sender: sender, text: text),
    );
  }

  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) async {
    final sender = _requireCurrentUser();
    await _runAction(
      () => _repository.sendAttachmentMessage(
        chat: chat,
        sender: sender,
        bytes: bytes,
        fileName: fileName,
        type: type,
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
      () => _repository.deleteChatForUser(
        chat: chat,
        currentUserId: user.uid,
      ),
    );
  }

  Future<void> reportChat({
    required ChatModel chat,
    required String reason,
  }) async {
    final reporter = _requireCurrentUser();
    await _runAction(
      () => _repository.reportChat(
        chat: chat,
        reporter: reporter,
        reason: reason,
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
