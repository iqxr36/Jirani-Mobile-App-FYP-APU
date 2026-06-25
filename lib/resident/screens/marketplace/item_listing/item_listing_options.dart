part of '../resident_item_listing_view.dart';

class _Option {
  const _Option(this.label, this.value);

  final String label;
  final String value;
}

const List<_Option> _categoryOptions = [
  _Option('Tools', AppConstants.itemCategoryTools),
  _Option('Kitchen', AppConstants.itemCategoryKitchen),
  _Option('Electronics', AppConstants.itemCategoryElectronics),
  _Option('Cleaning', AppConstants.itemCategoryCleaning),
  _Option('Study', AppConstants.itemCategoryStudy),
  _Option('Event Items', AppConstants.itemCategoryEventItems),
  _Option('Other', AppConstants.itemCategoryOther),
];

const List<_Option> _conditionOptions = [
  _Option('New', AppConstants.itemConditionNew),
  _Option('Good', AppConstants.itemConditionGood),
  _Option('Used', AppConstants.itemConditionUsed),
];

const List<_Option> _handoverConditionOptions = [
  _Option('Excellent', AppConstants.borrowConditionBeforeExcellent),
  _Option('Good', AppConstants.borrowConditionBeforeGood),
  _Option('Fair', AppConstants.borrowConditionBeforeFair),
  _Option('Damaged', AppConstants.borrowConditionBeforeDamaged),
];

const List<_Option> _returnConditionOptions = [
  _Option('Same condition', AppConstants.borrowConditionAfterSame),
  _Option('Minor issue', AppConstants.borrowConditionAfterMinor),
  _Option('Major damage', AppConstants.borrowConditionAfterMajor),
  _Option('Lost', AppConstants.borrowConditionAfterLost),
];

const List<_Option> _returnInspectionOptions = [
  _Option('Item is Good', AppConstants.borrowConditionAfterSame),
  _Option('Report Minor Issue', AppConstants.borrowConditionAfterMinor),
  _Option('Report Major Damage', AppConstants.borrowConditionAfterMajor),
  _Option('Lost Item', AppConstants.borrowConditionAfterLost),
];

const List<_Option> _depositDecisionOptions = [
  _Option('Release deposit', AppConstants.depositDecisionReturnDeposit),
  _Option('Partial deduction', AppConstants.depositDecisionPartialDeduction),
  _Option('Withhold deposit', AppConstants.depositDecisionWithholdDeposit),
];
