// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_section.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';

enum AdminSection {
  overview(
    'Overview',
    'Community health at a glance',
    Icons.space_dashboard_rounded,
  ),
  verification(
    'Verification',
    'Review resident proof documents',
    Icons.verified_user_rounded,
  ),
  notifications(
    'Notifications',
    'Admin alerts and review tasks',
    Icons.notifications_active_rounded,
  ),
  residents(
    'Residents',
    'Directory and account controls',
    Icons.groups_2_rounded,
  ),
  news('News', 'Publish resident updates and events', Icons.campaign_rounded),
  listings(
    'Listings',
    'Marketplace and task moderation',
    Icons.storefront_rounded,
  ),
  reports(
    'Reports',
    'Complaints and dispute resolution',
    Icons.report_problem_rounded,
  ),
  transactions(
    'Transactions',
    'Deposits and platform ledger',
    Icons.receipt_long_rounded,
  ),
  settings(
    'Settings',
    'Admin profile and platform preferences',
    Icons.tune_rounded,
  );

  const AdminSection(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
