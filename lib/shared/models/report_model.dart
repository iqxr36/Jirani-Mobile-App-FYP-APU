import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/shared/models/reported_chat_message_snapshot.dart';

/// Reports DB model: represents reports/{reportId} for chat misconduct, trust score flags, and marketplace deposit disputes.
class ReportModel {
  const ReportModel({
    required this.id,
    required this.type,
    required this.relatedBorrowRequestId,
    required this.itemId,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.title,
    required this.description,
    required this.evidenceImageUrl,
    required this.depositAmount,
    required this.minorDeductionAmount,
    required this.status,
    required this.chatId,
    required this.reportCategory,
    required this.reportedMessages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String relatedBorrowRequestId;
  final String itemId;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final String title;
  final String description;
  final String evidenceImageUrl;
  final double? depositAmount;
  final double? minorDeductionAmount;
  final String status;
  final String chatId;
  final String reportCategory;
  final List<ReportedChatMessageSnapshot> reportedMessages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Reports feature: identifies reports created from chat messages instead of marketplace disputes.
  bool get isChatReport => chatId.trim().isNotEmpty;

  /// Reports DB model: converts Firestore report data into the admin report inbox model.
  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
    final description = _firstNonEmpty([
      data['description'] as String?,
      data['reason'] as String?,
    ]);
    return ReportModel(
      id: id,
      type: (data['type'] as String?) ?? '',
      relatedBorrowRequestId: (data['relatedBorrowRequestId'] as String?) ?? '',
      itemId: (data['itemId'] as String?) ?? '',
      reporterId: (data['reporterId'] as String?) ?? '',
      reporterName: (data['reporterName'] as String?) ?? '',
      reportedUserId: (data['reportedUserId'] as String?) ?? '',
      reportedUserName: (data['reportedUserName'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: description,
      evidenceImageUrl: (data['evidenceImageUrl'] as String?) ?? '',
      depositAmount: _toDouble(data['depositAmount']),
      minorDeductionAmount: _toDouble(data['minorDeductionAmount']),
      status: (data['status'] as String?) ?? '',
      chatId: (data['chatId'] as String?) ?? '',
      reportCategory: (data['reportCategory'] as String?) ?? '',
      reportedMessages: _parseReportedMessages(data['reportedMessages']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Reports DB model: supports both description and legacy reason fields.
  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  /// Chat reports: converts stored reported-message snapshots for admin evidence review.
  static List<ReportedChatMessageSnapshot> _parseReportedMessages(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (entry) => ReportedChatMessageSnapshot.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
