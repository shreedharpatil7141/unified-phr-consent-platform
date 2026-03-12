import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/health_record_repository.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  Future<void> _deleteRecord(HealthRecord record) async {
    await ApiService.deleteRecord(record.id);
    HealthRecordRepository.removeRecord(record.id);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final records = HealthRecordRepository.getAllRecords()
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
                  subtitle: Text(
                    "${record.doctorName ?? ""} • ${record.hospitalName ?? ""}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteRecord(record),
                  ),
                );
              },
            ),
    );
  }
}
