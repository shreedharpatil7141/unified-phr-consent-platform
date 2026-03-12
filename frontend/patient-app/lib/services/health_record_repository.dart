import '../models/health_record.dart';
import '../services/api_service.dart';

class HealthRecordRepository {

  static final List<HealthRecord> _records = [];
  static final List<HealthRecord> _watchRecords = [];

  static String _normalizeType(String type) {
    return type.toLowerCase().replaceAll(" ", "_");
  }

  /// Load records from backend
  static Future<void> loadFromServer() async {

    try {

      final data = await ApiService.getMyRecords();

      _records.clear();

      for (var r in data) {

        _records.add(
          HealthRecord(
            id: r["record_id"] ?? "",
            category: r["normalized_category"] ?? r["category"] ?? "",
            type: r["normalized_record_type"] ?? r["record_type"] ?? "",
            domain: r["normalized_domain"] ?? r["domain"] ?? "",
            value: r["value"]?.toString() ?? "",
            unit: r["unit"] ?? "",
            source: r["normalized_source"] ?? r["source"] ?? "server",
            timestamp: DateTime.tryParse(r["timestamp"] ?? "") ?? DateTime.now(),
            filePath: ApiService.resolveFileUrl(r["file_url"]),
            recordName: r["record_name"],
            doctorName: r["doctor"],
            hospitalName: r["hospital"],
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

  static void setWatchRecords(List<HealthRecord> records) {
    _watchRecords
      ..clear()
      ..addAll(records);
  }

  static void removeRecord(String recordId) {
    _records.removeWhere((record) => record.id == recordId);
    _watchRecords.removeWhere((record) => record.id == recordId);
  }

  /// Get all records
  static List<HealthRecord> getAllRecords() {
    return [..._records, ..._watchRecords];
  }

  /// Filter by domain
  static List<HealthRecord> getRecordsByDomain(String domain) {

    return _records
        .followedBy(_watchRecords)
        .where((r) => r.domain == domain)
        .toList();

  }

  /// Filter by domain + year
  static List<HealthRecord> getRecordsByDomainAndYear(
      String domain,
      int year
  ){

    return _records.followedBy(_watchRecords).where((r) =>
        r.domain == domain &&
        r.timestamp.year == year
    ).toList();

  }

  /// Filter by type + date range
  static List<HealthRecord> getRecordsByTypeAndRange(
      String type,
      DateTime startDate
  ) {
    final normalizedType = _normalizeType(type);

    return _records.followedBy(_watchRecords).where((r) =>
        _normalizeType(r.type) == normalizedType &&
        r.timestamp.isAfter(startDate)
    ).toList();

  }

}
