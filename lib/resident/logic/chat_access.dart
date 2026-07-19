// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_access.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_model.dart';

void validateChatAccess({
  required ChatModel chat,
  required AppUser sender,
}) {
  if (chat.isDeletedFor(sender.uid)) {
    throw Exception('This conversation is no longer available.');
  }
  if (!sender.isVerifiedResident) {
    throw Exception('Only verified residents can use chat.');
  }
  final chatCommunityId = chat.communityId.trim();
  final senderCommunityId = sender.communityId.trim();
  if (chatCommunityId.isEmpty ||
      senderCommunityId.isEmpty ||
      chatCommunityId != senderCommunityId) {
    throw Exception('Chat is only available inside your community.');
  }
}
