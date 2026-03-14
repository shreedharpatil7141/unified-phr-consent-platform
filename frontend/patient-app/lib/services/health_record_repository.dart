import '../models/health_record.dart';
import '../services/api_service.dart';
import '../utils/server_time.dart';

class HealthRecordRepository {

  static final List<HealthRecord> _records = [];
  static final List<HealthRecord> _watchRecords = [];

  static String _normalizeType(String type) {
    return type.toLowerCase().replaceAll(" ", "_");
  }

  static Set<String> _typeAliases(String type) {
    final normalized = _normalizeType(type);
    if (normalized == "heart_rate" || normalized == "pulse_rate") {
      return {"heart_rate", "pulse_rate"};
    }
    return {normalized};
  }

  static bool _isLocalWatchSource(String source) {
    final normalized = source.toLowerCase();
    return normalized == "smartwatch";
  }

  static List<HealthRecord> _mergedDeduplicatedRecords() {
    final merged = [..._records, ..._watchRecords];
    final byKey = <String, HealthRecord>{};

    for (final record in merged) {
      final value = double.tryParse(record.value);
      final normalizedValue = value?.toStringAsFixed(3) ?? record.value;
      final key =
          "${_normalizeType(record.type)}|${record.timestamp.toIso8601String()}|$normalizedValue";

      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = record;
        continue;
      }

      // Prefer backend copy over local watch copy when the same sample exists in both.
      if (_isLocalWatchSource(existing.source) && !_isLocalWatchSource(record.source)) {
        byKey[key] = record;
      }
    }

    return byKey.values.toList();
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
            timestamp: parseServerTime(r["timestamp"]) ?? DateTime.now(),
            filePath: ApiService.resolveFileUrl(r["file_url"]),
            recordName: r["record_name"],
            doctorName: r["doctor"],
            hospitalName: r["hospital"],
            previousValue: r["previous_value"]?.toString(),
            changeDirection: r["change_direction"]?.toString(),
            delta: (r["delta"] is num) ? (r["delta"] as num).toDouble() : double.tryParse("${r["delta"] ?? ""}"),
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
    return _mergedDeduplicatedRecords();
  }

  /// Filter by domain
  static List<HealthRecord> getRecordsByDomain(String domain) {

    return _mergedDeduplicatedRecords()
        .where((r) => r.domain == domain)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  }

  /// Filter by domain + year
  static List<HealthRecord> getRecordsByDomainAndYear(
      String domain,
      int year
  ){

    return _mergedDeduplicatedRecords().where((r) =>
        r.domain == domain &&
        r.timestamp.year == year
    ).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  }

  /// Filter by type + date range
  static List<HealthRecord> getRecordsByTypeAndRange(
      String type,
      DateTime startDate
  ) {
    final acceptedTypes = _typeAliases(type);

    return _mergedDeduplicatedRecords().where((r) =>
        acceptedTypes.contains(_normalizeType(r.type)) &&
        !r.timestamp.isBefore(startDate)
    ).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  }

}
