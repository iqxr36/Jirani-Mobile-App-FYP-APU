import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';

class BorrowerMiniCard extends StatelessWidget {
  const BorrowerMiniCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.isVerified,
    required this.reputation,
  });

  final String name;
  final String email;
  final String phone;
  final bool isVerified;
  final double reputation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Row(
          children: [
            Expanded(child: Text(name)),
            if (isVerified) const VerifiedBadge(compact: true),
          ],
        ),
        subtitle: Text('$email\n$phone\nReputation: ${reputation.toStringAsFixed(1)}'),
      ),
    );
  }
}
