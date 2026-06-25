part of '../register_view.dart';

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({
    required this.textTheme,
    required this.loading,
    required this.onBack,
  });

  final TextTheme textTheme;
  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _kBrandTeal,
              ),
              onPressed: loading ? null : onBack,
            ),
          ),
          Text(
            'Join the Community',
            textAlign: TextAlign.center,
            style:
                textTheme.titleMedium?.copyWith(
                  color: _kBrandTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ) ??
                const TextStyle(
                  color: _kBrandTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
          ),
        ],
      ),
    );
  }
}

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({
    required this.formKey,
    required this.loading,
    required this.textTheme,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.communityPicker,
    required this.acceptedTerms,
    required this.onAcceptedTermsChanged,
    required this.guidelinesTap,
    required this.termsTap,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool loading;
  final TextTheme textTheme;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final Widget communityPicker;
  final bool acceptedTerms;
  final ValueChanged<bool?> onAcceptedTermsChanged;
  final TapGestureRecognizer guidelinesTap;
  final TapGestureRecognizer termsTap;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.glassFill(),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: context.residentOutline(lightAlpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'First Name',
                    controller: firstNameController,
                    hint: 'John',
                    enabled: !loading,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[A-Za-z\s'-]"),
                      ),
                      LengthLimitingTextInputFormatter(60),
                    ],
                    validator: Validators.validateFirstName,
                  ),
                  const SizedBox(height: 12),
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'Last Name',
                    controller: lastNameController,
                    hint: 'Doe',
                    enabled: !loading,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[A-Za-z\s'-]"),
                      ),
                      LengthLimitingTextInputFormatter(60),
                    ],
                    validator: Validators.validateLastName,
                  ),
                  const SizedBox(height: 12),
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'Email Address',
                    controller: emailController,
                    hint: 'John@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !loading,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'Password',
                    controller: passwordController,
                    hint: '••••••••',
                    obscureText: obscurePassword,
                    enabled: !loading,
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: context.appMuted,
                        size: 22,
                      ),
                      onPressed: loading ? null : onTogglePassword,
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 12),
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    hint: '••••••••',
                    obscureText: obscureConfirmPassword,
                    enabled: !loading,
                    suffixIcon: IconButton(
                      tooltip: obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: context.appMuted,
                        size: 22,
                      ),
                      onPressed: loading ? null : onToggleConfirmPassword,
                    ),
                    validator: (v) => Validators.validateConfirmPassword(
                      v,
                      passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  communityPicker,
                  const SizedBox(height: 12),
                  _buildRegisterFieldGroup(
                    context: context,
                    label: 'Phone Number',
                    controller: phoneController,
                    hint: '+60 12-345 6789',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: onSubmit,
                    enabled: !loading,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 10),
                  CheckboxTheme(
                    data: CheckboxThemeData(
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey.shade400;
                        }
                        if (states.contains(WidgetState.selected)) {
                          return _kBrandTeal;
                        }
                        return null;
                      }),
                      checkColor: WidgetStateProperty.all(Colors.white),
                      side: BorderSide(color: Colors.grey.shade700, width: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: CheckboxListTile(
                      value: acceptedTerms,
                      onChanged: loading ? null : onAcceptedTermsChanged,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: RichText(
                        text: TextSpan(
                          style:
                              textTheme.bodySmall?.copyWith(
                                color: context.appInk,
                                fontSize: 13,
                                height: 1.35,
                              ) ??
                              TextStyle(
                                color: context.appInk,
                                fontSize: 13,
                                height: 1.35,
                              ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Community Guidelines',
                              style: const TextStyle(
                                color: _kBrandTeal,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: guidelinesTap,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: _kBrandTeal,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: termsTap,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterActionsFooter extends StatelessWidget {
  const _RegisterActionsFooter({
    required this.textTheme,
    required this.loading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onLogin,
  });

  final TextTheme textTheme;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _kBrandTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Already have an account?',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: context.appInk),
            ),
            const SizedBox(height: 6),
            Align(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _kBrandTeal,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: loading ? null : onLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
