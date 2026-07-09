part of '../public_resident_profile_view.dart';

String _reviewMetric(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return '-';
  final total = reviews.fold<int>(0, (total, review) => total + review.rating);
  return (total / reviews.length).toStringAsFixed(1);
}

String _money(double? value) {
  final amount = value ?? 0;
  if (amount == 0) return 'RM 0';
  return amount % 1 == 0
      ? 'RM ${amount.toStringAsFixed(0)}'
      : 'RM ${amount.toStringAsFixed(2)}';
}

String _categoryLabel(String value) {
  return switch (value) {
    AppConstants.itemCategoryTools => 'Tools',
    AppConstants.itemCategoryKitchen => 'Kitchen',
    AppConstants.itemCategoryElectronics => 'Electronics',
    AppConstants.itemCategoryCleaning => 'Cleaning',
    AppConstants.itemCategoryStudy => 'Study',
    AppConstants.itemCategoryEventItems => 'Event Items',
    AppConstants.itemCategoryOther => 'Other',
    _ => value.isEmpty ? 'Other' : value,
  };
}

String _serviceCategoryLabel(String value) {
  return switch (value) {
    AppConstants.serviceCategoryHomeCleaningUpkeep => 'Home Cleaning',
    AppConstants.serviceCategoryRepairsMaintenance => 'Repairs',
    AppConstants.serviceCategoryAssemblyLabor => 'Assembly',
    AppConstants.serviceCategoryTutoringEducation => 'Tutoring',
    AppConstants.serviceCategoryAssistanceErrands => 'Errands',
    AppConstants.serviceCategoryItTechSetup => 'IT Setup',
    AppConstants.serviceCategoryHomeCookingMealPrep => 'Home Cooking',
    AppConstants.serviceCategoryCreativeDigitalTasks => 'Creative',
    _ => value.isEmpty ? 'Service' : value,
  };
}

String _servicePriceLabel(ServiceModel service) {
  if (service.priceType == AppConstants.servicePriceTypeFree) return 'Free';
  final amount =
      service.fixedJobPrice ?? service.hourlyRate ?? service.priceAmount ?? 0;
  final suffix = service.pricingMode == AppConstants.servicePricingModeHourly
      ? ' / hour'
      : '';
  return '${_money(amount)}$suffix';
}
