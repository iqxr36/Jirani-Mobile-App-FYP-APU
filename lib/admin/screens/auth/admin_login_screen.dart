// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_login_screen.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/widgets/admin_login_widgets.dart';
import 'package:jirani/admin/providers/admin_theme_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
import 'package:provider/provider.dart';

// Admin authentication UI feature: separate login screen for community/system admins.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _localError;
  bool _obscurePassword = true;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Admin authentication UI feature: validates credentials and signs the admin into the portal.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);
    authDebugLog('[AdminLoginScreen] login button pressed');
    final auth = context.read<AuthProvider>();
    authDebugLog('[AdminLoginScreen] login call started');
    await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      requireAdmin: true,
    );
    authDebugLog('[AdminLoginScreen] login call finished');
    if (!mounted) return;

    final admin = auth.currentAdmin;
    final user = auth.currentUser;
    if (auth.errorMessage != null || (admin == null && user == null)) {
      authDebugLog('[AdminLoginScreen] login failed');
      setState(() => _localError = auth.errorMessage);
      return;
    }

    if (admin != null) {
      return;
    }

    await auth.logout();
    if (!mounted) return;
    final role = user?.role ?? '';
    if (role == AppConstants.roleCommunityAdmin ||
        role == AppConstants.roleSystemAdmin) {
      setState(() {
        _localError =
            'This account has an old admin role in users. Create an admins/${user?.uid} document and assign its community there.';
      });
      return;
    }
    if (role == AppConstants.roleResident) {
      setState(() {
        _localError =
            'This account is a resident account. Please sign in through the Resident Mobile App.';
      });
    } else {
      setState(() => _localError = 'Admin role not found for this account.');
    }
  }

  Future<void> _sendResetEmail(AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _localError = 'Enter your email to reset password.');
      return;
    }
    await auth.sendPasswordResetEmail(email);
    if (!mounted) return;
    if (auth.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Text('Password reset email sent.'),
        ),
      );
    } else {
      setState(() => _localError = auth.errorMessage);
    }
  }

  Widget _buildForm({
    required AuthProvider auth,
    required Color primary,
    required bool compactHeader,
  }) {
    final displayedError = _localError ?? auth.errorMessage;
    return AdminLoginFormCard(
      primary: primary,
      compactHeader: compactHeader,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminLoginCardHeader(
              primary: primary,
              showBrandMark: compactHeader,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailCtrl,
              decoration: adminLoginInputDecoration(
                label: 'Email address',
                prefixIcon: Icons.mail_outline_rounded,
                primary: primary,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              decoration: adminLoginInputDecoration(
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                primary: primary,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!auth.isLoading) _submit();
              },
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading ? null : () => _sendResetEmail(auth),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Text('Forgot password?'),
              ),
            ),
            if (displayedError != null) ...[
              AdminLoginErrorBanner(message: displayedError),
              const SizedBox(height: 16),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Sign in',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            const AdminLoginFooterNote(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<AdminThemeProvider>();
    final primary = themeProvider.preset.primary;
    final secondary = themeProvider.preset.secondary;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = JiraniResponsive.isAdminWide(width);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget content;
    if (isWide) {
      content = Row(
        children: [
          Expanded(
            child: AdminLoginHeroPanel(primary: primary, secondary: secondary),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: _buildForm(
                  auth: auth,
                  primary: primary,
                  compactHeader: false,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(JiraniResponsive.gutter(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Secure admin access',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 28),
              _buildForm(auth: auth, primary: primary, compactHeader: true),
            ],
          ),
        ),
      );
    }

    final body = AdminLoginBackground(
      primary: primary,
      secondary: secondary,
      child: SafeArea(child: content),
    );

    if (reduceMotion) {
      return Scaffold(body: body);
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: body),
      ),
    );
  }
}
