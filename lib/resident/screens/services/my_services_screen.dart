import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/service_model.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/resident/screens/services/add_service_screen.dart';
import 'package:fyp_flutter_application/resident/screens/services/service_details_screen.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My services')),
        body: const Center(child: Text('Sign in to manage services.')),
      );
    }

    final stream = context.read<ServiceProvider>().myServicesStream(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddServiceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ServiceModel>>(
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
            return const Center(child: Text('You have no services yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  title: Text(s.title),
                  subtitle: Text('${s.category} · ${s.status}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      final p = context.read<ServiceProvider>();
                      try {
                        await p.setServiceStatus(serviceId: s.id, providerId: uid, status: v);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: $v')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: AppConstants.serviceStatusActive, child: const Text('Active')),
                      PopupMenuItem(value: AppConstants.serviceStatusInactive, child: const Text('Inactive')),
                      PopupMenuItem(value: AppConstants.serviceStatusArchived, child: const Text('Archived')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ServiceDetailsScreen(service: s)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
