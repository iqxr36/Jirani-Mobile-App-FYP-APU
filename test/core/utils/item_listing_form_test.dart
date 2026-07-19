// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : item_listing_form_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,19-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/utils/item_listing_form.dart';

void main() {
  group('ItemListingFormValidator', () {
    test('requires at least one photo and complete item details', () {
      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'Hammer drill with carrying case.',
          imageCount: 0,
        ),
        'Add at least one item photo.',
      );

      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'Hammer drill with carrying case.',
          imageCount: 1,
        ),
        isNull,
      );
    });

    test('description boundary matches Firestore rules', () {
      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'a' * 11,
          imageCount: 1,
        ),
        isNotNull,
      );
      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'a' * 12,
          imageCount: 1,
        ),
        isNull,
      );
      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'a' * 1000,
          imageCount: 1,
        ),
        isNull,
      );
      expect(
        ItemListingFormValidator.validateDetails(
          title: 'Drill',
          category: 'tools',
          condition: 'good',
          description: 'a' * 1001,
          imageCount: 1,
        ),
        isNotNull,
      );
    });

    test('parses valid money amounts and rejects invalid amounts', () {
      expect(ItemListingFormValidator.parseAmount('25'), 25);
      expect(ItemListingFormValidator.parseAmount('1,250.50'), 1250.50);
      expect(ItemListingFormValidator.parseAmount('-10'), isNull);
      expect(ItemListingFormValidator.parseAmount('RM 25'), isNull);
    });

    test('requires fee and deposit based on pricing type', () {
      expect(
        ItemListingFormValidator.validateFinancial(
          pricingType: ItemListingPricingType.free,
          feeText: '',
          depositText: '',
        ),
        isNull,
      );

      expect(
        ItemListingFormValidator.validateFinancial(
          pricingType: ItemListingPricingType.feeAndDeposit,
          feeText: '25',
          depositText: '',
        ),
        'Enter a deposit greater than RM 0.',
      );

      expect(
        ItemListingFormValidator.validateFinancial(
          pricingType: ItemListingPricingType.feeAndDeposit,
          feeText: '25',
          depositText: '50',
        ),
        isNull,
      );
    });
  });
}
