import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/service_request_model.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class MyServiceRequestsScreen extends StatelessWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My service requests')),
        body: const Center(child: Text('Sign in to view requests.')),
      );
    }

    final stream = context.read<ServiceProvider>().myRequestsStream(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My service requests')),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No requests yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                child: ListTile(
                  title: Text(r.serviceTitle),
                  subtitle: Text(
                    '${r.providerName}\n${r.message}\nStatus: ${r.status}',
                  ),
                  isThreeLine: true,
                  trailing: r.status == AppConstants.serviceRequestStatusPending
                      ? TextButton(
                          onPressed: () async {
                            final p = context.read<ServiceProvider>();
                            try {
                              await p.cancelServiceRequest(requestId: r.id, requesterId: uid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                );
                              }
                            }
                          },
                          child: const Text('Cancel'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
