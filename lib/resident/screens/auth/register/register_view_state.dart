part of '../register_view.dart';

// Resident registration UI feature: owns registration form controllers, community picker, and submit action.
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

  // Resident registration UI feature: loads active communities for the registration community dropdown.
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

  // Resident registration UI feature: opens the community selector and stores the selected community.
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

  @override
  void initState() {
    super.initState();
    _guidelinesTap = TapGestureRecognizer();
    _termsTap = TapGestureRecognizer();
    _guidelinesTap.onTap = () =>
        _openLegalDocument(JiraniLegalDocument.communityGuidelines);
    _termsTap.onTap = () =>
        _openLegalDocument(JiraniLegalDocument.termsOfService);
    _loadActiveCommunities();
  }

  void _openLegalDocument(JiraniLegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JiraniLegalDocumentView(document: document),
      ),
    );
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

  // Resident registration UI feature: validates the form and creates the Firebase Auth/user profile account.
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isLoading;
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
                        _RegisterHeader(
                          textTheme: textTheme,
                          loading: loading,
                          onBack: () {
                            vm.clearError();
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(height: 10),
                        const Center(child: JiraniLogo(height: 82)),
                        const SizedBox(height: 12),
                        _RegisterFormCard(
                          formKey: _formKey,
                          loading: loading,
                          textTheme: textTheme,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          phoneController: _phoneController,
                          obscurePassword: _obscurePassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onToggleConfirmPassword: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          communityPicker: _buildRegisterCommunityPicker(
                            context: context,
                            enabled: !loading,
                            communitiesLoading: _communitiesLoading,
                            communitiesError: _communitiesError,
                            activeCommunities: _activeCommunities,
                            selectedCommunity: _selectedCommunity,
                            onSelectCommunity: _selectCommunity,
                          ),
                          acceptedTerms: _acceptedTerms,
                          onAcceptedTermsChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                          guidelinesTap: _guidelinesTap,
                          termsTap: _termsTap,
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 18),
                        _RegisterActionsFooter(
                          textTheme: textTheme,
                          loading: loading,
                          errorMessage: vm.errorMessage,
                          onSubmit: _submit,
                          onLogin: () {
                            vm.clearError();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginView(),
                              ),
                            );
                          },
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
