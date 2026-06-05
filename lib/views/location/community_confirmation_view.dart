import 'package:flutter/material.dart';
import 'package:jirani/data/models/community_model.dart';
import 'package:jirani/services/community_service.dart';
import 'package:jirani/services/geofence_manager.dart';
import 'package:jirani/services/location_access.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/location/geofence_checking_view.dart';
import 'package:jirani/views/location/location_permission_view.dart';
import 'package:jirani/widgets/common/jirani_modal.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 350;

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

  Future<void> _continue(AuthViewModel viewModel) async {
    if (_isContinuing) return;
    final community = _currentSelection(viewModel);
    if (community == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a community first.')),
      );
      return;
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
