part of '../resident_profile_view.dart';

class _VerificationStatus {
  const _VerificationStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _VerificationStatus.from(String? status) {
    switch (status) {
      case 'verified':
        return const _VerificationStatus(
          label: 'Verified',
          color: Color(0xFF34C759),
          icon: Icons.check_rounded,
        );
      case 'submitted':
        return const _VerificationStatus(
          label: 'In Review',
          color: Color(0xFFFFB020),
          icon: Icons.hourglass_bottom_rounded,
        );
      case 'rejected':
        return const _VerificationStatus(
          label: 'Rejected',
          color: Color(0xFFE5484D),
          icon: Icons.priority_high_rounded,
        );
      default:
        return const _VerificationStatus(
          label: 'Pending',
          color: _kBrandTeal,
          icon: Icons.lock_outline_rounded,
        );
    }
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.status});

  final _VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 4, right: 9),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: status.color.withValues(alpha: 0.22),
            child: Icon(status.icon, size: 11, color: status.color),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityVerificationPanel extends StatelessWidget {
  const _IdentityVerificationPanel({
    required this.user,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
  });

  final AppUser? user;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = user?.email.trim() ?? '';
    final pendingEmail = user?.pendingEmail.trim() ?? '';
    final phone = user?.phoneNumber.trim() ?? '';
    final emailValue = user?.hasPendingEmailChange == true
        ? '$email\nPending confirmation: $pendingEmail'
        : (email.isEmpty ? 'No email saved' : email);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.68)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _IdentityVerificationRow(
            icon: Icons.mark_email_read_outlined,
            title: 'Email Address',
            value: emailValue,
            verified: user?.emailVerified ?? false,
            actionLabel: 'Verify now',
            onTap: onVerifyEmail,
          ),
          Divider(
            height: 14,
            color: isDark
                ? scheme.outlineVariant
                : Colors.black.withValues(alpha: 0.08),
          ),
          _IdentityVerificationRow(
            icon: Icons.sms_outlined,
            title: 'Phone Number',
            value: phone.isEmpty ? 'No phone saved' : phone,
            verified: user?.phoneVerified ?? false,
            actionLabel: phone.isEmpty ? 'Add first' : 'Verify now',
            onTap: onVerifyPhone,
          ),
        ],
      ),
    );
  }
}

class _IdentityVerificationRow extends StatelessWidget {
  const _IdentityVerificationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.verified,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool verified;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = verified ? const Color(0xFF34C759) : _kBrandTeal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: verified ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'Verified' : actionLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
