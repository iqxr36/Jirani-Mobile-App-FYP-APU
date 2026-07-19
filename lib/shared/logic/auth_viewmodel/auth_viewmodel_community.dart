// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_viewmodel_community.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../auth_viewmodel.dart';

mixin _AuthViewModelCommunityMixin on _AuthViewModelBase {
  /// Community/geofence feature: changes the resident community and resets verification, connections, chats, and location gate if needed.
  Future<void> updateSelectedCommunity({
    required String communityId,
    required String communityName,
  }) async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to select a community.');
    }

    final nextCommunityId = communityId.trim();
    final nextCommunityName = communityName.trim();
    final currentUser = _currentUser;
    final communityChanged = isChangingSavedCommunity(
      user: currentUser,
      nextCommunity: CommunityModel(
        communityId: nextCommunityId,
        name: nextCommunityName,
        centerLocation: const GeoPoint(0, 0),
        radiusInMeters: 1,
        isActive: true,
        city: '',
      ),
    );
    final fields = <String, dynamic>{
      'communityId': nextCommunityId,
      'communityName': nextCommunityName,
    };

    if (communityChanged) {
      await _verificationRepository.cancelActiveVerificationRequestIfAny();
      await _connectionRepository.removeConnectionsOutsideCommunity(
        uid: uid,
        communityId: nextCommunityId,
      );
      await _chatRepository.archiveChatsOutsideCommunity(
        uid: uid,
        communityId: nextCommunityId,
      );
      fields.addAll({
        'verificationStatus': AppConstants.verificationPending,
        'locationVerified': false,
        'locationVerificationStatus': AppConstants.verificationPending,
        'locationVerifiedCommunityName': '',
      });
    }

    await _userRepository.updateUserFields(uid: uid, fields: fields);
    _currentUser = _currentUser?.copyWith(
      communityId: nextCommunityId,
      communityName: nextCommunityName,
      verificationStatus: communityChanged
          ? AppConstants.verificationPending
          : null,
      locationVerified: communityChanged ? false : null,
    );
    notifyListeners();
  }

  /// Geofence feature: marks the resident as inside their selected community after a successful boundary check.
  Future<void> markLocationVerified() async {
    final uid = _firebaseUser?.uid ?? _currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to verify your location.');
    }

    await _userRepository.updateUserFields(
      uid: uid,
      fields: {
        'locationVerified': true,
        'locationVerificationStatus': 'passed',
        'locationVerifiedCommunityName':
            _currentUser?.communityName.trim() ?? '',
      },
    );
    _currentUser = _currentUser?.copyWith(locationVerified: true);
    _showAccountCreatedScreen = false;
    notifyListeners();
  }
}
