part of '../resident_profile_view.dart';

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.marketplaceCounts,
    required this.onEditProfile,
    required this.onChangePhoto,
    required this.isPhotoUpdating,
    required this.onVerificationStatus,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
    required this.onMyItems,
    required this.onRatings,
    required this.onMyServices,
    required this.onSettings,
    required this.onLogout,
  });

  final AppUser? user;
  final _ProfileMarketplaceCounts? marketplaceCounts;
  final VoidCallback onEditProfile;
  final VoidCallback? onChangePhoto;
  final bool isPhotoUpdating;
  final VoidCallback onVerificationStatus;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;
  final VoidCallback onMyItems;
  final VoidCallback onRatings;
  final VoidCallback onMyServices;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Neighbor';
    final community = user?.communityName.trim().isNotEmpty == true
        ? user!.communityName.trim().toUpperCase()
        : 'COMMUNITY';
    final unit = user?.unitNumber.trim().isNotEmpty == true
        ? user!.unitNumber.trim()
        : '-';
    final status = _VerificationStatus.from(user?.verificationStatus);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.90)
            : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _VerificationChip(status: status),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _ProfileAvatar(
                  user: user,
                  onTap: onChangePhoto,
                  isLoading: isPhotoUpdating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    community,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                Flexible(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (user?.trustedResident == true) ...[
            const SizedBox(height: 10),
            const _TrustedResidentBadge(),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricChip(
                value: user == null || (user?.totalReviews ?? 0) == 0
                    ? '-'
                    : user!.communityTrustScore.toStringAsFixed(1),
                label: 'Trust',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                value: '${marketplaceCounts?.borrowed ?? 0}',
                label: 'Borrowed',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                value: '${marketplaceCounts?.lent ?? 0}',
                label: 'Lent',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                value: '${user?.totalReviews ?? 0}',
                label: 'Reviews',
              ),
            ],
          ),
          const SizedBox(height: 17),
          _IdentityVerificationPanel(
            user: user,
            onVerifyEmail: onVerifyEmail,
            onVerifyPhone: onVerifyPhone,
          ),
          const SizedBox(height: 17),
          Divider(
            height: 1,
            thickness: 2,
            color: isDark
                ? scheme.outlineVariant
                : Colors.black.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 17),
          _ProfileMenuRow(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: onEditProfile,
          ),
          _ProfileMenuRow(
            icon: Icons.verified_user_outlined,
            label: 'Verification Status',
            onTap: onVerificationStatus,
          ),
          _ProfileMenuRow(
            icon: Icons.inventory_2_outlined,
            label: 'My Items',
            onTap: onMyItems,
          ),
          _ProfileMenuRow(
            icon: Icons.star_border_rounded,
            label: 'Ratings & Reviews',
            onTap: onRatings,
          ),
          _ProfileMenuRow(
            icon: Icons.article_outlined,
            label: 'My Services',
            onTap: onMyServices,
          ),
          _ProfileMenuRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: onSettings,
          ),
          _ProfileMenuRow(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: const Color(0xFFB00020),
            onTap: onLogout,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
