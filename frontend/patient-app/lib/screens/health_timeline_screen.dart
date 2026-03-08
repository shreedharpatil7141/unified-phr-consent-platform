import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../services/health_record_repository.dart';

class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {

  List<HealthRecord> records = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  void loadRecords() {

    records = HealthRecordRepository
        .getAllRecords()
        .where((r) => r.category != "vitals")   // remove vitals
        .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Health Timeline"),
      ),

      body: records.isEmpty
          ? const Center(
              child: Text("No health events yet"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,

              itemBuilder: (context, index) {

                final record = records[index];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Timeline Line
                    Column(
                      children: [

                        const Icon(
                          Icons.circle,
                          size: 12,
                          color: Colors.blue,
                        ),

                        Container(
                          width: 2,
                          height: 80,
                          color: Colors.grey.shade300,
                        )

                      ],
                    ),

                    const SizedBox(width: 12),

                    /// Timeline Card
                    Expanded(
                      child: Card(
                        elevation: 2,

                        child: ListTile(

                          leading: Icon(
                            getIcon(record.category),
                            color: Colors.blue,
                          ),

                          title: Text(
                            record.recordName ?? record.type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (record.hospitalName != null &&
                                  record.hospitalName!.isNotEmpty)
                                Text(record.hospitalName!),

                            ],
                          ),

                          trailing: Text(
                            "${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    )

                  ],
                );
              },
            ),
    );
  }

  IconData getIcon(String category) {

    switch (category) {

      case "lab_report":
        return Icons.science;

      case "prescription":
        return Icons.description;

      case "vaccination":
        return Icons.vaccines;

      case "expense":
        return Icons.receipt_long;

      default:
        return Icons.health_and_safety;
    }
  }
}