import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/service_model.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/resident/screens/services/service_details_screen.dart';
import 'package:provider/provider.dart';

class ServicesBrowseScreen extends StatelessWidget {
  const ServicesBrowseScreen({super.key});

  static String _priceLabel(ServiceModel s) {
    if (s.priceType == AppConstants.servicePriceTypeFree) return 'Free';
    if (s.priceAmount != null) return '${s.priceType}: ${s.priceAmount}';
    return s.priceType;
  }

  @override
  Widget build(BuildContext context) {
    final stream = context.read<ServiceProvider>().activeServicesStream();

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
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
            return const Center(child: Text('No active services listed.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  title: Text(s.title),
                  subtitle: Text('${s.category} · ${_priceLabel(s)}\n${s.providerName}'),
                  isThreeLine: true,
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
