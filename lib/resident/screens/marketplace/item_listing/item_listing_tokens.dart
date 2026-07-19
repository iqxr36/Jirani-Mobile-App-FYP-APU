// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : item_listing_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_item_listing_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kDanger = Color(0xFFB00020);
const double _kMaxContentWidth = 440;
const int _kMaxPhotos = 5;
final DateFormat _shortDateFormat = DateFormat('MMM d');
enum _LenderDashboardTab { listed, incoming }

enum _StatusTone { neutral, success, warning, danger }
