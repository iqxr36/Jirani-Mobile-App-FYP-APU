import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/screens/location/resident_geofence_gate.dart';
import 'package:jirani/resident/services/geofence_gate_service.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  testWidgets('shows a stable permission screen when location is denied', (
    tester,
  ) async {
    final gateway = _DeniedLocationGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: ResidentGeofenceGate(
          user: _resident(),
          gateService: GeofenceGateService(locationGateway: gateway),
          child: const Text('Protected resident content'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Location Permission Needed'), findsOneWidget);
    expect(find.text('Allow Location'), findsOneWidget);
    expect(find.text('Protected resident content'), findsNothing);
    expect(gateway.requestCount, 0);
  });
}

class _DeniedLocationGateway implements GeofenceLocationGateway {
  int requestCount = 0;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<Position> getCurrentPosition() => throw UnimplementedError();

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCount += 1;
    return LocationPermission.denied;
  }
}

AppUser _resident() {
  final now = DateTime(2026);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'resident@example.com',
    phoneNumber: '',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'Test Community',
    unitNumber: 'A-1',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: false,
    createdAt: now,
    updatedAt: now,
  );
}
