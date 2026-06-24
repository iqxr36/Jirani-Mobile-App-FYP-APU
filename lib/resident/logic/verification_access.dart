import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

/// Whether the resident may use marketplace, services, borrowing, etc.
bool residentHasFullAppAccess(AppUser? user) =>
    user != null &&
    user.isResident &&
    user.isVerifiedResident &&
    user.locationVerified;

String verificationStatusMessage(String status) {
  switch (status) {
    case AppConstants.verificationSubmitted:
      return 'Your residency verification is under review. You can browse the app, but actions stay locked until an admin approves you.';
    case AppConstants.verificationRejected:
      return 'Your verification was not approved. Update your documents or contact support to unlock full access.';
    case AppConstants.verificationVerified:
      return 'You are verified. Stay inside your selected community to use full features.';
    case AppConstants.verificationPending:
    default:
      return 'Complete residency verification to unlock borrowing, lending, services, and marketplace actions.';
  }
}

void showVerificationRequiredSnack(BuildContext context, {AppUser? user}) {
  final status = user?.verificationStatus ?? AppConstants.verificationPending;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(verificationStatusMessage(status))));
}
