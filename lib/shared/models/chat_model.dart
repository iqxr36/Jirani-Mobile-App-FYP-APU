import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/pinned_chat_message.dart';

class ChatModel {
  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.communityId,
    required this.connectionId,
    required this.participantNames,
    required this.participantImageUrls,
    required this.lastMessageText,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.unreadCounts,
    required this.deletedFor,
    required this.createdAt,
    required this.updatedAt,
    this.pinnedMessage,
    this.pinnedBy = '',
  });

  final String id;
  final List<String> participantIds;
  final String communityId;
  final String connectionId;
  final Map<String, String> participantNames;
  final Map<String, String> participantImageUrls;
  final String lastMessageText;
  final String lastMessageType;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCounts;
  final List<String> deletedFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PinnedChatMessage? pinnedMessage;
  final String pinnedBy;

  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String participantName(String userId) {
    return participantNames[userId]?.trim().isNotEmpty == true
        ? participantNames[userId]!.trim()
        : 'Resident';
  }

  String participantImageUrl(String userId) {
    return participantImageUrls[userId] ?? '';
  }

  int unreadCountFor(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool isDeletedFor(String userId) => deletedFor.contains(userId);

  factory ChatModel.fromMap(String id, Map<String, dynamic> data) {
    final pinnedRaw = data['pinnedMessage'];
    final pinnedMessage = pinnedRaw is Map
        ? PinnedChatMessage.fromMap(Map<String, dynamic>.from(pinnedRaw))
        : null;
    return ChatModel(
      id: id,
      participantIds: _toStringList(data['participantIds']),
      communityId: (data['communityId'] as String?) ?? '',
      connectionId: (data['connectionId'] as String?) ?? id,
      participantNames: _toStringMap(data['participantNames']),
      participantImageUrls: _toStringMap(data['participantImageUrls']),
      lastMessageText: (data['lastMessageText'] as String?) ?? '',
      lastMessageType:
          (data['lastMessageType'] as String?) ?? AppConstants.chatMessageText,
      lastMessageAt: _parseNullableDate(data['lastMessageAt']),
      lastSenderId: (data['lastSenderId'] as String?) ?? '',
      unreadCounts: _toIntMap(data['unreadCounts']),
      deletedFor: _toStringList(data['deletedFor']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      pinnedMessage:
          pinnedMessage != null && pinnedMessage.messageId.trim().isNotEmpty
          ? pinnedMessage
          : null,
      pinnedBy: (data['pinnedBy'] as String?) ?? '',
    );
  }

  static String chatId(String firstUserId, String secondUserId) {
    final ids = <String>[firstUserId, secondUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static Map<String, String> _toStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
      );
    }
    return const <String, String>{};
  }

  static Map<String, int> _toIntMap(dynamic value) {
    if (value is Map) {
      return value.map((key, entry) {
        final count = entry is num ? entry.toInt() : int.tryParse('$entry') ?? 0;
        return MapEntry(key.toString(), count);
      });
    }
    return const <String, int>{};
  }

  static DateTime _parseDate(dynamic value) {
    return _parseNullableDate(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
