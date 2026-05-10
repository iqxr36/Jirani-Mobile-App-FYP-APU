import 'package:flutter/material.dart';

class FeeDepositSummaryCard extends StatelessWidget {
  const FeeDepositSummaryCard({
    super.key,
    required this.hasUsageFee,
    required this.usageFeeAmount,
    required this.hasDeposit,
    required this.depositAmount,
  });

  final bool hasUsageFee;
  final double? usageFeeAmount;
  final bool hasDeposit;
  final double? depositAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lending terms', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hasUsageFee && (usageFeeAmount ?? 0) > 0
                  ? 'Usage fee: RM ${_fmt(usageFeeAmount!)}'
                  : 'Usage fee: Not required',
            ),
            const SizedBox(height: 4),
            Text(
              hasDeposit && (depositAmount ?? 0) > 0
                  ? 'Refundable deposit: RM ${_fmt(depositAmount!)}'
                  : 'Refundable deposit: Not required',
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
