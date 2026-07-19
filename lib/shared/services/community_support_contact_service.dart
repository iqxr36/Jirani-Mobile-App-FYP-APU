// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_support_contact_service.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_support_contact.dart';

abstract interface class CommunitySupportContactReader {
  Future<CommunitySupportContact?> fetchForCommunity(String communityId);
}

abstract interface class CommunitySupportContactWriter {
  Future<void> saveForCommunity(CommunitySupportContact contact);
}

/// Community support feature: reads and saves the scoped resident contact.
class CommunitySupportContactService
    implements CommunitySupportContactReader, CommunitySupportContactWriter {
  CommunitySupportContactService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _contacts => _firestore
      .collection(AppConstants.communitySupportContactsCollection);

  @override
  Future<CommunitySupportContact?> fetchForCommunity(String communityId) async {
    final id = communityId.trim();
    if (id.isEmpty) return null;
    final snapshot = await _contacts.doc(id).get();
    final data = snapshot.data();
    return data == null
        ? null
        : CommunitySupportContact.fromMap(data, snapshot.id);
  }

  @override
  Future<void> saveForCommunity(CommunitySupportContact contact) async {
    final id = contact.communityId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'communityId', 'must not be empty');
    }
    await _contacts.doc(id).set(contact.toMap());
  }
}
