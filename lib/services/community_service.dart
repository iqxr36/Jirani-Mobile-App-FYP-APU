import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/data/models/community_model.dart';

class CommunityService {
  CommunityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection(AppConstants.communitiesCollection);

  Future<void> addCommunity(CommunityModel community) async {
    try {
      await _communities.doc(community.communityId).set(community.toMap());
    } catch (error) {
      debugPrint('Error adding community: $error');
      rethrow;
    }
  }

  Future<List<CommunityModel>> fetchActiveCommunities() async {
    try {
      final snapshot = await _communities
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => CommunityModel.fromMap(doc.data(), doc.id))
          .toList(growable: false);
    } catch (error) {
      debugPrint('Error fetching active communities: $error');
      rethrow;
    }
  }

  Future<CommunityModel?> fetchCommunity(String communityId) async {
    try {
      final document = await _communities.doc(communityId).get();
      final data = document.data();
      if (data == null) return null;

      return CommunityModel.fromMap(data, document.id);
    } catch (error) {
      debugPrint('Error fetching community: $error');
      rethrow;
    }
  }
}
