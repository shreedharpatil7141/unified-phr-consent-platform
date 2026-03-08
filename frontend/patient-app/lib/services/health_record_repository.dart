import '../models/health_record.dart';

class HealthRecordRepository {

  static final List<HealthRecord> _records = [];

  static void addRecord(HealthRecord record) {
  _records.add(record);
}

  static List<HealthRecord> getAllRecords() {
    return _records;
  }

  /// NEW: filter by domain
  static List<HealthRecord> getRecordsByDomain(String domain) {

    return _records
        .where((r) => r.domain == domain)
        .toList();
  }

  /// NEW: filter by domain + year
  static List<HealthRecord> getRecordsByDomainAndYear(
      String domain,
      int year
  ){

    return _records.where((r) =>
        r.domain == domain &&
        r.timestamp.year == year
    ).toList();

  }
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