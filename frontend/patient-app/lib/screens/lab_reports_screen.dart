import 'package:flutter/material.dart';
import '../services/health_record_repository.dart';
import '../models/health_record.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class LabReportsPage extends StatefulWidget {
  const LabReportsPage({super.key});

  @override
  State<LabReportsPage> createState() => _LabReportsPageState();
}

class _LabReportsPageState extends State<LabReportsPage> {

  String selectedDomain = "all";

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
              onPressed: () {
                if(record.filePath != null){
                  OpenFile.open(record.filePath!);
                }
              },
            ),

            const SizedBox(width: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("Share"),
              onPressed: () {
                if(record.filePath != null){
                  Share.shareXFiles(
                    [XFile(record.filePath!)],
                    text: record.recordName ?? "Medical Report",
                  );
                }
              },
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