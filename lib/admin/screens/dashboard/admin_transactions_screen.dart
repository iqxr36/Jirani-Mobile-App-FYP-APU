import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final transactionRows = adminTransactionRowsFromRequests(
      admin.borrowRequests,
      admin.serviceRequests,
    );

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Transactions Monitoring',
          subtitle:
              'Audit borrow deposits, task service payments, disputes, and completion status.',
          controls: const [
            AdminFilterChipButton(label: 'Date Range'),
            AdminFilterChipButton(label: 'Type'),
            AdminFilterChipButton(label: 'Status'),
          ],
        ),
        const SizedBox(height: 20),
        AdminPanel(
          title: 'Platform Ledger',
          action: '${transactionRows.length} records',
          padding: EdgeInsets.zero,
          child: transactionRows.isEmpty
              ? const AdminEmptyPanelMessage(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions found',
                  body:
                      'Borrow and task service requests will appear here.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('Transaction ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Provider')),
                      DataColumn(label: Text('Requester')),
                      DataColumn(label: Text('Deposit')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: transactionRows
                        .map(
                          (tx) => DataRow(
                            cells: [
                              DataCell(Text(tx.id)),
                              DataCell(Text(tx.date)),
                              DataCell(Text(tx.type)),
                              DataCell(Text(tx.provider)),
                              DataCell(Text(tx.requester)),
                              DataCell(Text(tx.deposit)),
                              DataCell(
                                AdminStatusPill(
                                  label: tx.status,
                                  color: tx.color,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
