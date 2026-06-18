import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/agent_debug_log.dart';
import 'package:jirani/core/utils/chat_access.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection(AppConstants.chatsCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(AppConstants.reportsCollection);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(AppConstants.notificationsCollection);

  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    final currentUserId = currentUser.uid;
    final communityId = currentUser.communityId.trim();
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H3',
        location: 'lib/services/chat_service.dart:34',
        message: 'Starting chat inbox Firestore query',
        data: <String, Object?>{
          'currentUserId': agentDebugId(currentUserId),
          'queryField': 'participantLookup.<uid>',
          'communityId': agentDebugId(communityId),
          'collection': AppConstants.chatsCollection,
        },
      ),
    );
    // #endregion
    return _chats
        .where('participantLookup.$currentUserId', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
              .where(
                (chat) =>
                    chat.communityId == communityId &&
                    !chat.isDeletedFor(currentUserId),
              )
              .toList(growable: false);
          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return chats;
        });
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageModel.fromMap(doc.id, doc.data()))
              .toList(growable: false);
        });
  }

  Future<ChatModel> openOrCreateChat({
    required AppUser currentUser,
    required AppUser neighbor,
  }) async {
    _validateParticipants(currentUser: currentUser, neighbor: neighbor);
    final chatId = ChatModel.chatId(currentUser.uid, neighbor.uid);
    final doc = _chats.doc(chatId);
    final now = FieldValue.serverTimestamp();
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H2,H4',
        location: 'lib/services/chat_service.dart:79',
        message: 'Opening or creating chat',
        data: <String, Object?>{
          'chatId': agentDebugId(chatId),
          'currentUserId': agentDebugId(currentUser.uid),
          'neighborId': agentDebugId(neighbor.uid),
          'currentStatus': currentUser.verificationStatus,
          'neighborStatus': neighbor.verificationStatus,
          'currentRole': currentUser.role,
          'neighborRole': neighbor.role,
          'sameCommunity': currentUser.communityId == neighbor.communityId,
          'currentCommunityId': agentDebugId(currentUser.communityId),
          'neighborCommunityId': agentDebugId(neighbor.communityId),
        },
      ),
    );
    // #endregion

    final baseData = <String, dynamic>{
      'participantIds': <String>[currentUser.uid, neighbor.uid]..sort(),
      'communityId': currentUser.communityId,
      'connectionId': chatId,
      'participantNames': <String, String>{
        currentUser.uid: _displayName(currentUser),
        neighbor.uid: _displayName(neighbor),
      },
      'participantImageUrls': <String, String>{
        currentUser.uid: currentUser.profileImageUrl,
        neighbor.uid: neighbor.profileImageUrl,
      },
      'participantLookup': <String, bool>{
        currentUser.uid: true,
        neighbor.uid: true,
      },
      'updatedAt': now,
    };

    try {
      final snapshot = await doc.get();
      if (snapshot.exists) {
        await doc.update({
          ...baseData,
          'deletedFor': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        // #region agent log
        unawaited(
          agentDebugLog(
            runId: 'post-fix',
            hypothesisId: 'H4',
            location: 'lib/services/chat_service.dart:130',
            message:
                'Chat did not exist; creating chat after allowed missing-doc read',
            data: <String, Object?>{
              'chatId': agentDebugId(chatId),
              'snapshotExists': snapshot.exists,
            },
          ),
        );
        // #endregion
        await doc.set({
          ...baseData,
          'lastMessageText': '',
          'lastMessageType': AppConstants.chatMessageText,
          'lastMessageAt': null,
          'lastSenderId': '',
          'unreadCounts': <String, int>{currentUser.uid: 0, neighbor.uid: 0},
          'deletedFor': <String>[],
          'createdAt': now,
        });
      }
    } catch (error) {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'post-fix',
          hypothesisId: 'H4',
          location: 'lib/services/chat_service.dart:132',
          message: 'openOrCreateChat Firestore open/create failed',
          data: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'error': error.toString(),
          },
        ),
      );
      // #endregion
      rethrow;
    }

    final created = await doc.get();
    return ChatModel.fromMap(created.id, created.data() ?? const {});
  }

  Future<void> sendTextMessage({
    required ChatModel chat,
    required AppUser sender,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    await _sendMessage(
      chat: chat,
      sender: sender,
      type: AppConstants.chatMessageText,
      text: cleanText,
    );
  }

  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    required AppUser sender,
    Uint8List? bytes,
    String? localFilePath,
    required String fileName,
    required String type,
    required int fileSize,
  }) async {
    if (bytes == null && (localFilePath == null || localFilePath.isEmpty)) {
      throw Exception('Attachment file data is missing.');
    }

    final cleanFileName = fileName.trim().isEmpty
        ? 'attachment'
        : p.basename(fileName.trim());
    final messageDoc = _chats
        .doc(chat.id)
        .collection(AppConstants.messagesCollection)
        .doc();
    final extension = p.extension(cleanFileName);
    final storagePath =
        '${AppConstants.storageChatAttachmentsPath}/${chat.id}/${sender.uid}/${messageDoc.id}$extension';
    final mimeType = lookupMimeType(cleanFileName, headerBytes: bytes);
    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: mimeType ?? 'application/octet-stream',
      customMetadata: {
        'chatId': chat.id,
        'senderId': sender.uid,
        'fileName': cleanFileName,
      },
    );

    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H2,H3',
        location: 'lib/services/chat_service.dart:216',
        message: 'Starting chat attachment upload',
        data: <String, Object?>{
          'chatId': agentDebugId(chat.id),
          'senderId': agentDebugId(sender.uid),
          'byteLength': bytes?.length,
          'fileSize': fileSize,
          'hasLocalPath': localFilePath?.isNotEmpty == true,
          'extension': extension.toLowerCase(),
          'mimeType': mimeType ?? 'application/octet-stream',
          'storagePathId': agentDebugId(storagePath),
          'type': type,
        },
      ),
    );
    // #endregion

    try {
      final path = localFilePath;
      if (path != null && path.isNotEmpty) {
        await ref.putFile(File(path), metadata);
      } else {
        await ref.putData(bytes!, metadata);
      }
    } catch (error) {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H2,H3',
          location: 'lib/services/chat_service.dart:241',
          message: 'Chat attachment upload failed',
          data: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'error': error.toString(),
            'byteLength': bytes?.length,
            'fileSize': fileSize,
            'hasLocalPath': localFilePath?.isNotEmpty == true,
            'extension': extension.toLowerCase(),
            'mimeType': mimeType ?? 'application/octet-stream',
          },
        ),
      );
      // #endregion
      rethrow;
    }
    final url = await ref.getDownloadURL();
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H2,H4,H5',
        location: 'lib/services/chat_service.dart:260',
        message: 'Chat attachment upload succeeded',
        data: <String, Object?>{
          'chatId': agentDebugId(chat.id),
          'downloadUrlLength': url.length,
          'storagePathId': agentDebugId(storagePath),
          'type': type,
        },
      ),
    );
    // #endregion

    await _sendMessage(
      chat: chat,
      sender: sender,
      type: type,
      text: type == AppConstants.chatMessageImage ? 'Photo' : cleanFileName,
      mediaUrl: url,
      storagePath: storagePath,
      fileName: cleanFileName,
      mimeType: mimeType ?? '',
      fileSize: fileSize,
      messageId: messageDoc.id,
    );
  }

  Future<void> markChatRead({
    required ChatModel chat,
    required String currentUserId,
  }) async {
    final chatRef = _chats.doc(chat.id);
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H5',
        location: 'lib/services/chat_service.dart:212',
        message: 'Marking chat read',
        data: <String, Object?>{
          'chatId': agentDebugId(chat.id),
          'currentUserId': agentDebugId(currentUserId),
          'currentUserInParticipants': chat.participantIds.contains(
            currentUserId,
          ),
          'participantCount': chat.participantIds.length,
        },
      ),
    );
    // #endregion
    try {
      await chatRef.update({'unreadCounts.$currentUserId': 0});
    } catch (error) {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H5',
          location: 'lib/services/chat_service.dart:231',
          message: 'markChatRead Firestore update failed',
          data: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'error': error.toString(),
          },
        ),
      );
      // #endregion
      rethrow;
    }

    final unreadMessages = await chatRef
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final data = doc.data();
      if (data['senderId'] == currentUserId) continue;
      final readBy = data['readBy'];
      if (readBy is List && readBy.contains(currentUserId)) continue;
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
    await batch.commit();
  }

  Future<void> deleteChatForUser({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _chats.doc(chat.id).update({
      'deletedFor': FieldValue.arrayUnion([currentUserId]),
      'unreadCounts.$currentUserId': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveChatsOutsideCommunity({
    required String uid,
    required String communityId,
  }) async {
    final targetCommunityId = communityId.trim();
    final snapshot = await _chats
        .where('participantLookup.$uid', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      final chat = ChatModel.fromMap(doc.id, doc.data());
      if (chat.communityId.trim() == targetCommunityId ||
          chat.isDeletedFor(uid)) {
        continue;
      }
      batch.update(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([uid]),
        'unreadCounts.$uid': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<void> reportChat({
    required ChatModel chat,
    required AppUser reporter,
    required String reason,
  }) {
    final reportedUserId = chat.otherParticipantId(reporter.uid);
    final now = FieldValue.serverTimestamp();
    return _reports.add({
      'type': AppConstants.reportTypeUserMisconduct,
      'status': AppConstants.reportStatusOpen,
      'reporterId': reporter.uid,
      'reportedUserId': reportedUserId,
      'chatId': chat.id,
      'reason': reason.trim().isEmpty ? 'Chat reported by resident.' : reason,
      'communityId': reporter.communityId,
      'communityName': reporter.communityName,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _sendMessage({
    required ChatModel chat,
    required AppUser sender,
    required String type,
    required String text,
    String mediaUrl = '',
    String storagePath = '',
    String fileName = '',
    String mimeType = '',
    int fileSize = 0,
    String? messageId,
  }) async {
    validateChatAccess(chat: chat, sender: sender);

    final recipientId = chat.otherParticipantId(sender.uid);
    if (recipientId.isEmpty) {
      throw Exception('Unable to find the chat recipient.');
    }

    final chatRef = _chats.doc(chat.id);
    final messageRef = messageId == null
        ? chatRef.collection(AppConstants.messagesCollection).doc()
        : chatRef.collection(AppConstants.messagesCollection).doc(messageId);
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H5',
        location: 'lib/services/chat_service.dart:315',
        message: 'Sending chat message batch',
        data: <String, Object?>{
          'chatId': agentDebugId(chat.id),
          'senderId': agentDebugId(sender.uid),
          'recipientId': agentDebugId(recipientId),
          'senderInParticipants': chat.participantIds.contains(sender.uid),
          'recipientInParticipants': chat.participantIds.contains(recipientId),
          'participantCount': chat.participantIds.length,
          'type': type,
        },
      ),
    );
    // #endregion

    batch.set(messageRef, {
      'chatId': chat.id,
      'senderId': sender.uid,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'createdAt': now,
      'readBy': <String>[sender.uid],
    });

    batch.update(chatRef, {
      'lastMessageText': _previewText(type: type, text: text),
      'lastMessageType': type,
      'lastMessageAt': now,
      'lastSenderId': sender.uid,
      'updatedAt': now,
      'unreadCounts.${sender.uid}': 0,
      'unreadCounts.$recipientId': FieldValue.increment(1),
    });

    try {
      await batch.commit();
    } catch (error) {
      // #region agent log
      unawaited(
        agentDebugLog(
          runId: 'pre-fix',
          hypothesisId: 'H5',
          location: 'lib/services/chat_service.dart:361',
          message: 'sendMessage Firestore batch failed',
          data: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'error': error.toString(),
          },
        ),
      );
      // #endregion
      rethrow;
    }
    await _createNotification(
      chat: chat,
      sender: sender,
      recipientId: recipientId,
      body: _previewText(type: type, text: text),
    );
  }

  Future<void> _createNotification({
    required ChatModel chat,
    required AppUser sender,
    required String recipientId,
    required String body,
  }) {
    return _notifications.add({
      'userId': recipientId,
      'type': 'chatMessage',
      'title': _displayName(sender),
      'body': body,
      'chatId': chat.id,
      'senderId': sender.uid,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _previewText({required String type, required String text}) {
    if (type == AppConstants.chatMessageImage) return 'Photo';
    if (type == AppConstants.chatMessageFile) return 'Attachment';
    return text;
  }

  void _validateParticipants({
    required AppUser currentUser,
    required AppUser neighbor,
  }) {
    if (currentUser.uid == neighbor.uid) {
      throw Exception('You cannot message yourself.');
    }
    if (!currentUser.isVerifiedResident || !neighbor.isVerifiedResident) {
      throw Exception('Only verified residents can use chat.');
    }
    if (currentUser.communityId.isEmpty ||
        currentUser.communityId != neighbor.communityId) {
      throw Exception('Chat is only available inside your community.');
    }
  }

  String _displayName(AppUser user) {
    return user.fullName.trim().isNotEmpty ? user.fullName.trim() : 'Resident';
  }
}
