import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/data/models/item_model.dart';
import 'package:fyp_flutter_application/views/marketplace/marketplace_browse_view.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrow_status_chip.dart';

import 'my_borrow_requests_screen.dart';

class BorrowRequestSentScreen extends StatelessWidget {
  const BorrowRequestSentScreen({super.key, required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Sent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.teal),
          const SizedBox(height: 10),
          const Text(
            'Your borrow request has been sent to the owner.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Center(child: BorrowStatusChip(status: 'pending')),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: item.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imageUrls.first, width: 56, height: 56, fit: BoxFit.cover),
                    )
                  : const CircleAvatar(child: Icon(Icons.image_outlined)),
              title: Text(item.title),
              subtitle: Text('Owner: ${item.ownerName}'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const MyBorrowRequestsScreen()),
                (route) => route.isFirst,
              );
            },
            child: const Text('View My Requests'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const MarketplaceBrowseView()),
                (route) => route.isFirst,
              );
            },
            child: const Text('Back to Marketplace'),
          ),
        ],
      ),
    );
  }
}
