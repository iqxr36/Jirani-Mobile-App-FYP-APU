import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fyp_flutter_application/views/location/geofence_checking_view.dart';

/// Explains location access and requests permission before the verification flow.
class LocationPermissionView extends StatefulWidget {
  const LocationPermissionView({super.key});

  @override
  State<LocationPermissionView> createState() => _LocationPermissionViewState();
}

class _LocationPermissionViewState extends State<LocationPermissionView> {
  bool _busy = false;
  String? _deniedMessage;

  Future<void> _enableLocation() async {
    setState(() {
      _busy = true;
      _deniedMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _deniedMessage = 'Location services are turned off. Please enable them in system settings.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _deniedMessage = 'Location permission is permanently denied. Open Settings to enable it.';
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _deniedMessage = 'Location permission was denied. Trust Community needs location to confirm you are within your community zone.';
        });
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const GeofenceCheckingView()),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location access')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.location_on_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Trust Community uses your location to confirm that you are inside your approved residential community zone.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.visibility_off_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your live location is not publicly shown to other residents.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // TODO Phase 2B: compare user location with community latitude/longitude/radius.
              if (_deniedMessage != null) ...[
                const SizedBox(height: 16),
                Text(_deniedMessage!, style: TextStyle(color: Colors.red.shade800)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _enableLocation,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enable Location'),
              ),
              if (_deniedMessage != null &&
                  _deniedMessage!.contains('permanently')) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => Geolocator.openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Not Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
