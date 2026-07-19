// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_support_contact.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';

/// Community support feature: the official resident-facing administrator contact.
class CommunitySupportContact {
  const CommunitySupportContact({
    required this.communityId,
    required this.contactName,
    required this.email,
    required this.phoneNumber,
    required this.updatedBy,
    this.updatedAt,
  });

  final String communityId;
  final String contactName;
  final String email;
  final String phoneNumber;
  final String updatedBy;
  final Timestamp? updatedAt;

  factory CommunitySupportContact.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return CommunitySupportContact(
      communityId: documentId.trim(),
      contactName: (map['contactName'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
      updatedBy: (map['updatedBy'] as String? ?? '').trim(),
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'communityId': communityId.trim(),
      'contactName': contactName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'updatedBy': updatedBy.trim(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
