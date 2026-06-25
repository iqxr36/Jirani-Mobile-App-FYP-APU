part of '../register_view.dart';

class _CommunityModalMessage extends StatelessWidget {
  const _CommunityModalMessage({
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
          Icon(icon, color: _kBrandTeal, size: 38),
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
              color: Colors.black.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _kBrandTeal,
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

Widget _buildRegisterCommunityPicker({
  required BuildContext context,
  required bool enabled,
  required bool communitiesLoading,
  required String? communitiesError,
  required List<CommunityModel> activeCommunities,
  required CommunityModel? selectedCommunity,
  required VoidCallback onSelectCommunity,
}) {
  final hasOptions = activeCommunities.isNotEmpty;
  final canSelect = enabled;
  final selectedName = selectedCommunity?.name;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Community / Residence', style: _registerLabelStyle(context)),
      const SizedBox(height: 6),
      if (communitiesLoading)
        const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSelect ? onSelectCommunity : null,
            borderRadius: BorderRadius.circular(_kFieldRadius),
            child: InputDecorator(
              decoration: _registerInputDecoration(
                context,
                hint: hasOptions
                    ? 'Select your community'
                    : 'No active communities available',
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              isEmpty: selectedName == null || selectedName.isEmpty,
              child: Text(
                selectedName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: canSelect ? context.appInk : context.appMuted,
                ),
              ),
            ),
          ),
        ),
      if (communitiesError != null || !hasOptions && !communitiesLoading)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            communitiesError ??
                'You can select a community during location verification.',
            style: TextStyle(fontSize: 11, color: context.appMuted),
          ),
        ),
    ],
  );
}
