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
    final centerLocation = map['centerLocation'];
    if (centerLocation is! GeoPoint) {
      throw FormatException('Community $id is missing a GeoPoint boundary.');
    }

    final radius = map['radiusInMeters'];
    final parsedRadius = radius is num
        ? radius.toDouble()
        : double.tryParse(radius?.toString() ?? '');
    if (parsedRadius == null) {
      throw FormatException('Community $id is missing a numeric radius.');
    }

    return CommunityModel(
      communityId: id,
      name: (map['name'] as String?) ?? '',
      centerLocation: centerLocation,
      radiusInMeters: parsedRadius,
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
