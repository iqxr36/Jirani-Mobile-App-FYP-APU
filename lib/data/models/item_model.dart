import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class ItemModel {
  const ItemModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhotoUrl,
    required this.ownerVerified,
    required this.ownerReputationScore,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.lendingType,
    required this.feeAmount,
    required this.depositAmount,
    required this.status,
    required this.communityId,
    required this.communityName,
    required this.pickupInstructions,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhotoUrl;
  final bool ownerVerified;
  final double ownerReputationScore;
  final String title;
  final String description;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final String lendingType;
  final double? feeAmount;
  final double? depositAmount;
  final String status;
  final String communityId;
  final String communityName;
  final String pickupInstructions;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhotoUrl,
    bool? ownerVerified,
    double? ownerReputationScore,
    String? title,
    String? description,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? lendingType,
    double? feeAmount,
    double? depositAmount,
    String? status,
    String? communityId,
    String? communityName,
    String? pickupInstructions,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      ownerVerified: ownerVerified ?? this.ownerVerified,
      ownerReputationScore: ownerReputationScore ?? this.ownerReputationScore,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      lendingType: lendingType ?? this.lendingType,
      feeAmount: feeAmount ?? this.feeAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ItemModel.fromMap(String id, Map<String, dynamic> data) {
    return ItemModel(
      id: id,
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      ownerEmail: (data['ownerEmail'] as String?) ?? '',
      ownerPhotoUrl: (data['ownerPhotoUrl'] as String?) ?? '',
      ownerVerified: data['ownerVerified'] as bool? ?? false,
      ownerReputationScore: _toDouble(data['ownerReputationScore']) ?? 0,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? AppConstants.itemCategoryOther,
      condition: (data['condition'] as String?) ?? AppConstants.itemConditionUsed,
      imageUrls: _toStringList(data['imageUrls']),
      lendingType: (data['lendingType'] as String?) ?? AppConstants.lendingTypeFree,
      feeAmount: _toDouble(data['feeAmount']),
      depositAmount: _toDouble(data['depositAmount']),
      status: (data['status'] as String?) ?? AppConstants.itemStatusAvailable,
      communityId: (data['communityId'] as String?) ?? '',
      communityName: (data['communityName'] as String?) ?? '',
      pickupInstructions: (data['pickupInstructions'] as String?) ?? '',
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhotoUrl': ownerPhotoUrl,
      'ownerVerified': ownerVerified,
      'ownerReputationScore': ownerReputationScore,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'lendingType': lendingType,
      'feeAmount': feeAmount,
      'depositAmount': depositAmount,
      'status': status,
      'communityId': communityId,
      'communityName': communityName,
      'pickupInstructions': pickupInstructions,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
