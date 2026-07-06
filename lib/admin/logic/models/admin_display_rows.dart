import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';

enum AdminListingType { marketplaceItem, taskService }

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
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.owner,
    required this.ownerId,
    required this.status,
    required this.icon,
    required this.color,
    required this.description,
    required this.communityName,
    required this.createdAt,
    required this.updatedAt,
    this.item,
    this.service,
    this.imageUrls = const <String>[],
    this.priceLabel = '',
    this.depositLabel = '',
    this.conditionLabel = '',
    this.availabilityLabel = '',
  });

  final String id;
  final AdminListingType type;
  final String title;
  final String category;
  final String owner;
  final String ownerId;
  final String status;
  final IconData icon;
  final Color color;
  final String description;
  final String communityName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemModel? item;
  final ServiceModel? service;
  final List<String> imageUrls;
  final String priceLabel;
  final String depositLabel;
  final String conditionLabel;
  final String availabilityLabel;

  bool get isItem => type == AdminListingType.marketplaceItem;
  bool get isService => type == AdminListingType.taskService;
  bool get canRestore =>
      (isItem && item?.status == AppConstants.itemStatusArchived) ||
      (isService && service?.status == AppConstants.serviceStatusArchived);
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
    required this.inboxSubtitle,
  });

  final String title;
  final String priority;
  final String reporter;
  final String reporterEmail;
  final String target;
  final String content;
  final String description;
  final String inboxSubtitle;
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
    id: item.id,
    type: AdminListingType.marketplaceItem,
    title: item.title.isEmpty ? 'Untitled listing' : item.title,
    category: adminStatusLabel(item.category),
    owner: item.ownerName.isEmpty ? item.ownerEmail : item.ownerName,
    ownerId: item.ownerId,
    status: adminStatusLabel(item.status),
    icon: adminCategoryIcon(item.category),
    color: adminStatusColor(item.status),
    description: item.description,
    communityName: item.communityName,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
    item: item,
    imageUrls: item.imageUrls,
    priceLabel: item.hasUsageFee && item.feeAmount != null
        ? 'RM ${item.feeAmount!.toStringAsFixed(2)}'
        : 'Free',
    depositLabel: item.hasDeposit && item.depositAmount != null
        ? 'RM ${item.depositAmount!.toStringAsFixed(2)}'
        : 'No deposit',
    conditionLabel: adminStatusLabel(item.condition),
  );
}

AdminListingRow adminListingRowFromService(ServiceModel service) {
  return AdminListingRow(
    id: service.id,
    type: AdminListingType.taskService,
    title: service.title.isEmpty ? 'Untitled service' : service.title,
    category: 'Task service',
    owner: service.providerName.isEmpty
        ? service.providerEmail
        : service.providerName,
    ownerId: service.providerId,
    status: adminStatusLabel(service.status),
    icon: adminCategoryIcon(service.category),
    color: adminStatusColor(service.status),
    description: service.description,
    communityName: '',
    createdAt: service.createdAt,
    updatedAt: service.updatedAt,
    service: service,
    priceLabel: service.priceType == AppConstants.servicePriceTypeFree
        ? 'Free'
        : service.priceAmount == null
        ? adminStatusLabel(service.priceType)
        : 'RM ${service.priceAmount!.toStringAsFixed(2)}',
    availabilityLabel: service.availability,
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
  final reporter = report.reporterName.isEmpty
      ? report.reporterId
      : report.reporterName;
  final target = report.reportedUserName.isEmpty
      ? report.reportedUserId
      : report.reportedUserName;
  final description = report.description.isEmpty
      ? 'No description provided.'
      : report.description;
  final isMarketplaceDispute = report.relatedBorrowRequestId.trim().isNotEmpty;
  final isChatReport = report.chatId.trim().isNotEmpty;
  final inboxSubtitle = isMarketplaceDispute
      ? '$reporter - $description'
      : report.reporterId == report.reportedUserId ||
            report.title == 'Low Community Trust Score'
      ? description
      : isChatReport && report.title.isNotEmpty
      ? '$reporter • ${report.title}'
      : '$reporter reported $target';
  return AdminReportRow(
    title: report.title.isEmpty ? adminStatusLabel(report.type) : report.title,
    priority: priority,
    reporter: reporter,
    reporterEmail: report.reporterId,
    target: target,
    content: report.itemId.isEmpty
        ? report.relatedBorrowRequestId
        : 'Item ${report.itemId}',
    description: description,
    inboxSubtitle: inboxSubtitle,
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
        deposit: request.amount == null
            ? 'Free'
            : 'RM ${request.amount!.toStringAsFixed(0)}',
        status: adminStatusLabel(request.status),
        color: adminStatusColor(request.status),
        createdAt: request.createdAt,
      );
    }),
  ];

  rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
}
