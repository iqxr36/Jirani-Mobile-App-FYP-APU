import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';

class AdminActivityRow {
  const AdminActivityRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
}

class AdminListingRow {
  const AdminListingRow({
    required this.title,
    required this.category,
    required this.owner,
    required this.status,
    required this.icon,
    required this.color,
  });

  final String title;
  final String category;
  final String owner;
  final String status;
  final IconData icon;
  final Color color;
}

class AdminReportRow {
  const AdminReportRow({
    required this.title,
    required this.priority,
    required this.reporter,
    required this.reporterEmail,
    required this.target,
    required this.content,
    required this.description,
  });

  final String title;
  final String priority;
  final String reporter;
  final String reporterEmail;
  final String target;
  final String content;
  final String description;
}

class AdminTransactionRow {
  const AdminTransactionRow({
    required this.id,
    required this.date,
    required this.type,
    required this.provider,
    required this.requester,
    required this.deposit,
    required this.status,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String date;
  final String type;
  final String provider;
  final String requester;
  final String deposit;
  final String status;
  final Color color;
  final DateTime createdAt;
}

AdminListingRow adminListingRowFromItem(ItemModel item) {
  return AdminListingRow(
    title: item.title.isEmpty ? 'Untitled listing' : item.title,
    category: adminStatusLabel(item.category),
    owner: item.ownerName.isEmpty ? item.ownerEmail : item.ownerName,
    status: adminStatusLabel(item.status),
    icon: adminCategoryIcon(item.category),
    color: adminStatusColor(item.status),
  );
}

AdminListingRow adminListingRowFromService(ServiceModel service) {
  return AdminListingRow(
    title: service.title.isEmpty ? 'Untitled service' : service.title,
    category: 'Task service',
    owner: service.providerName.isEmpty
        ? service.providerEmail
        : service.providerName,
    status: adminStatusLabel(service.status),
    icon: adminCategoryIcon(service.category),
    color: adminStatusColor(service.status),
  );
}

AdminReportRow adminReportRowFromReport(ReportModel report) {
  final priority = switch (report.type) {
    AppConstants.reportTypeDamagedItem ||
    AppConstants.reportTypeLostItem ||
    AppConstants.reportTypeDepositDispute =>
      'High',
    AppConstants.reportTypeUserMisconduct => 'Med',
    _ => 'Low',
  };
  return AdminReportRow(
    title: report.title.isEmpty ? adminStatusLabel(report.type) : report.title,
    priority: priority,
    reporter: report.reporterName.isEmpty
        ? report.reporterId
        : report.reporterName,
    reporterEmail: report.reporterId,
    target: report.reportedUserName.isEmpty
        ? report.reportedUserId
        : report.reportedUserName,
    content: report.itemId.isEmpty
        ? report.relatedBorrowRequestId
        : 'Item ${report.itemId}',
    description: report.description.isEmpty
        ? 'No description provided.'
        : report.description,
  );
}

List<AdminTransactionRow> adminTransactionRowsFromRequests(
  List<BorrowRequest> borrowRequests,
  List<ServiceRequestModel> serviceRequests,
) {
  final rows = <AdminTransactionRow>[
    ...borrowRequests.map((request) {
      final depositAmount = request.hasDeposit ? request.depositAmount ?? 0 : 0;
      return AdminTransactionRow(
        id: adminShortRecordId('BR', request.id),
        date: adminFormatDate(request.createdAt),
        type: 'Borrow',
        provider: request.ownerName.isEmpty ? 'Owner' : request.ownerName,
        requester: request.borrowerName.isEmpty
            ? 'Requester'
            : request.borrowerName,
        deposit: 'RM ${depositAmount.toStringAsFixed(0)}',
        status: adminStatusLabel(request.status),
        color: adminStatusColor(request.status),
        createdAt: request.createdAt,
      );
    }),
    ...serviceRequests.map((request) {
      return AdminTransactionRow(
        id: adminShortRecordId('SR', request.id),
        date: adminFormatDate(request.createdAt),
        type: 'Task Service',
        provider: request.providerName.isEmpty
            ? 'Provider'
            : request.providerName,
        requester: request.requesterName.isEmpty
            ? 'Requester'
            : request.requesterName,
        deposit: 'RM 0',
        status: adminStatusLabel(request.status),
        color: adminStatusColor(request.status),
        createdAt: request.createdAt,
      );
    }),
  ];

  rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
}
