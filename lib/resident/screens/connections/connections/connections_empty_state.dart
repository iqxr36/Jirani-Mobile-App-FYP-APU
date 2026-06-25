part of '../resident_connections_view.dart';

class _EmptyConnectionsState extends StatelessWidget {
  const _EmptyConnectionsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.glassFill(lightAlpha: 0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.residentOutline(lightAlpha: 0.08)),
        boxShadow: context.softSurfaceShadow(
          lightOpacity: 0.08,
          blurRadius: 20,
          dy: 10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined, color: _kBrandTeal, size: 40),
          const SizedBox(height: 12),
          Text(
            'No connections yet',
            style: TextStyle(
              color: context.appInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Connect + on a neighbor to add them here.',
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
    );
  }
}
