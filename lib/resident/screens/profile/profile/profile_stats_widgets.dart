// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : profile_stats_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_profile_view.dart';

class _ProfileMarketplaceCounts {
  const _ProfileMarketplaceCounts({
    required this.borrowed,
    required this.lent,
  });

  final int borrowed;
  final int lent;
}

class _ProfileStatsBuilder extends StatelessWidget {
  const _ProfileStatsBuilder({
    required this.user,
    required this.builder,
  });

  final AppUser? user;
  final Widget Function(BuildContext context, _ProfileMarketplaceCounts? counts)
  builder;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) return builder(context, null);

    final requests = FirebaseFirestore.instance.collection(
      AppConstants.borrowRequestsCollection,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: requests
          .where('borrowerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: AppConstants.borrowStatusCompleted)
          .snapshots(),
      builder: (context, borrowedSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: requests
              .where('ownerId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: AppConstants.borrowStatusCompleted)
              .snapshots(),
          builder: (context, lentSnapshot) {
            final liveCountsAvailable =
                borrowedSnapshot.hasData && lentSnapshot.hasData;
            final counts = liveCountsAvailable
                ? _ProfileMarketplaceCounts(
                    borrowed: borrowedSnapshot.data!.docs.length,
                    lent: lentSnapshot.data!.docs.length,
                  )
                : _ProfileMarketplaceCounts(
                    borrowed: currentUser.completedBorrowings,
                    lent: currentUser.completedLendings,
                  );
            return builder(context, counts);
          },
        );
      },
    );
  }
}
