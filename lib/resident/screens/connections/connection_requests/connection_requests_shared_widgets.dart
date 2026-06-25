part of '../resident_connection_requests_view.dart';

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: context.avatarPlaceholder,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: _kBrandTeal,
        size: 40,
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFF34C759),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
    );
  }
}

class _NoRequestsState extends StatelessWidget {
  const _NoRequestsState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyStateCard(
      icon: Icons.mark_email_read_outlined,
      title: 'No pending requests',
      message:
          'New connection requests from verified neighbors will appear here.',
    );
  }
}

class _NoNeighborsState extends StatelessWidget {
  const _NoNeighborsState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyStateCard(
      icon: Icons.group_outlined,
      title: 'No neighbors yet',
      message: 'Neighbors you connect with will appear here.',
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.93),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.08, blurRadius: 20, dy: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kBrandTeal, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: context.appInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
