import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/health_record_repository.dart';

class VaccinesPage extends StatefulWidget {
  const VaccinesPage({super.key});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> {
  bool _isRemoteFile(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme;
  }

  Future<void> _viewFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;

    if (_isRemoteFile(filePath)) {
      final uri = Uri.parse(filePath);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open file")),
        );
      }
      return;
    }

    await OpenFile.open(filePath);
  }

  Future<void> _shareFile(HealthRecord record) async {
    final filePath = record.filePath;
    if (filePath == null || filePath.isEmpty) return;

    if (_isRemoteFile(filePath)) {
      await Share.share("${record.recordName ?? "Vaccination Record"}\n$filePath");
      return;
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: record.recordName ?? "Vaccination Record",
    );
  }

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

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vaccines, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                record.recordName ?? record.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${record.doctorName ?? ""} • ${record.hospitalName ?? ""}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text("View"),
                              onPressed: () async => _viewFile(record.filePath),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text("Share"),
                              onPressed: () async => _shareFile(record),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteRecord(record),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
