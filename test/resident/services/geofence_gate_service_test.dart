// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : geofence_gate_service_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/services/geofence_gate_service.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  group('GeofenceGateService permission behavior', () {
    test('passive access check never requests location permission', () async {
      final gateway = _FakeLocationGateway(
        permission: LocationPermission.denied,
      );
      final service = GeofenceGateService(locationGateway: gateway);

      final result = await service.checkResidentAccess(_resident());

      expect(result.blockReason, GeofenceGateBlockReason.permissionDenied);
      expect(gateway.checkCount, 1);
      expect(gateway.requestCount, 0);
      expect(gateway.positionCount, 0);
    });

    test('explicit request reports permanently denied', () async {
      final gateway = _FakeLocationGateway(
        permission: LocationPermission.denied,
        requestedPermission: LocationPermission.deniedForever,
      );
      final service = GeofenceGateService(locationGateway: gateway);

      final result = await service.requestForegroundLocationPermission();

      expect(
        result.blockReason,
        GeofenceGateBlockReason.permissionDeniedForever,
      );
      expect(gateway.requestCount, 1);
    });

    test(
      'disabled location service is terminal and does not request',
      () async {
        final gateway = _FakeLocationGateway(
          serviceEnabled: false,
          permission: LocationPermission.denied,
        );
        final service = GeofenceGateService(locationGateway: gateway);

        final result = await service.requestForegroundLocationPermission();

        expect(result.blockReason, GeofenceGateBlockReason.locationServicesOff);
        expect(gateway.requestCount, 0);
      },
    );
  });
}

class _FakeLocationGateway implements GeofenceLocationGateway {
  _FakeLocationGateway({
    this.serviceEnabled = true,
    required this.permission,
    LocationPermission? requestedPermission,
  }) : requestedPermission = requestedPermission ?? permission;

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission requestedPermission;
  int checkCount = 0;
  int requestCount = 0;
  int positionCount = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    checkCount += 1;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition() async {
    positionCount += 1;
    throw UnimplementedError();
  }

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCount += 1;
    return requestedPermission;
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
