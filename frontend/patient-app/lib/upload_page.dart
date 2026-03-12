import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/health_record_repository.dart';
import '../services/data_segregation_service.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Health Records"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),

              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Title
            const Text(
              "Add Health Records",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// Grid buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 3,

                children: const [

                  UploadButton(
                    icon: Icons.science,
                    text: "Lab Reports",
                  ),

                  UploadButton(
                    icon: Icons.receipt_long,
                    text: "Upload Prescription",
                  ),

                  UploadButton(
                    icon: Icons.note_alt,
                    text: "Doctor Notes",
                  ),

                  UploadButton(
                    icon: Icons.medical_information,
                    text: "Imaging",
                  ),

                  UploadButton(
                    icon: Icons.vaccines,
                    text: "Vaccination",
                  ),

                  UploadButton(
                    icon: Icons.currency_rupee,
                    text: "Medical Expense",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// Upload Button Widget
////////////////////////////////////////////////////

class UploadButton extends StatelessWidget {

  final IconData icon;
  final String text;

  const UploadButton({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () async {
        // pick a file and upload
        try {
          var result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.isNotEmpty) {
            String path = result.files.first.path!;
            String name = result.files.first.name;
            final mapping = DataSegregationService.segregate(text);
            final category = mapping["category"] ?? "other";
            final domain = mapping["domain"] ?? "general";
            await ApiService.uploadRecord(
              filePath: path,
              fileName: name,
              category: category,
              recordType: mapping["type"] ?? "document",
              domain: domain == "user_selected" ? "general" : domain,
              provider: text,
              recordName: name,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Upload succeeded"))
            );
            // make sure new record is fetched from backend
            await HealthRecordRepository.loadFromServer();
          }
        } catch (e) {
          print("UPLOAD ERROR: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Upload failed"))
          );
        }
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),

        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: Colors.blue,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
