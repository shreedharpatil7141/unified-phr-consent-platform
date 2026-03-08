class HealthRecord {

  final String id;
  final String category;
  final String type;
  final String domain; // NEW

  final String value;
  final String unit;
  final String source;
  final DateTime timestamp;
  final String? filePath;

  final String? recordName;
  final String? doctorName;
  final String? hospitalName;

  String? previousValue;

  HealthRecord({
    required this.id,
    required this.category,
    required this.type,
    required this.domain,
    required this.value,
    required this.unit,
    required this.source,
    required this.timestamp,
    this.filePath,
    this.recordName,
    this.doctorName,
    this.hospitalName,
    this.previousValue,
  });

}