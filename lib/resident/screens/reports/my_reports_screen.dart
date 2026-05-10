import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/models/report_model.dart';
import 'package:fyp_flutter_application/providers/report_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      body: uid.isEmpty
          ? const Center(child: Text('Sign in to view reports.'))
          : StreamBuilder<List<ReportModel>>(
              stream: context.read<ReportProvider>().reportsForReporter(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(snap.error.toString()));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No reports yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.title),
                        subtitle: Text('${r.type}\n${r.description}\nStatus: ${r.status}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
