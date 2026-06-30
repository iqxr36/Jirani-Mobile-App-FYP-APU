import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/public_resident_profile.dart';

// Public profile data layer: reads safe resident profile documents used by neighbor lists and profiles.
class PublicProfileRepository {
  PublicProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection(AppConstants.publicProfilesCollection);

  // Public profile feature: streams one public resident profile for profile detail screens.
  Stream<PublicResidentProfile?> watchProfile(String uid) {
    return _publicProfiles.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return PublicResidentProfile.fromMap({...data, 'uid': data['uid'] ?? uid});
    });
  }

  // Public profile feature: loads one public resident profile for one-off navigation flows.
  Future<PublicResidentProfile?> getProfile(String uid) async {
    final snapshot = await _publicProfiles.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return PublicResidentProfile.fromMap({...data, 'uid': data['uid'] ?? uid});
  }

  // Neighbor directory feature: streams verified residents in the current user's community.
  Stream<List<AppUser>> watchVerifiedCommunityResidents(AppUser currentUser) {
    return _publicProfiles
        .where('communityId', isEqualTo: currentUser.communityId)
        .where('role', isEqualTo: AppConstants.roleResident)
        .where(
          'verificationStatus',
          isEqualTo: AppConstants.verificationVerified,
        )
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map(
                (doc) => PublicResidentProfile.fromMap({
                  ...doc.data(),
                  'uid': doc.data()['uid'] ?? doc.id,
                }).toNeighborListUser(),
              )
              .where(
                (user) =>
                    user.uid != currentUser.uid &&
                    user.isResident &&
                    user.isVerifiedResident,
              )
              .toList(growable: false);
          users.sort((a, b) => a.fullName.compareTo(b.fullName));
          return users;
        });
  }
}
