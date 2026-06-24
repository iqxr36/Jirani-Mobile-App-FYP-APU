import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_model.dart';

abstract class CommunityReader {
  Future<List<CommunityModel>> fetchActiveCommunities();
}

class CommunityService implements CommunityReader {
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

  @override
  Future<List<CommunityModel>> fetchActiveCommunities() async {
    try {
      final snapshot = await _communities.get();

      final communities = <CommunityModel>[];
      for (final doc in snapshot.docs) {
        try {
          final community = CommunityModel.fromMap(doc.data(), doc.id);
          if (community.isActive) {
            communities.add(community);
          }
        } catch (error) {
          debugPrint('Skipping malformed community ${doc.id}: $error');
        }
      }
      return communities;
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

      final community = CommunityModel.fromMap(data, document.id);
      return community.isActive ? community : null;
    } catch (error) {
      debugPrint('Error fetching community: $error');
      rethrow;
    }
  }
}
