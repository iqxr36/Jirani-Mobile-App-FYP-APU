// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : marketplace_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_marketplace_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kWarmAccent = Color(0xFFE29578);
const double _kMaxContentWidth = 440;

final DateFormat _shortDateFormat = DateFormat('d MMM yyyy');
final DateFormat _compactDateFormat = DateFormat('MMM d');

enum _MarketplaceSection { browse, requests }

enum _RentalMode { daily, hourly }

class _CategoryFilter {
  const _CategoryFilter(this.label, this.value);

  final String label;
  final String value;
}

const List<_CategoryFilter> _categoryFilters = [
  _CategoryFilter('All Items', 'all'),
  _CategoryFilter('Tools', AppConstants.itemCategoryTools),
  _CategoryFilter('Kitchen', AppConstants.itemCategoryKitchen),
  _CategoryFilter('Electronics', AppConstants.itemCategoryElectronics),
  _CategoryFilter('Cleaning', AppConstants.itemCategoryCleaning),
  _CategoryFilter('Study', AppConstants.itemCategoryStudy),
  _CategoryFilter('Events', AppConstants.itemCategoryEventItems),
  _CategoryFilter('Other', AppConstants.itemCategoryOther),
];
