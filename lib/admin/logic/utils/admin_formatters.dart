import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/core/constants/app_constants.dart';

BoxDecoration adminSurfaceDecoration() {
  return BoxDecoration(
    color: AdminColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AdminColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String adminFormatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String adminDocumentTypeLabel(String value) {
  return switch (value) {
    AppConstants.documentTypeUtilityBill => 'Utility bill',
    AppConstants.documentTypeTenancyAgreement => 'Tenancy agreement',
    AppConstants.documentTypeAccessCard => 'Access card',
    AppConstants.documentTypeOtherProof => 'Other proof',
    _ => value.trim().isEmpty ? 'Residency document' : value,
  };
}

String adminOcrFieldLabel(String value) {
  return switch (value) {
    'type' => 'Document Type',
    'tenantName' => 'Tenant Name',
    'landlordName' => 'Landlord Name',
    'propertyAddress' => 'Property Address',
    'unitNumber' => 'Unit Number',
    'agreementDate' => 'Agreement Date',
    'billType' => 'Bill Type',
    'amount' => 'Amount',
    'billDate' => 'Bill Date',
    'accountNumber' => 'Account Number',
    'utilityProvider' => 'Utility Provider',
    'tenant_name' => 'Tenant Name',
    'property_address' => 'Property Address',
    'bill_type' => 'Bill Type',
    'utility_provider' => 'Utility Provider',
    'billHolderName' => 'Bill Holder Name',
    'dueDate' => 'Due Date',
    'serviceAddress' => 'Service Address',
    'totalAmount' => 'Total Amount',
    'utilityType' => 'Utility Type',
    'account_number' => 'Account Number',
    'bill_date' => 'Bill Date',
    'bill_holder_name' => 'Bill Holder Name',
    'due_date' => 'Due Date',
    'service_address' => 'Service Address',
    'total_amount' => 'Total Amount',
    'utility_issuer_or_provider' => 'Utility Provider',
    'utility_type' => 'Utility Type',
    'residentName' => 'Resident Name',
    'resident_name' => 'Resident Name',
    'issuer' => 'Issuer',
    'documentDate' => 'Document Date',
    'document_date' => 'Document Date',
    'cardNumber' => 'Card Number',
    'card_number' => 'Card Number',
    'summary' => 'Summary',
    'fullText' => 'Full OCR Text',
    _ => value,
  };
}

String adminStatusLabel(String value) {
  if (value.trim().isEmpty) return 'Unknown';
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

IconData adminCategoryIcon(String category) {
  return switch (category) {
    AppConstants.itemCategoryTools => Icons.handyman_rounded,
    AppConstants.itemCategoryKitchen => Icons.blender_rounded,
    AppConstants.itemCategoryElectronics => Icons.devices_rounded,
    AppConstants.itemCategoryCleaning => Icons.cleaning_services_rounded,
    AppConstants.itemCategoryStudy => Icons.menu_book_rounded,
    AppConstants.serviceCategoryHomeCleaningUpkeep =>
      Icons.cleaning_services_rounded,
    AppConstants.serviceCategoryRepairsMaintenance => Icons.build_rounded,
    AppConstants.serviceCategoryAssemblyLabor => Icons.handyman_rounded,
    AppConstants.serviceCategoryTutoringEducation => Icons.school_rounded,
    AppConstants.serviceCategoryAssistanceErrands =>
      Icons.volunteer_activism_rounded,
    AppConstants.serviceCategoryItTechSetup => Icons.router_rounded,
    AppConstants.serviceCategoryHomeCookingMealPrep => Icons.restaurant_rounded,
    AppConstants.serviceCategoryCreativeDigitalTasks =>
      Icons.design_services_rounded,
    _ => Icons.inventory_2_rounded,
  };
}

Color adminStatusColor(String status) {
  return switch (status) {
    AppConstants.itemStatusAvailable ||
    AppConstants.serviceStatusActive ||
    AppConstants.reportStatusResolved ||
    AppConstants.borrowStatusCompleted ||
    AppConstants.serviceRequestStatusCompleted => AdminColors.success,
    AppConstants.reportStatusOpen ||
    AppConstants.reportStatusUnderReview ||
    AppConstants.borrowStatusPending ||
    AppConstants.serviceRequestStatusPending => AdminColors.warning,
    AppConstants.itemStatusArchived ||
    AppConstants.reportStatusDismissed ||
    AppConstants.borrowStatusRejected ||
    AppConstants.serviceRequestStatusRejected => AdminColors.accent,
    _ => AdminColors.primary,
  };
}

String adminShortRecordId(String prefix, String id) {
  if (id.isEmpty) return '$prefix-NEW';
  final compact = id.length > 6 ? id.substring(0, 6) : id;
  return '$prefix-${compact.toUpperCase()}';
}
