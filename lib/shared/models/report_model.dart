import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
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
      description: (data['description'] as String?) ?? '',
      evidenceImageUrl: (data['evidenceImageUrl'] as String?) ?? '',
      depositAmount: _toDouble(data['depositAmount']),
      minorDeductionAmount: _toDouble(data['minorDeductionAmount']),
      status: (data['status'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
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
