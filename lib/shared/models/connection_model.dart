import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Connections feature constants: mirrors Firestore connection status values used in connection requests.
class ConnectionStatus {
  const ConnectionStatus._();

  static const String pending = AppConstants.connectionPending;
  static const String accepted = AppConstants.connectionAccepted;
  static const String declined = AppConstants.connectionDeclined;
}

/// Connections DB model: represents connections/{connectionId} between two residents in the same community.
class ConnectionModel {
  const ConnectionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.participants,
    required this.communityId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final List<String> participants;
  final String communityId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == ConnectionStatus.pending;
  bool get isAccepted => status == ConnectionStatus.accepted;
  bool get isDeclined => status == ConnectionStatus.declined;

  /// Connections feature: returns the other participant id for neighbor list and chat entry points.
  String otherUserId(String currentUserId) {
    if (currentUserId == fromUserId) return toUserId;
    return fromUserId;
  }

  /// Connections feature: creates an updated connection object while preserving unchanged fields.
  ConnectionModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    List<String>? participants,
    String? communityId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      participants: participants ?? this.participants,
      communityId: communityId ?? this.communityId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Connections DB model: serializes a connection request or accepted connection into Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'participants': participants,
      'communityId': communityId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Connections DB model: converts Firestore connection data into a ConnectionModel.
  factory ConnectionModel.fromMap(String id, Map<String, dynamic> data) {
    return ConnectionModel(
      id: id,
      fromUserId: (data['fromUserId'] as String?) ?? '',
      toUserId: (data['toUserId'] as String?) ?? '',
      participants: _toStringList(data['participants']),
      communityId: (data['communityId'] as String?) ?? '',
      status: (data['status'] as String?) ?? ConnectionStatus.pending,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Connections feature: creates deterministic connection ids so duplicate requests cannot be created.
  static String connectionId(String firstUserId, String secondUserId) {
    final ids = <String>[firstUserId, secondUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
