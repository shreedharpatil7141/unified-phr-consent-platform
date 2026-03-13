import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../services/health_record_repository.dart';

class VitalsHistoryScreen extends StatefulWidget {
  const VitalsHistoryScreen({super.key});

  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {

  List<HealthRecord> records = [];

  @override
  void initState() {
    super.initState();
    loadVitals();
  }

  void loadVitals() {

    final raw = HealthRecordRepository
        .getAllRecords()
        .where((r) => r.category == "vitals" || r.category == "wearable")
        .toList();

    final grouped = <String, List<HealthRecord>>{};
    for (final record in raw) {
      final dayKey =
          "${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}";
      final key = "${record.type}|$dayKey";
      grouped.putIfAbsent(key, () => []).add(record);
    }

    records = grouped.entries.map((entry) {
      final bucket = entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final first = bucket.first;
      final isHeart = first.type.toLowerCase().contains("heart");

      final values = bucket
          .map((item) => double.tryParse(item.value) ?? 0)
          .where((value) => value > 0)
          .toList();
      final aggregated = values.isEmpty
          ? 0
          : (isHeart
              ? values.last
              : values.reduce((a, b) => a + b) / values.length);

      return HealthRecord(
        id: "${first.type}_${first.timestamp.millisecondsSinceEpoch}",
        category: first.category,
        type: first.type,
        domain: first.domain,
        value: aggregated.toStringAsFixed(isHeart ? 0 : 2),
        unit: first.unit,
        source: first.source,
        timestamp: DateTime(
          first.timestamp.year,
          first.timestamp.month,
          first.timestamp.day,
        ),
      );
    }).toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Vitals History"),
      ),

      body: records.isEmpty
          ? const Center(
              child: Text("No vitals recorded"),
            )
          : ListView.builder(
              itemCount: records.length,

              itemBuilder: (context, index) {

                final record = records[index];

                return Card(
                  margin: const EdgeInsets.all(10),

                  child: ListTile(

                    leading: const Icon(
                      Icons.monitor_heart,
                      color: Colors.red,
                    ),

                    title: Text(
                      getDisplayName(record.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text("${record.value} ${record.unit}"),

                        if(record.previousValue != null)
                          Text(
                            getComparison(record.value, record.previousValue!),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          )

                      ],
                    ),

                    trailing: Text(
                      "${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}",
                    ),
                  ),
                );
              },
            ),
    );
  }

  String getDisplayName(String type) {

    switch(type) {

      case "blood_pressure":
        return "Blood Pressure";

      case "glucose":
        return "Blood Sugar";

      case "temperature":
        return "Body Temperature";

      case "heart_rate":
        return "Pulse Rate";

      case "weight":
        return "Weight";

      case "spo2":
        return "Oxygen Saturation";

      case "respiration":
        return "Respiration Rate";

      default:
        return type;
    }
  }

  String getComparison(String current, String previous) {

    try {

      double c = double.parse(current);
      double p = double.parse(previous);

      double diff = c - p;

      if(diff > 0) {
        return "↑ Increased by ${diff.toStringAsFixed(1)} (previous $previous)";
      }

      if(diff < 0) {
        return "↓ Decreased by ${diff.abs().toStringAsFixed(1)} (previous $previous)";
      }

      return "No change";

    } catch(e) {
      return "";
    }
  }
}
