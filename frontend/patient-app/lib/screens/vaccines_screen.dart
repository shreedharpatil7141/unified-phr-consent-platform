import 'package:flutter/material.dart';
import '../services/health_record_repository.dart';
import '../models/health_record.dart';

class VaccinesPage extends StatelessWidget {
  const VaccinesPage({super.key});

  @override
  Widget build(BuildContext context) {

    final List<HealthRecord> records =
        HealthRecordRepository.getAllRecords()
            .where((r) =>
                r.category == "vaccine" ||
                r.category == "vaccination")
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
                      "${record.doctorName ?? ""} • ${record.hospitalName ?? ""}"),
                );
              },
            ),
    );
  }
}