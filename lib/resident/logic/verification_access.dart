// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_access.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

// Verification access feature: returns whether the resident may use marketplace, services, borrowing, and lending actions.
bool residentHasFullAppAccess(AppUser? user) =>
    user != null &&
    user.isResident &&
    user.isActiveAccount &&
    user.isVerifiedResident &&
    user.locationVerified;

// Verification access feature: gates protected Firestore listeners behind the same rule as locked UI.
bool residentCanStartProtectedListeners(AppUser? user) =>
    residentHasFullAppAccess(user);

// Verification access feature: builds the blocked-action message based on account and verification state.
String residentAccessMessage(AppUser? user) {
  if (user == null) {
    return verificationStatusMessage(AppConstants.verificationPending);
  }
  if (user.hasActiveSuspension) {
    return 'Your account is suspended. Check the suspension notice for the access return time.';
  }
  switch (user.accountStatus) {
    case AppConstants.accountStatusArchived:
      return 'Your account is archived. Contact community admin if you need access restored.';
    default:
      return verificationStatusMessage(user.verificationStatus);
  }
}

// Verification access feature: maps verification status into the explanation shown on locked resident actions.
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

// Verification access feature: shows a SnackBar when an unverified resident taps a locked feature.
void showVerificationRequiredSnack(BuildContext context, {AppUser? user}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(residentAccessMessage(user))));
}
