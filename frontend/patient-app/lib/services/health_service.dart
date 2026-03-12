import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {

  final Health health = Health();

  Future<List<HealthDataPoint>> getHealthData({DateTime? startTime}) async {
    await health.configure();

    await Permission.activityRecognition.request();
    await Permission.sensors.request();

    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
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
      HealthDataAccess.READ,
    ];

    bool? hasPermissions = await health.hasPermissions(
      types,
      permissions: permissions,
    );

    bool requested = hasPermissions == true;
    if (!requested) {
      requested = await health.requestAuthorization(
        types,
        permissions: permissions,
      );
    }

    if (requested) {

      DateTime now = DateTime.now();
      DateTime recentWindow = startTime ?? now.subtract(const Duration(days: 365));

      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        startTime: recentWindow,
        endTime: now,
        types: types,
      );

      return health.removeDuplicates(data);
    }

    return [];
  }
}
