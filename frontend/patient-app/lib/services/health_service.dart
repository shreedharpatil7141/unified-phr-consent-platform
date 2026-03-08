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

    bool requested = await health.requestAuthorization(types);

    if (requested) {

      DateTime now = DateTime.now();
      DateTime oneYearAgo = now.subtract(const Duration(days: 365));

      List<HealthDataPoint> data =
          await health.getHealthDataFromTypes(
        types: types,
        startTime: oneYearAgo,
        endTime: now,
      );

      return data;

    }

    return [];
  }
}