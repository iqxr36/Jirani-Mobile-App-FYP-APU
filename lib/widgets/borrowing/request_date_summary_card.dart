import 'package:flutter/material.dart';

class RequestDateSummaryCard extends StatelessWidget {
  const RequestDateSummaryCard({
    super.key,
    required this.requestedStartDate,
    required this.expectedReturnDate,
    required this.pickupTime,
  });

  final DateTime requestedStartDate;
  final DateTime expectedReturnDate;
  final String pickupTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request schedule', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Start: ${_fmtDate(requestedStartDate)}'),
            Text('Return: ${_fmtDate(expectedReturnDate)}'),
            Text('Pickup time: $pickupTime'),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
