import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

/// Whether the resident may use marketplace, services, borrowing, etc.
bool residentHasFullAppAccess(AppUser? user) =>
    user != null &&
    user.isResident &&
    user.isActiveAccount &&
    user.isVerifiedResident &&
    user.locationVerified;

String residentAccessMessage(AppUser? user) {
  if (user == null) {
    return verificationStatusMessage(AppConstants.verificationPending);
  }
  switch (user.accountStatus) {
    case AppConstants.accountStatusSuspended:
      return 'Your account is suspended. Contact community admin for assistance.';
    case AppConstants.accountStatusArchived:
      return 'Your account is archived. Contact community admin if you need access restored.';
    default:
      return verificationStatusMessage(user.verificationStatus);
  }
}

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
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(residentAccessMessage(user))));
}
