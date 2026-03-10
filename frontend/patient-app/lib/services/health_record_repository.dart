import '../models/health_record.dart';
import '../services/api_service.dart';

class HealthRecordRepository {

  static final List<HealthRecord> _records = [];

  /// Load records from backend
  static Future<void> loadFromServer() async {

    try {

      final data = await ApiService.getMyRecords();

      _records.clear();

      for (var r in data) {

        _records.add(
          HealthRecord(
            id: r["id"] ?? "",
            category: r["category"] ?? "",
            type: r["type"] ?? "",
            domain: r["domain"] ?? "",
            value: r["value"]?.toString() ?? "",
            unit: r["unit"] ?? "",
            source: r["source"] ?? "server",
            timestamp: DateTime.tryParse(r["timestamp"] ?? "") ?? DateTime.now(),
            recordName: r["recordName"],
          ),
        );

      }

    } catch (e) {

      print("LOAD SERVER RECORD ERROR: $e");

    }

  }

  /// Add record locally
  static void addRecord(HealthRecord record) {
    _records.add(record);
  }

  /// Get all records
  static List<HealthRecord> getAllRecords() {
    return _records;
  }

  /// Filter by domain
  static List<HealthRecord> getRecordsByDomain(String domain) {

    return _records
        .where((r) => r.domain == domain)
        .toList();

  }

  /// Filter by domain + year
  static List<HealthRecord> getRecordsByDomainAndYear(
      String domain,
      int year
  ){

    return _records.where((r) =>
        r.domain == domain &&
        r.timestamp.year == year
    ).toList();

  }

  /// Filter by type + date range
  static List<HealthRecord> getRecordsByTypeAndRange(
      String type,
      DateTime startDate
  ) {

    return _records.where((r) =>
        r.type == type &&
        r.timestamp.isAfter(startDate)
    ).toList();

  }

}