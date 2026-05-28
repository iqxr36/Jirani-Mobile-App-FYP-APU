import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed community boundary used for resident location verification.
class CommunityModel {
  const CommunityModel({
    required this.communityId,
    required this.name,
    required this.centerLocation,
    required this.radiusInMeters,
    required this.isActive,
    required this.city,
    this.createdAt,
  });

  final String communityId;
  final String name;
  final GeoPoint centerLocation;
  final double radiusInMeters;
  final bool isActive;
  final String city;
  final Timestamp? createdAt;

  factory CommunityModel.fromMap(Map<String, dynamic> map, String id) {
    return CommunityModel(
      communityId: id,
      name: (map['name'] as String?) ?? '',
      centerLocation: map['centerLocation'] as GeoPoint,
      radiusInMeters: (map['radiusInMeters'] as num).toDouble(),
      isActive: (map['isActive'] as bool?) ?? false,
      city: (map['city'] as String?) ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'communityId': communityId,
      'name': name,
      'centerLocation': centerLocation,
      'radiusInMeters': radiusInMeters,
      'isActive': isActive,
      'city': city,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
