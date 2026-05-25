import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/notifications/notification_permission_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'outside_geofence_view.dart';

/// Acquires the user's position and verifies it against their community boundary.
class GeofenceCheckingView extends StatefulWidget {
  const GeofenceCheckingView({super.key});

  @override
  State<GeofenceCheckingView> createState() => _GeofenceCheckingViewState();
}

class _GeofenceCheckingViewState extends State<GeofenceCheckingView> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  Future<void> _runCheck() async {
    setState(() => _error = null);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final boundary = await _loadCommunityBoundary();

      if (isOutsideCommunityBoundary(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        communityLatitude: boundary.latitude,
        communityLongitude: boundary.longitude,
        radiusMeters: boundary.radiusMeters,
      )) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const OutsideGeofenceView()),
        );
        if (mounted) await _runCheck();
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const NotificationPermissionView()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<_CommunityBoundary> _loadCommunityBoundary() async {
    final user = context.read<AuthViewModel>().currentUser;
    final communityId = user?.communityId.trim() ?? '';
    final communityName = user?.communityName.trim() ?? '';
    final communities = FirebaseFirestore.instance.collection(AppConstants.communitiesCollection);

    Map<String, dynamic>? data;
    if (communityId.isNotEmpty) {
      data = (await communities.doc(communityId).get()).data();
    }
    if (data == null && communityName.isNotEmpty) {
      final named = await communities.where('name', isEqualTo: communityName).limit(1).get();
      if (named.docs.isNotEmpty) data = named.docs.first.data();
    }
    if (data == null) {
      throw Exception('Community location boundary not found.');
    }

    final latitude = _toDouble(data['latitude']);
    final longitude = _toDouble(data['longitude']);
    final radiusMeters = _toDouble(data['radius']);
    if (latitude == null || longitude == null || radiusMeters == null || radiusMeters <= 0) {
      throw Exception('Community location boundary is not configured.');
    }
    return _CommunityBoundary(latitude, longitude, radiusMeters);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checking location')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Getting your location…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Checking whether you are within your community boundary.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ] else ...[
                Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => const NotificationPermissionView()),
                  ),
                  child: const Text('Continue to verification'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityBoundary {
  const _CommunityBoundary(this.latitude, this.longitude, this.radiusMeters);

  final double latitude;
  final double longitude;
  final double radiusMeters;
}
