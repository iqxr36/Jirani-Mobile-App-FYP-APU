enum ItemListingPricingType { free, feeOnly, depositOnly, feeAndDeposit }

extension ItemListingPricingTypeX on ItemListingPricingType {
  String get label {
    return switch (this) {
      ItemListingPricingType.free => 'Free',
      ItemListingPricingType.feeOnly => 'Borrowing Fee Only',
      ItemListingPricingType.depositOnly => 'Deposit Required',
      ItemListingPricingType.feeAndDeposit => 'Fee + Deposit',
    };
  }

  bool get requiresFee {
    return this == ItemListingPricingType.feeOnly ||
        this == ItemListingPricingType.feeAndDeposit;
  }

  bool get requiresDeposit {
    return this == ItemListingPricingType.depositOnly ||
        this == ItemListingPricingType.feeAndDeposit;
  }
}

class ItemListingFormValidator {
  ItemListingFormValidator._();

  static String? validateDetails({
    required String title,
    required String category,
    required String condition,
    required String description,
    required int imageCount,
  }) {
    if (imageCount <= 0) {
      return 'Add at least one item photo.';
    }
    if (title.trim().length < 3) {
      return 'Enter an item name with at least 3 characters.';
    }
    if (category.trim().isEmpty) {
      return 'Select an item category.';
    }
    if (condition.trim().isEmpty) {
      return 'Select the item condition.';
    }
    if (description.trim().length < 12) {
      return 'Describe the item with at least 12 characters.';
    }
    return null;
  }

  static String? validateFinancial({
    required ItemListingPricingType pricingType,
    required String feeText,
    required String depositText,
  }) {
    final fee = parseAmount(feeText);
    final deposit = parseAmount(depositText);
    if (pricingType.requiresFee && (fee == null || fee <= 0)) {
      return 'Enter a daily fee greater than RM 0.';
    }
    if (pricingType.requiresDeposit && (deposit == null || deposit <= 0)) {
      return 'Enter a deposit greater than RM 0.';
    }
    return null;
  }

  static double? parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    final amount = double.tryParse(normalized);
    if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
      return null;
    }
    return amount;
  }

  static const int maxPhotos = 5;
  static const int maxImageBytes = 10 * 1024 * 1024;

  static ItemListingPricingType pricingTypeFromFlags({
    required bool hasUsageFee,
    required bool hasDeposit,
  }) {
    if (hasUsageFee && hasDeposit) {
      return ItemListingPricingType.feeAndDeposit;
    }
    if (hasUsageFee) return ItemListingPricingType.feeOnly;
    if (hasDeposit) return ItemListingPricingType.depositOnly;
    return ItemListingPricingType.free;
  }

  static String? validateListing({
    required String title,
    required String description,
    required String category,
    required String condition,
    required int imageCount,
    required bool hasUsageFee,
    required bool hasDeposit,
    double? feeAmount,
    double? depositAmount,
  }) {
    final detailsError = validateDetails(
      title: title,
      category: category,
      condition: condition,
      description: description,
      imageCount: imageCount,
    );
    if (detailsError != null) return detailsError;

    if (imageCount > maxPhotos) {
      return 'You can upload up to $maxPhotos photos.';
    }

    final pricingType = pricingTypeFromFlags(
      hasUsageFee: hasUsageFee,
      hasDeposit: hasDeposit,
    );
    return validateFinancial(
      pricingType: pricingType,
      feeText: hasUsageFee ? (feeAmount?.toString() ?? '') : '',
      depositText: hasDeposit ? (depositAmount?.toString() ?? '') : '',
    );
  }
}
