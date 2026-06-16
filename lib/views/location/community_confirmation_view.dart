import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/services/community_service.dart';
import 'package:jirani/services/geofence_manager.dart';
import 'package:jirani/services/location_access.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/location/geofence_checking_view.dart';
import 'package:jirani/views/location/location_permission_view.dart';
import 'package:jirani/shared/widgets/jirani_modal.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

class CommunityConfirmationView extends StatefulWidget {
  const CommunityConfirmationView({super.key});

  @override
  State<CommunityConfirmationView> createState() =>
      _CommunityConfirmationViewState();
}

class _CommunityConfirmationViewState extends State<CommunityConfirmationView> {
  final CommunityService _communityService = CommunityService();

  List<CommunityModel> _communities = const [];
  CommunityModel? _selectedCommunity;
  String? _loadError;
  bool _isLoadingCommunities = true;
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      final communities = await _communityService.fetchActiveCommunities();
      communities.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;

      final viewModel = context.read<AuthViewModel>();
      final savedId = viewModel.currentUser?.communityId.trim() ?? '';
      final savedName = viewModel.currentUser?.communityName.trim() ?? '';
      CommunityModel? selected;
      for (final community in communities) {
        if (community.communityId == savedId || community.name == savedName) {
          selected = community;
          break;
        }
      }

      setState(() {
        _communities = communities;
        _selectedCommunity =
            selected ?? (communities.isEmpty ? null : communities.first);
        _loadError = null;
        _isLoadingCommunities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load active communities.';
        _isLoadingCommunities = false;
      });
    }
  }

  CommunityModel? _currentSelection(AuthViewModel viewModel) {
    if (_selectedCommunity != null) return _selectedCommunity!;

    final savedId = viewModel.currentUser?.communityId.trim() ?? '';
    final savedName = viewModel.currentUser?.communityName.trim() ?? '';
    for (final community in _communities) {
      if (community.communityId == savedId || community.name == savedName) {
        return community;
      }
    }
    return _communities.isEmpty ? null : _communities.first;
  }

  Future<void> _changeCommunity(AuthViewModel viewModel) async {
    final current = _currentSelection(viewModel);
    final selected = await showJiraniModalBottomSheet<CommunityModel>(
      context: context,
      title: 'Select Your Community',
      subtitle: 'Available partner communities',
      icon: Icons.apartment_rounded,
      child: Builder(
        builder: (modalContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._communities.map(
                (community) => JiraniModalOption(
                  title: community.name,
                  subtitle: community.city,
                  icon: Icons.apartment_rounded,
                  selected: current?.communityId == community.communityId,
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

  bool _isChangingSavedCommunity(
    AuthViewModel viewModel,
    CommunityModel community,
  ) {
    final user = viewModel.currentUser;
    if (user == null) return false;

    final currentCommunityId = user.communityId.trim();
    final currentCommunityName = user.communityName.trim();
    final nextCommunityId = community.communityId.trim();
    final nextCommunityName = community.name.trim();
    if (currentCommunityId.isNotEmpty && nextCommunityId.isNotEmpty) {
      return currentCommunityId != nextCommunityId;
    }
    return currentCommunityName != nextCommunityName;
  }

  bool _needsVerificationResetWarning(
    AuthViewModel viewModel,
    CommunityModel community,
  ) {
    return viewModel.currentUser?.verificationStatus ==
            AppConstants.verificationVerified &&
        _isChangingSavedCommunity(viewModel, community);
  }

  Future<bool> _confirmVerificationReset(CommunityModel community) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF071817).withValues(alpha: 0.62),
      builder: (dialogContext) {
        return _CommunityChangeWarningDialog(
          communityName: community.name,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _continue(AuthViewModel viewModel) async {
    if (_isContinuing) return;
    final community = _currentSelection(viewModel);
    if (community == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a community first.')),
      );
      return;
    }

    if (_needsVerificationResetWarning(viewModel, community)) {
      final confirmed = await _confirmVerificationReset(community);
      if (!mounted || !confirmed) return;
    }

    setState(() => _isContinuing = true);

    try {
      await viewModel.updateSelectedCommunity(
        communityId: community.communityId,
        communityName: community.name,
      );
      if (!await LocationAccess.isLocationReadyForUse()) {
        if (!mounted) return;
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => LocationPermissionView(
              nextBuilder: (_) => GeofenceCheckingView(
                communityId: community.communityId,
                communityName: community.name,
              ),
            ),
          ),
        );
        return;
      }
      await _startNativeMonitoring(community);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => GeofenceCheckingView(
            communityId: community.communityId,
            communityName: community.name,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your community. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  Future<void> _startNativeMonitoring(CommunityModel selectedCommunity) async {
    try {
      final canRunInBackground = await GeofenceManager.instance
          .hasBackgroundLocationPermission();
      if (canRunInBackground) {
        await GeofenceManager.instance.startGeofencing([selectedCommunity]);
        return;
      }
    } catch (error) {
      debugPrint('Gatekeeper: native monitoring registration failed: $error');
    }

    debugPrint(
      'Gatekeeper: native background monitoring was not enabled; '
      'continuing with the immediate location check.',
    );
  }

  Widget _buildCommunityCard(CommunityModel community) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4E9ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home, color: Color(0xFF53657A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECTED COMMUNITY',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        community.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 15,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              community.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Divider(
              height: 1,
              thickness: 1.5,
              color: Colors.black.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: _kBrandTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 17, color: Colors.black),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We will check whether you are currently near\nthis community to continue verification.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityContent(CommunityModel? community) {
    if (_isLoadingCommunities) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (community != null) return _buildCommunityCard(community);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, color: _kBrandTeal, size: 34),
          const SizedBox(height: 10),
          Text(
            _loadError ?? 'No active communities have been saved yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _loadCommunities(),
              child: const Text('Try Loading Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final community = _currentSelection(viewModel);
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(26, 14, 26, 18 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Confirm Your Community',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _kBrandTeal,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Please confirm your selected residence\nbefore we check your location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildCommunityContent(community),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 26),
                          _buildButton(
                            label: _isContinuing ? 'Saving...' : 'Continue',
                            background: _kBrandTeal,
                            foreground: Colors.white,
                            onPressed:
                                _isContinuing ||
                                    _isLoadingCommunities ||
                                    community == null
                                ? null
                                : () => _continue(viewModel),
                          ),
                          const SizedBox(height: 12),
                          _buildButton(
                            label: 'Change Community',
                            background: const Color(
                              0xFF787880,
                            ).withValues(alpha: 0.16),
                            foreground: _kBrandTeal,
                            onPressed: _isContinuing || _communities.isEmpty
                                ? null
                                : () => _changeCommunity(viewModel),
                          ),
                        ],
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

class _CommunityChangeWarningDialog extends StatelessWidget {
  const _CommunityChangeWarningDialog({
    required this.communityName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String communityName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 7, color: const Color(0xFFE29578)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE29578,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFFE29578,
                                ).withValues(alpha: 0.30),
                              ),
                            ),
                            child: const Icon(
                              Icons.move_down_rounded,
                              color: Color(0xFF9A4D2D),
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change community?',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF102B2A),
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Moving to $communityName will reset your residency access.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF556361),
                                    fontWeight: FontWeight.w500,
                                    height: 1.42,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _WarningImpactRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Verification will reset',
                        subtitle:
                            'You will become unverified in your current and new community.',
                      ),
                      const SizedBox(height: 8),
                      const _WarningImpactRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Resident features will lock',
                        subtitle:
                            'Borrowing, lending, services, and marketplace actions pause.',
                      ),
                      const SizedBox(height: 8),
                      const _WarningImpactRow(
                        icon: Icons.description_outlined,
                        title: 'Documents must be submitted again',
                        subtitle:
                            'Upload proof of residence for the new community.',
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useStackedButtons = constraints.maxWidth < 330;
                          final cancelButton = OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              foregroundColor: const Color(0xFF173836),
                              side: const BorderSide(color: Color(0xFFD8E8E6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Keep Current'),
                          );
                          final confirmButton = FilledButton(
                            onPressed: onConfirm,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: const Color(0xFF006D77),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Change Community'),
                          );

                          if (useStackedButtons) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                confirmButton,
                                const SizedBox(height: 10),
                                cancelButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: cancelButton),
                              const SizedBox(width: 10),
                              Expanded(child: confirmButton),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningImpactRow extends StatelessWidget {
  const _WarningImpactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D7C8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9A4D2D), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D211C),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF675247),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
