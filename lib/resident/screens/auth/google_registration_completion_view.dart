// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : google_registration_completion_view.dart (Dart source file)
// Description     : Completes resident information for first-time Google users before creating their Firestore profile.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/resident/screens/auth/resident_registration_ui.dart';
import 'package:jirani/resident/screens/legal/legal_document_view.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/services/community_service.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:provider/provider.dart';

class GoogleRegistrationCompletionView extends StatefulWidget {
  const GoogleRegistrationCompletionView({super.key, this.communityReader});

  final CommunityReader? communityReader;

  @override
  State<GoogleRegistrationCompletionView> createState() =>
      _GoogleRegistrationCompletionViewState();
}

class _GoogleRegistrationCompletionViewState
    extends State<GoogleRegistrationCompletionView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late final CommunityReader _communityReader =
      widget.communityReader ?? CommunityService();
  late final TapGestureRecognizer _guidelinesTap;
  late final TapGestureRecognizer _termsTap;

  List<CommunityModel> _communities = const [];
  CommunityModel? _selectedCommunity;
  bool _loadingCommunities = true;
  bool _profilePrefilled = false;
  bool _termsAccepted = false;
  String? _communitiesError;

  @override
  void initState() {
    super.initState();
    _guidelinesTap = TapGestureRecognizer()
      ..onTap = () =>
          _openLegalDocument(JiraniLegalDocument.communityGuidelines);
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegalDocument(JiraniLegalDocument.termsOfService);
    _loadCommunities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profilePrefilled) return;
    _profilePrefilled = true;
    final firebaseUser = context.read<AuthViewModel>().firebaseUser;
    final names = _splitDisplayName(firebaseUser?.displayName?.trim() ?? '');
    _firstNameController.text = names.$1;
    _lastNameController.text = names.$2;
    _emailController.text = firebaseUser?.email?.trim() ?? '';
  }

  @override
  void dispose() {
    _guidelinesTap.dispose();
    _termsTap.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  (String, String) _splitDisplayName(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  Future<void> _loadCommunities() async {
    if (mounted) {
      setState(() {
        _loadingCommunities = true;
        _communitiesError = null;
      });
    }
    try {
      final communities = [...await _communityReader.fetchActiveCommunities()];
      communities.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _communities = communities;
        _loadingCommunities = false;
        _communitiesError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCommunities = false;
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
          if (_loadingCommunities) {
            return const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (_communitiesError != null) {
            return _GoogleCommunityModalMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load communities',
              message: _communitiesError!,
              actionLabel: 'Try Again',
              onAction: () async {
                await _loadCommunities();
                if (mounted) setModalState(() {});
              },
            );
          }
          if (_communities.isEmpty) {
            return _GoogleCommunityModalMessage(
              icon: Icons.apartment_rounded,
              title: 'No communities available',
              message:
                  'An active partner community is required to create your account.',
              actionLabel: 'Refresh',
              onAction: () async {
                await _loadCommunities();
                if (mounted) setModalState(() {});
              },
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._communities.map(
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

  Future<void> _submit() async {
    final viewModel = context.read<AuthViewModel>();
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Community Guidelines and Terms of Service.',
          ),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final community = _selectedCommunity;
    if (community == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select your community.')));
      return;
    }
    await viewModel.completeGoogleRegistration(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      termsAccepted: true,
      communityId: community.communityId,
      communityName: community.name,
    );
  }

  void _openLegalDocument(JiraniLegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JiraniLegalDocumentView(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, _) {
        final loading = viewModel.isLoading;
        final bottomInset = JiraniResponsive.bottomInset(context);
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
                        ResidentRegistrationHeader(
                          title: 'Complete Registration',
                          loading: loading,
                          onBack: viewModel.logout,
                        ),
                        const SizedBox(height: 10),
                        const Center(child: JiraniLogo(height: 82)),
                        const SizedBox(height: 12),
                        ResidentRegistrationFormCard(
                          formKey: _formKey,
                          children: [
                            ResidentRegistrationField(
                              fieldKey: const Key(
                                'google-registration-first-name',
                              ),
                              label: 'First Name',
                              controller: _firstNameController,
                              hint: 'John',
                              enabled: !loading,
                              autofillHints: const [AutofillHints.givenName],
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[A-Za-z\s'-]"),
                                ),
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: Validators.validateFirstName,
                            ),
                            const SizedBox(height: 12),
                            ResidentRegistrationField(
                              fieldKey: const Key(
                                'google-registration-last-name',
                              ),
                              label: 'Last Name',
                              controller: _lastNameController,
                              hint: 'Doe',
                              enabled: !loading,
                              autofillHints: const [AutofillHints.familyName],
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[A-Za-z\s'-]"),
                                ),
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: Validators.validateLastName,
                            ),
                            const SizedBox(height: 12),
                            ResidentRegistrationField(
                              label: 'Email Address',
                              controller: _emailController,
                              hint: 'John@example.com',
                              keyboardType: TextInputType.emailAddress,
                              enabled: !loading,
                              readOnly: true,
                              suffixIcon: const Tooltip(
                                message: 'Verified by Google',
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: residentRegistrationBrandTeal,
                                ),
                              ),
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 12),
                            ResidentCommunityPicker(
                              pickerKey: const Key(
                                'google-registration-community',
                              ),
                              enabled: !loading,
                              communitiesLoading: _loadingCommunities,
                              communitiesError: _communitiesError,
                              activeCommunities: _communities,
                              selectedCommunity: _selectedCommunity,
                              onSelectCommunity: _selectCommunity,
                              emptyMessage:
                                  'An active community is required to create your account.',
                            ),
                            const SizedBox(height: 12),
                            ResidentRegistrationField(
                              fieldKey: const Key('google-registration-phone'),
                              label: 'Phone Number',
                              controller: _phoneController,
                              hint: '+60 12-345 6789',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: _submit,
                              enabled: !loading,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\s-]'),
                                ),
                                LengthLimitingTextInputFormatter(20),
                              ],
                              validator: Validators.validatePhone,
                            ),
                            const SizedBox(height: 10),
                            _GoogleRegistrationTerms(
                              key: const Key('google-registration-terms'),
                              textTheme: textTheme,
                              loading: loading,
                              accepted: _termsAccepted,
                              guidelinesTap: _guidelinesTap,
                              termsTap: _termsTap,
                              onChanged: (value) => setState(
                                () => _termsAccepted = value ?? false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (viewModel.errorMessage case final error?)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      error,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ResidentRegistrationPrimaryButton(
                                  buttonKey: const Key(
                                    'google-registration-submit',
                                  ),
                                  loading: loading,
                                  label: 'Create Account',
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Use a different Google account?',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: context.appInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          residentRegistrationBrandTeal,
                                      minimumSize: const Size(48, 44),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : viewModel.logout,
                                    child: const Text(
                                      'Sign out',
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

class _GoogleRegistrationTerms extends StatelessWidget {
  const _GoogleRegistrationTerms({
    super.key,
    required this.textTheme,
    required this.loading,
    required this.accepted,
    required this.guidelinesTap,
    required this.termsTap,
    required this.onChanged,
  });

  final TextTheme textTheme;
  final bool loading;
  final bool accepted;
  final TapGestureRecognizer guidelinesTap;
  final TapGestureRecognizer termsTap;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxTheme(
      data: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.shade400;
          }
          if (states.contains(WidgetState.selected)) {
            return residentRegistrationBrandTeal;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade700, width: 1.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: CheckboxListTile(
        value: accepted,
        onChanged: loading ? null : onChanged,
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
                TextStyle(color: context.appInk, fontSize: 13, height: 1.35),
            children: [
              const TextSpan(text: 'I agree to the '),
              TextSpan(
                text: 'Community Guidelines',
                style: const TextStyle(
                  color: residentRegistrationBrandTeal,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
                recognizer: guidelinesTap,
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Terms of Service',
                style: const TextStyle(
                  color: residentRegistrationBrandTeal,
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
    );
  }
}

class _GoogleCommunityModalMessage extends StatelessWidget {
  const _GoogleCommunityModalMessage({
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
          const SizedBox(height: 4),
          Icon(icon, color: residentRegistrationBrandTeal, size: 38),
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
              color: context.appMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: residentRegistrationBrandTeal,
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
