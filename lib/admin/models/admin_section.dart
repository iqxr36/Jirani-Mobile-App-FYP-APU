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
