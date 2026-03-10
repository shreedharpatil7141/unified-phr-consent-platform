import 'package:health/health.dart';

class HealthService {

  final Health health = Health();

  Future<List<HealthDataPoint>> getHealthData() async {

    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_ASLEEP,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    bool requested = await health.requestAuthorization(
      types,
      permissions: permissions,
    );

    if (requested) {

      DateTime now = DateTime.now();
      DateTime oneYearAgo = now.subtract(const Duration(days: 365));

      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        startTime: oneYearAgo,
        endTime: now,
        types: types,
      );

      return data;
    }

    return [];
  }
}