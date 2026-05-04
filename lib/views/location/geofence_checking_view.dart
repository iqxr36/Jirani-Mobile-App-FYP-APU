import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fyp_flutter_application/views/verification/verification_intro_view.dart';

/// Placeholder screen while acquiring a fix. Real geofence bounds come in Phase 2B.
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
      // TODO Phase 2B: compare user location with community latitude/longitude/radius.
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VerificationIntroView()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
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
                  'Boundary checks will be enabled in a future update.',
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
                    MaterialPageRoute<void>(builder: (_) => const VerificationIntroView()),
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
