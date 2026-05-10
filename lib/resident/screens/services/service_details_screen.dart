import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/service_model.dart';
import 'package:fyp_flutter_application/resident/screens/services/service_request_form_screen.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({super.key, required this.service});

  final ServiceModel service;

  static String _priceLine(ServiceModel s) {
    if (s.priceType == AppConstants.servicePriceTypeFree) return 'Free';
    if (s.priceAmount != null) return '${s.priceType}: ${s.priceAmount}';
    return s.priceType;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().currentUser?.uid ?? '';
    final isOwner = uid == service.providerId;
    final verified = context.watch<AuthViewModel>().currentUser?.isVerifiedResident ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(service.providerName, style: Theme.of(context).textTheme.titleMedium),
          Text(service.providerEmail),
          const SizedBox(height: 12),
          Text('Category: ${service.category}'),
          Text('Price: ${_priceLine(service)}'),
          Text('Availability: ${service.availability}'),
          Text('Status: ${service.status}'),
          const SizedBox(height: 12),
          Text(service.description),
          const SizedBox(height: 24),
          if (!isOwner && verified && service.status == AppConstants.serviceStatusActive)
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceRequestFormScreen(service: service),
                  ),
                );
              },
              child: const Text('Request this service'),
            ),
          if (!verified && !isOwner)
            const Text('Verify your residency to request services.'),
        ],
      ),
    );
  }
}
