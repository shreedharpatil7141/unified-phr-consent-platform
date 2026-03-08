import 'package:flutter/material.dart';
import '../services/health_record_repository.dart';
import '../models/health_record.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {

    final List<HealthRecord> records =
        HealthRecordRepository.getAllRecords()
            .where((r) => r.category == "prescription")
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescriptions"),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text("No prescriptions uploaded"),
            )
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {

                final record = records[index];

                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(record.recordName ?? record.type),
subtitle: Text("${record.doctorName ?? ""} • ${record.hospitalName ?? ""}"),
                );
              },
            ),
    );
  }
}