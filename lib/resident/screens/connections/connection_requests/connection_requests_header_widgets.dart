// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : connection_requests_header_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_connection_requests_view.dart';

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader();

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
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 32,
              ),
            ),
          ),
          const Text(
            'Connection Requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxWidth: 286),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: context.glassFill(lightAlpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBrandTeal.withValues(alpha: 0.12)),
          boxShadow: context.softSurfaceShadow(lightOpacity: 0.13, blurRadius: 18, dy: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: context.appInk,
              size: 20,
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.76),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.glassBorder()),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.08, blurRadius: 16, dy: 8),
      ),
      child: Row(
        children: [
          _TabPill(
            label: 'Connection Requests',
            selected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          const SizedBox(width: 4),
          _TabPill(
            label: 'My Neighbors',
            selected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? _kBrandTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? context.softSurfaceShadow(
                        lightOpacity: 0.16,
                        blurRadius: 12,
                        dy: 5,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? onPrimary : context.appMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
    required this.isLoading,
    required this.errorMessage,
    required this.requestCount,
    required this.neighborCount,
  });

  final bool isLoading;
  final String? errorMessage;
  final int requestCount;
  final int neighborCount;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final icon = hasError
        ? Icons.info_outline_rounded
        : isLoading
        ? Icons.sync_rounded
        : Icons.verified_user_outlined;
    final message = hasError
        ? errorMessage!
        : isLoading
        ? 'Syncing your latest connection updates...'
        : '$neighborCount connected neighbor${neighborCount == 1 ? '' : 's'} · $requestCount pending request${requestCount == 1 ? '' : 's'}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF4E5)
            : _kBrandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? const Color(0xFFE29578).withValues(alpha: 0.34)
              : _kBrandTeal.withValues(alpha: 0.16),
        ),
        boxShadow: context.softSurfaceShadow(lightOpacity: 0.05, blurRadius: 14, dy: 6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasError ? const Color(0xFFB45309) : _kBrandTeal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: hasError ? const Color(0xFF92400E) : _kBrandTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
