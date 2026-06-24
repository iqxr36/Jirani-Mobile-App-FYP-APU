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
