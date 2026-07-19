// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_service_core.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../chat_service.dart';

abstract class _ChatServiceBase {
  _ChatServiceBase({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection(AppConstants.chatsCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(AppConstants.reportsCollection);

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

  ChatMessageReply? _replyFromMessage({
    required ChatModel chat,
    required ChatMessageModel? message,
  }) {
    if (message == null) return null;
    return ChatMessageReply(
      messageId: message.id,
      senderId: message.senderId,
      senderName: chat.participantName(message.senderId),
      type: message.type,
      text: message.previewText,
    );
  }

  Map<String, String> _replyFields(ChatMessageReply? replyTo) {
    if (replyTo == null) return const {};
    return {
      'replyToMessageId': replyTo.messageId,
      'replyToSenderId': replyTo.senderId,
      'replyToSenderName': replyTo.senderName,
      'replyToType': replyTo.type,
      'replyToText': replyTo.text,
    };
  }

  List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }
}
