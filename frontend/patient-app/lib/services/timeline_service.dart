import '../models/health_record.dart';
import 'health_record_repository.dart';

class TimelineService {

  static List<HealthRecord> getTimeline() {

    final records = HealthRecordRepository.getAllRecords();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return records;
  }

}