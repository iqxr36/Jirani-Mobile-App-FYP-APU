import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/providers/borrow_request_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrow_request_card.dart';
import 'package:provider/provider.dart';

import 'lender_request_review_screen.dart';

class IncomingBorrowRequestsScreen extends StatefulWidget {
  const IncomingBorrowRequestsScreen({super.key});

  @override
  State<IncomingBorrowRequestsScreen> createState() => _IncomingBorrowRequestsScreenState();
}

class _IncomingBorrowRequestsScreenState extends State<IncomingBorrowRequestsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>().currentUser;
      if (auth != null) {
        context.read<BorrowRequestProvider>().watchIncomingRequests(auth.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>().currentUser;
    final vm = context.watch<BorrowRequestProvider>();
    final data = vm.incomingRequests.where((r) => _filter == 'all' || r.status == _filter).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
      body: auth == null
          ? const Center(child: Text('Please sign in again.'))
          : Column(
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _filters
                      .map(
                        (f) => ChoiceChip(
                          label: Text(_chipLabel(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : data.isEmpty
                          ? const Center(child: Text('No incoming requests.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: data.length,
                              itemBuilder: (_, i) {
                                final request = data[i];
                                return BorrowRequestCard(
                                  request: request,
                                  showBorrower: true,
                                  onViewDetails: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LenderRequestReviewScreen(request: request),
                                      ),
                                    );
                                  },
                                  onReview: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LenderRequestReviewScreen(request: request),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  static const _filters = <String>[
    AppConstants.borrowStatusPending,
    AppConstants.borrowStatusApproved,
    AppConstants.borrowStatusPickupReady,
    AppConstants.borrowStatusActive,
    AppConstants.borrowStatusReturnSubmitted,
    AppConstants.borrowStatusCompleted,
    AppConstants.borrowStatusRejected,
    AppConstants.borrowStatusCancelled,
    'all',
  ];

  static String _chipLabel(String value) {
    const map = <String, String>{
      AppConstants.borrowStatusPending: 'Pending',
      AppConstants.borrowStatusApproved: 'Approved',
      AppConstants.borrowStatusPickupReady: 'Pickup ready',
      AppConstants.borrowStatusActive: 'Active',
      AppConstants.borrowStatusReturnSubmitted: 'Return sent',
      AppConstants.borrowStatusCompleted: 'Completed',
      AppConstants.borrowStatusRejected: 'Rejected',
      AppConstants.borrowStatusCancelled: 'Cancelled',
      'all': 'All',
    };
    return map[value] ?? value;
  }
}
