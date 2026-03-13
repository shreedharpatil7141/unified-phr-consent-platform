import 'package:flutter/material.dart';
import '../services/health_record_repository.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LabReportsPage extends StatefulWidget {
  const LabReportsPage({super.key});

  @override
  State<LabReportsPage> createState() => _LabReportsPageState();
}

class _LabReportsPageState extends State<LabReportsPage> {

  String selectedDomain = "all";

  bool _isRemoteFile(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme;
  }

  Future<void> _viewFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return;
    }

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
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    if (_isRemoteFile(filePath)) {
      await Share.share(
        "${record.recordName ?? "Medical Report"}\n$filePath",
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: record.recordName ?? "Medical Report",
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

    List<HealthRecord> records =
        HealthRecordRepository.getAllRecords()
            .where((r) => r.category == "lab_report")
            .toList();

    if(selectedDomain != "all"){
      records = records
          .where((r) => r.domain == selectedDomain)
          .toList();
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Lab Reports"),
      ),

      body: Column(

        children: [

          /// FILTER CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [

                filterChip("all","All"),
                filterChip("cardiac","Cardiac"),
                filterChip("metabolic","Metabolic"),
                filterChip("renal","Renal"),
                filterChip("hematology","Hematology"),
                filterChip("radiology","Radiology"),
                filterChip("respiratory","Respiratory"),

              ],
            ),
          ),

          const SizedBox(height: 10),

          /// REPORT LIST
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text("No Lab Reports Uploaded"),
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

            const Icon(Icons.science, color: Colors.blue),

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
              onPressed: () async {
                await _viewFile(record.filePath);
              },
            ),

            const SizedBox(width: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("Share"),
              onPressed: () async {
                await _shareFile(record);
              },
            ),

            const SizedBox(width: 10),

            IconButton(
              onPressed: () => _deleteRecord(record),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),

          ],
        )

      ],
    ),
  ),
);

                    },
                  ),
          ),

        ],
      ),
    );
  }

  Widget filterChip(String value, String label){

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),

      child: ChoiceChip(
        label: Text(label),
        selected: selectedDomain == value,

        onSelected: (v){

          setState(() {
            selectedDomain = value;
          });

        },
      ),
    );

  }

}
