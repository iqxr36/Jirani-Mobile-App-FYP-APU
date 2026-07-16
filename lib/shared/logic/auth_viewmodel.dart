library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/community_change.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/models/admin_notification_preferences.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/utils/auth_error_messages.dart';

part 'auth_viewmodel/auth_viewmodel_core.dart';
part 'auth_viewmodel/auth_viewmodel_sign_in.dart';
part 'auth_viewmodel/auth_viewmodel_registration.dart';
part 'auth_viewmodel/auth_viewmodel_verification.dart';
part 'auth_viewmodel/auth_viewmodel_profile.dart';
part 'auth_viewmodel/auth_viewmodel_community.dart';

/// Auth state manager: coordinates Firebase session, resident/admin profiles, registration, verification, and profile updates.
class AuthViewModel extends _AuthViewModelBase
    with
        _AuthViewModelSignInMixin,
        _AuthViewModelRegistrationMixin,
        _AuthViewModelVerificationMixin,
        _AuthViewModelProfileMixin,
        _AuthViewModelCommunityMixin {
  AuthViewModel({
    super.repository,
    super.userRepository,
    super.connectionRepository,
    super.verificationRepository,
    super.chatRepository,
    super.listenToAuthChanges,
    super.initialCurrentUser,
    super.initialCurrentAdmin,
    super.surfaceAdminProfileImageHydrationErrors,
  });

  @visibleForTesting
  /// Auth tests: injects a Firebase user without listening to real Firebase auth changes.
  void testingSetFirebaseUser(User? user) {
    _firebaseUser = user;
  }

  @visibleForTesting
  Future<bool> testingHydrateAdminProfileImage() {
    return _hydrateAdminProfileImageIfNeeded();
  }

  void reportAdminProfileImageRenderFailure(Object error) {
    _reportAdminProfileImageRenderFailure(error);
  }

  @visibleForTesting
  factory AuthViewModel.forTesting({
    AppUser? currentUser,
    AdminUser? currentAdmin,
    AuthRepository? repository,
    UserRepository? userRepository,
    ConnectionRepository? connectionRepository,
    VerificationRepository? verificationRepository,
    ChatRepository? chatRepository,
    bool? surfaceAdminProfileImageHydrationErrors,
  }) {
    return AuthViewModel(
      repository: repository,
      userRepository: userRepository,
      connectionRepository: connectionRepository,
      verificationRepository: verificationRepository,
      chatRepository: chatRepository,
      listenToAuthChanges: false,
      initialCurrentUser: currentUser,
      initialCurrentAdmin: currentAdmin,
      surfaceAdminProfileImageHydrationErrors:
          surfaceAdminProfileImageHydrationErrors,
    );
  }
}
