import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/services/community_service.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

/// Register screen — compact header, labeled fields in card, teal primary button.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _communityService = CommunityService();

  late final TapGestureRecognizer _guidelinesTap;
  late final TapGestureRecognizer _termsTap;

  List<CommunityModel> _activeCommunities = const [];
  CommunityModel? _selectedCommunity;
  bool _communitiesLoading = true;
  String? _communitiesError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  static const Color _kBrandTeal = Color(0xFF006D77);
  static const double _kCardRadius = 26;
  static const double _kFieldRadius = 10;

  static const TextStyle _kLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.28),
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: const BorderSide(color: _kBrandTeal, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
      ),
    );
  }

  Widget _buildFieldGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onFieldSubmitted,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _kLabelStyle),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 15),
          onFieldSubmitted: onFieldSubmitted != null
              ? (_) => onFieldSubmitted()
              : null,
          decoration: _inputDecoration(hint: hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _loadActiveCommunities() async {
    if (mounted) {
      setState(() {
        _communitiesLoading = true;
        _communitiesError = null;
      });
    }
    try {
      final communities = await _communityService.fetchActiveCommunities();
      communities.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _activeCommunities = communities;
        _communitiesLoading = false;
        _communitiesError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _communitiesLoading = false;
        _communitiesError = 'Communities could not be loaded right now.';
      });
    }
  }

  Future<void> _selectCommunity() async {
    final selected = await showJiraniModalBottomSheet<CommunityModel>(
      context: context,
      title: 'Select Your Community',
      subtitle: 'Available partner communities',
      icon: Icons.apartment_rounded,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          if (_communitiesLoading) {
            return const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          if (_communitiesError != null) {
            return _CommunityModalMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load communities',
              message: _communitiesError!,
              actionLabel: 'Try Again',
              onAction: () async {
                await _loadActiveCommunities();
                if (mounted) setModalState(() {});
              },
            );
          }

          if (_activeCommunities.isEmpty) {
            return _CommunityModalMessage(
              icon: Icons.apartment_rounded,
              title: 'No communities available',
              message:
                  'Active communities will appear here once they are set up.',
              actionLabel: 'Refresh',
              onAction: () async {
                await _loadActiveCommunities();
                if (mounted) setModalState(() {});
              },
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._activeCommunities.map(
                (community) => JiraniModalOption(
                  title: community.name,
                  subtitle: community.city,
                  icon: Icons.apartment_rounded,
                  selected:
                      _selectedCommunity?.communityId == community.communityId,
                  onTap: () => Navigator.of(modalContext).pop(community),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCommunity = selected);
    }
  }

  Widget _buildCommunityPicker({required bool enabled}) {
    final hasOptions = _activeCommunities.isNotEmpty;
    final canSelect = enabled;
    final selectedName = _selectedCommunity?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Community / Residence', style: _kLabelStyle),
        const SizedBox(height: 6),
        if (_communitiesLoading)
          const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSelect ? _selectCommunity : null,
              borderRadius: BorderRadius.circular(_kFieldRadius),
              child: InputDecorator(
                decoration: _inputDecoration(
                  hint: hasOptions
                      ? 'Select your community'
                      : 'No active communities available',
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                isEmpty: selectedName == null || selectedName.isEmpty,
                child: Text(
                  selectedName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: canSelect
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          ),
        if (_communitiesError != null || !hasOptions && !_communitiesLoading)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _communitiesError ??
                  'You can select a community during location verification.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _guidelinesTap = TapGestureRecognizer();
    _termsTap = TapGestureRecognizer();
    _guidelinesTap.onTap = () {};
    _termsTap.onTap = () {};
    _loadActiveCommunities();
  }

  @override
  void dispose() {
    _guidelinesTap.dispose();
    _termsTap.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<AuthViewModel>();
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Community Guidelines and Terms of Service.',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_activeCommunities.isNotEmpty && _selectedCommunity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select your community.')));
      return;
    }

    await vm.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      termsAccepted: true,
      communityId: _selectedCommunity?.communityId ?? '',
      communityName: _selectedCommunity?.name ?? '',
    );
    if (!mounted || vm.errorMessage != null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildHeader(AuthViewModel vm, TextTheme textTheme) {
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
              onPressed: vm.isLoading
                  ? null
                  : () {
                      vm.clearError();
                      Navigator.of(context).pop();
                    },
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isLoading;

        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(vm, textTheme),
                        const SizedBox(height: 10),
                        const Center(child: JiraniLogo(height: 82)),
                        const SizedBox(height: 12),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  _kCardRadius,
                                ),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 18,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildFieldGroup(
                                        label: 'First Name',
                                        controller: _firstNameController,
                                        hint: 'John',
                                        enabled: !loading,
                                        validator: Validators.validateFirstName,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFieldGroup(
                                        label: 'Last Name',
                                        controller: _lastNameController,
                                        hint: 'Doe',
                                        enabled: !loading,
                                        validator: Validators.validateLastName,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFieldGroup(
                                        label: 'Email Address',
                                        controller: _emailController,
                                        hint: 'John@example.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        enabled: !loading,
                                        validator: Validators.validateEmail,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFieldGroup(
                                        label: 'Password',
                                        controller: _passwordController,
                                        hint: '••••••••',
                                        obscureText: _obscurePassword,
                                        enabled: !loading,
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            size: 22,
                                          ),
                                          onPressed: loading
                                              ? null
                                              : () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                        ),
                                        validator: Validators.validatePassword,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFieldGroup(
                                        label: 'Confirm Password',
                                        controller: _confirmPasswordController,
                                        hint: '••••••••',
                                        obscureText: _obscureConfirmPassword,
                                        enabled: !loading,
                                        suffixIcon: IconButton(
                                          tooltip: _obscureConfirmPassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            size: 22,
                                          ),
                                          onPressed: loading
                                              ? null
                                              : () => setState(
                                                  () => _obscureConfirmPassword =
                                                      !_obscureConfirmPassword,
                                                ),
                                        ),
                                        validator: (v) =>
                                            Validators.validateConfirmPassword(
                                              v,
                                              _passwordController.text,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCommunityPicker(enabled: !loading),
                                      const SizedBox(height: 12),
                                      _buildFieldGroup(
                                        label: 'Phone Number',
                                        controller: _phoneController,
                                        hint: '+60 12-345 6789',
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: _submit,
                                        enabled: !loading,
                                        validator: Validators.validatePhone,
                                      ),
                                      const SizedBox(height: 10),
                                      CheckboxTheme(
                                        data: CheckboxThemeData(
                                          fillColor:
                                              WidgetStateProperty.resolveWith((
                                                states,
                                              ) {
                                                if (states.contains(
                                                  WidgetState.disabled,
                                                )) {
                                                  return Colors.grey.shade400;
                                                }
                                                if (states.contains(
                                                  WidgetState.selected,
                                                )) {
                                                  return _kBrandTeal;
                                                }
                                                return null;
                                              }),
                                          checkColor: WidgetStateProperty.all(
                                            Colors.white,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade700,
                                            width: 1.5,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: CheckboxListTile(
                                          value: _acceptedTerms,
                                          onChanged: loading
                                              ? null
                                              : (v) => setState(
                                                  () => _acceptedTerms =
                                                      v ?? false,
                                                ),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: RichText(
                                            text: TextSpan(
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                    color: Colors.black87,
                                                    fontSize: 13,
                                                    height: 1.35,
                                                  ) ??
                                                  const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 13,
                                                    height: 1.35,
                                                  ),
                                              children: [
                                                const TextSpan(
                                                  text: 'I agree to the ',
                                                ),
                                                TextSpan(
                                                  text: 'Community Guidelines',
                                                  style: const TextStyle(
                                                    color: _kBrandTeal,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer: _guidelinesTap,
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: const TextStyle(
                                                    color: _kBrandTeal,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer: _termsTap,
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
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (vm.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      vm.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
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
                                      disabledBackgroundColor: _kBrandTeal
                                          .withValues(alpha: 0.6),
                                      disabledForegroundColor: Colors.white70,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: loading ? null : _submit,
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
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: _kBrandTeal,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () {
                                            vm.clearError();
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const LoginView(),
                                              ),
                                            );
                                          },
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CommunityModalMessage extends StatelessWidget {
  const _CommunityModalMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _RegisterViewState._kBrandTeal, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _RegisterViewState._kBrandTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
