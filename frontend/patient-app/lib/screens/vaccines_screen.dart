import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/health_record_repository.dart';

class VaccinesPage extends StatefulWidget {
  const VaccinesPage({super.key});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> {
  Future<void> _deleteRecord(HealthRecord record) async {
    await ApiService.deleteRecord(record.id);
    HealthRecordRepository.removeRecord(record.id);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final records = HealthRecordRepository.getAllRecords()
        .where((r) => r.category == "vaccine" || r.category == "vaccination")
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaccines"),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text("No vaccine records"),
            )
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                return ListTile(
                  leading: const Icon(Icons.vaccines),
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
