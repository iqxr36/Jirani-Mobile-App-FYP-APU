import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';

/// Returns true when the user already has a saved community and is selecting
/// a different one.
bool isChangingSavedCommunity({
  required AppUser? user,
  required CommunityModel nextCommunity,
}) {
  if (user == null) return false;

  final currentCommunityId = user.communityId.trim();
  final currentCommunityName = user.communityName.trim();
  final nextCommunityId = nextCommunity.communityId.trim();
  final nextCommunityName = nextCommunity.name.trim();
  if (currentCommunityId.isEmpty && currentCommunityName.isEmpty) {
    return false;
  }
  if (currentCommunityId.isNotEmpty && nextCommunityId.isNotEmpty) {
    return currentCommunityId != nextCommunityId;
  }
  return currentCommunityName != nextCommunityName;
}

/// Returns true when the user should see the community-change warning dialog.
bool needsCommunityChangeWarning({
  required AppUser? user,
  required CommunityModel nextCommunity,
}) {
  return isChangingSavedCommunity(user: user, nextCommunity: nextCommunity);
}
