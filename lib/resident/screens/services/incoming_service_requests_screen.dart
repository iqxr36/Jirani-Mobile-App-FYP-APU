import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/service_request_model.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class IncomingServiceRequestsScreen extends StatelessWidget {
  const IncomingServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incoming service requests')),
        body: const Center(child: Text('Sign in to view requests.')),
      );
    }

    final stream = context.read<ServiceProvider>().incomingRequestsStream(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming service requests')),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!.where((r) => r.providerId == uid).toList();
          if (list.isEmpty) {
            return const Center(child: Text('No incoming requests.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.serviceTitle, style: Theme.of(context).textTheme.titleSmall),
                      Text('From: ${r.requesterName}'),
                      Text('Status: ${r.status}'),
                      Text(r.message),
                      if (r.status == AppConstants.serviceRequestStatusPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () async => _accept(context, r.id, uid),
                              child: const Text('Accept'),
                            ),
                            TextButton(
                              onPressed: () async => _reject(context, r.id, uid),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                      if (r.status == AppConstants.serviceRequestStatusAccepted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.tonal(
                            onPressed: () async => _complete(context, r.id, uid),
                            child: const Text('Mark completed'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Future<void> _accept(BuildContext context, String requestId, String providerId) async {
    final p = context.read<ServiceProvider>();
    try {
      await p.acceptServiceRequest(requestId: requestId, providerId: providerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  static Future<void> _reject(BuildContext context, String requestId, String providerId) async {
    final p = context.read<ServiceProvider>();
    try {
      await p.rejectServiceRequest(requestId: requestId, providerId: providerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  static Future<void> _complete(BuildContext context, String requestId, String providerId) async {
    final p = context.read<ServiceProvider>();
    try {
      await p.completeServiceRequest(requestId: requestId, providerId: providerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked completed.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}
