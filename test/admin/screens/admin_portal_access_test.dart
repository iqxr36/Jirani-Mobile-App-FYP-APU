// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_portal_access_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/widgets/admin_login_widgets.dart';
import 'package:jirani/admin/providers/admin_theme_provider.dart';
import 'package:jirani/admin/screens/admin_dashboard_screen.dart';
import 'package:jirani/admin/screens/auth/admin_login_screen.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/screens/auth/suspended_account_view.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/logic/auth_wrapper.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('admin portal access', () {
    testWidgets('full-height desktop login shows the complete hero', (
      tester,
    ) async {
      await _pumpAdminLoginAtSize(tester, const Size(1440, 900));

      expect(find.byType(AdminLoginHeroPanel), findsOneWidget);
      expect(find.text('Verified access'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AdminLoginHeroPanel),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('short desktop login uses compact hero without scrolling', (
      tester,
    ) async {
      await _pumpAdminLoginAtSize(tester, const Size(1366, 768));

      expect(find.byType(AdminLoginHeroPanel), findsOneWidget);
      expect(find.text('Verified access'), findsNothing);
      expect(find.text('Resident verification'), findsOneWidget);
      expect(find.text('Live community insights'), findsOneWidget);
      expect(find.text('Secure by design'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AdminLoginHeroPanel),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('very short wide login falls back to single-column scrolling', (
      tester,
    ) async {
      await _pumpAdminLoginAtSize(tester, const Size(1280, 640));

      expect(find.byType(AdminLoginHeroPanel), findsNothing);
      expect(find.text('Secure admin access'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('admin login rejects and signs out a resident account', () async {
      final resident = _residentUser();
      final repository = _PortalAuthRepository(resident);
      final viewModel = _portalViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.login(
        email: resident.email,
        password: 'StrongPass1!',
        requireAdmin: true,
      );

      expect(repository.logoutCalls, 1);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.currentAdmin, isNull);
      expect(viewModel.firebaseUser, isNull);
      expect(
        viewModel.errorMessage,
        'This account is a resident account. Please sign in through the Resident Mobile App.',
      );
    });

    testWidgets('dashboard blocks a resident even if opened directly', (
      tester,
    ) async {
      final resident = _residentUser();
      final viewModel = _portalViewModel(
        repository: _PortalAuthRepository(resident),
        currentUser: resident,
      );
      addTearDown(viewModel.dispose);
      var logoutCalls = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: AdminDashboardScreen(
              onLogout: () => logoutCalls++,
              isLoggingOut: false,
            ),
          ),
        ),
      );

      expect(find.text('Admin access required'), findsOneWidget);
      expect(
        find.text(
          'This account is not authorized to open the administrator portal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Overview'), findsNothing);

      await tester.tap(find.text('Sign out'));
      expect(logoutCalls, 1);
    });

    testWidgets('web router keeps a resident on the admin login screen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      final resident = _residentUser();
      final repository = _PortalAuthRepository(resident);
      final viewModel = _portalViewModel(
        repository: repository,
        currentUser: resident,
      );
      viewModel.testingSetFirebaseUser(repository.firebaseUser);
      final themeProvider = AdminThemeProvider();
      addTearDown(viewModel.dispose);
      addTearDown(themeProvider.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: viewModel),
            ChangeNotifierProvider<AdminThemeProvider>.value(
              value: themeProvider,
            ),
          ],
          child: const MaterialApp(home: AuthWrapper(isWebOverride: true)),
        ),
      );
      await tester.pump();

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.text('Secure admin access'), findsWidgets);
    });

    testWidgets('mobile router sends a suspended resident to the notice', (
      tester,
    ) async {
      final resident = _residentUser().copyWith(
        accountStatus: AppConstants.accountStatusSuspended,
        suspendedReason: 'Community safety review.',
      );
      final repository = _PortalAuthRepository(resident);
      final viewModel = _portalViewModel(
        repository: repository,
        currentUser: resident,
      );
      viewModel.testingSetFirebaseUser(repository.firebaseUser);
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: AuthWrapper(isWebOverride: false)),
        ),
      );

      expect(find.byType(SuspendedAccountView), findsOneWidget);
      expect(find.text('Community safety review.'), findsOneWidget);
    });
  });
}

Future<void> _pumpAdminLoginAtSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(const {});
  final resident = _residentUser();
  final repository = _PortalAuthRepository(resident);
  final viewModel = _portalViewModel(repository: repository);
  final themeProvider = AdminThemeProvider();
  addTearDown(viewModel.dispose);
  addTearDown(themeProvider.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: viewModel),
        ChangeNotifierProvider<AdminThemeProvider>.value(value: themeProvider),
      ],
      child: const MaterialApp(home: AdminLoginScreen()),
    ),
  );
  await tester.pump();
}

AuthViewModel _portalViewModel({
  required AuthRepository repository,
  AppUser? currentUser,
}) {
  return AuthViewModel(
    repository: repository,
    userRepository: _FakeUserRepository(),
    connectionRepository: _FakeConnectionRepository(),
    verificationRepository: _FakeVerificationRepository(),
    chatRepository: _FakeChatRepository(),
    listenToAuthChanges: false,
    initialCurrentUser: currentUser,
  );
}

AppUser _residentUser() {
  final now = DateTime(2026, 7, 16);
  return AppUser(
    uid: 'resident-portal-test',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'resident@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationVerified,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'One South',
    unitNumber: 'A-1-1',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _PortalAuthRepository implements AuthRepository {
  _PortalAuthRepository(this.resident)
    : firebaseUser = MockUser(uid: resident.uid, email: resident.email);

  final AppUser resident;
  MockUser? firebaseUser;
  int logoutCalls = 0;

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  User? get currentFirebaseUser => firebaseUser;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #login) {
      return Future<void>.value();
    }
    if (invocation.memberName == #getCurrentAppUser) {
      return Future<AppUser?>.value(resident);
    }
    if (invocation.memberName == #getCurrentAdminUser) {
      return Future<Object?>.value(null);
    }
    if (invocation.memberName == #logout) {
      logoutCalls++;
      firebaseUser = null;
      return Future<void>.value();
    }
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class _FakeConnectionRepository implements ConnectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class _FakeVerificationRepository implements VerificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class _FakeChatRepository implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}
