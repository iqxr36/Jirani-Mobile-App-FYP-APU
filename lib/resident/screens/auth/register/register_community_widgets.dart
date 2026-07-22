// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : register_community_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

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
  required bool enabled,
  required bool communitiesLoading,
  required String? communitiesError,
  required List<CommunityModel> activeCommunities,
  required CommunityModel? selectedCommunity,
  required VoidCallback onSelectCommunity,
}) {
  return ResidentCommunityPicker(
    enabled: enabled,
    communitiesLoading: communitiesLoading,
    communitiesError: communitiesError,
    activeCommunities: activeCommunities,
    selectedCommunity: selectedCommunity,
    onSelectCommunity: onSelectCommunity,
  );
}
