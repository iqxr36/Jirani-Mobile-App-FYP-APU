// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : profile_display_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_profile_view.dart';

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surface.withValues(alpha: 0.72)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustedResidentBadge extends StatelessWidget {
  const _TrustedResidentBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkUi
            ? scheme.tertiaryContainer.withValues(alpha: 0.72)
            : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.isDarkUi ? scheme.tertiary : const Color(0xFFFFC857),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 16,
            color: context.isDarkUi
                ? scheme.onTertiaryContainer
                : const Color(0xFF9A6700),
          ),
          const SizedBox(width: 6),
          Text(
            'Trusted Resident',
            style: TextStyle(
              color: context.isDarkUi
                  ? scheme.onTertiaryContainer
                  : const Color(0xFF7A5200),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.onTap,
    required this.isLoading,
  });

  final AppUser? user;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = user?.profileImageUrl.trim() ?? '';

    return Semantics(
      button: onTap != null,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.avatarPlaceholder,
                    border: Border.all(
                      color: scheme.surface.withValues(alpha: 0.9),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kBrandTeal.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: _kBrandTeal,
                            size: 62,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_outline_rounded,
                              color: _kBrandTeal,
                              size: 62,
                            ),
                          ),
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.34),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kBrandTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color == Colors.black ? scheme.onSurface : color;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: effectiveColor),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: effectiveColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 32,
                    color: effectiveColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1.5,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}
