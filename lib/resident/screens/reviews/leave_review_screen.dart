import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';
import 'package:fyp_flutter_application/providers/review_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class LeaveReviewScreen extends StatefulWidget {
  const LeaveReviewScreen({
    super.key,
    required this.borrowRequest,
    required this.role,
  });

  final BorrowRequest borrowRequest;
  /// [AppConstants.reviewRoleBorrowerToOwner] or [AppConstants.reviewRoleOwnerToBorrower]
  final String role;

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>().currentUser;
    if (auth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user profile. Please sign in again.')),
      );
      return;
    }
    final review = context.read<ReviewProvider>();
    try {
      await review.createReview(
        borrowRequest: widget.borrowRequest,
        reviewerId: auth.uid,
        reviewerName: auth.fullName,
        role: widget.role,
        rating: _rating,
        comment: _commentCtrl.text,
      );
      await context.read<AuthViewModel>().refreshCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewBusy = context.watch<ReviewProvider>().isSubmitting;
    final target = widget.role == AppConstants.reviewRoleBorrowerToOwner
        ? widget.borrowRequest.ownerName
        : widget.borrowRequest.borrowerName;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rate $target', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: reviewBusy ? null : () => setState(() => _rating = star),
                icon: Icon(star <= _rating ? Icons.star : Icons.star_border),
              );
            }),
          ),
          Text('Rating: $_rating / 5'),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: reviewBusy ? null : _submit,
            child: reviewBusy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
