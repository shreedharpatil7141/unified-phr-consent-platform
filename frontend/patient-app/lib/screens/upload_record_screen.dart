import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../services/data_segregation_service.dart';
import '../services/health_record_repository.dart';
import '../services/api_service.dart';

class UploadRecordScreen extends StatefulWidget {

  final String title;

  const UploadRecordScreen({
    super.key,
    required this.title,
  });

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {

  File? selectedFile;
  String? fileName;

  final recordNameController = TextEditingController();
  final hospitalController = TextEditingController();
  final doctorController = TextEditingController();
  final notesController = TextEditingController();

  String selectedDomain = "cardiac";

  Future pickFile() async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf','jpg','jpeg','png'],
    );

    if (result != null) {

      String path = result.files.single.path!;
      String name = result.files.single.name;

      setState(() {
        selectedFile = File(path);
        fileName = name;
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// FILE PREVIEW
            if(selectedFile != null)
              Column(
                children: [

                  if(fileName!.toLowerCase().endsWith(".pdf"))
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 100,
                      color: Colors.red,
                    )
                  else
                    Image.file(
                      selectedFile!,
                      height: 200,
                    ),

                  const SizedBox(height: 10),

                  Text(
                    fileName ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                ],
              ),

            const SizedBox(height: 20),

            /// FILE PICKER
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Report (PDF / Image)"),
            ),

            const SizedBox(height: 25),

            /// RECORD NAME
            TextField(
              controller: recordNameController,
              decoration: const InputDecoration(
                labelText: "Record Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// DOMAIN DROPDOWN (only for lab reports)
            if(widget.title == "Lab Reports")
              DropdownButtonFormField<String>(

                value: selectedDomain,

                decoration: const InputDecoration(
                  labelText: "Medical Domain",
                  border: OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: "cardiac",
                    child: Text("Cardiac"),
                  ),

                  DropdownMenuItem(
                    value: "metabolic",
                    child: Text("Metabolic"),
                  ),

                  DropdownMenuItem(
                    value: "renal",
                    child: Text("Renal"),
                  ),

                  DropdownMenuItem(
                    value: "hepatic",
                    child: Text("Hepatic"),
                  ),

                  DropdownMenuItem(
                    value: "hematology",
                    child: Text("Hematology"),
                  ),

                  DropdownMenuItem(
                    value: "respiratory",
                    child: Text("Respiratory"),
                  ),

                  DropdownMenuItem(
                    value: "wellness",
                    child: Text("General Wellness"),
                  ),

                ],

                onChanged: (value){

                  setState(() {
                    selectedDomain = value!;
                  });

                },

              ),

            const SizedBox(height: 15),

            /// HOSPITAL
            TextField(
              controller: hospitalController,
              decoration: const InputDecoration(
                labelText: "Hospital / Lab Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// DOCTOR
            TextField(
              controller: doctorController,
              decoration: const InputDecoration(
                labelText: "Doctor Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// NOTES
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            /// SAVE BUTTON
            ElevatedButton(
              onPressed: () async {

                if (selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please upload a file")),
                  );
                  return;
                }

                final mapping =
                    DataSegregationService.segregate(widget.title);

                final domain = widget.title == "Lab Reports"
                    ? selectedDomain
                    : mapping["domain"]!;

                try {
                  final response = await ApiService.uploadRecord(
                    filePath: selectedFile!.path,
                    fileName: fileName!,
                    category: mapping["category"]!,
                    recordType: mapping["type"]!,
                    domain: domain,
                    provider: hospitalController.text.trim(),
                    recordName: recordNameController.text.trim(),
                    doctor: doctorController.text.trim(),
                    hospital: hospitalController.text.trim(),
                    notes: notesController.text.trim(),
                  );

                  await HealthRecordRepository.loadFromServer();

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Record uploaded successfully"
                        "${response["report_intelligence"] != null ? " - ${response["report_intelligence"]["inferred_domain"]} detected" : ""}",
                      ),
                    ),
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Upload failed: $e")),
                  );
                }
              },
              child: const Text("Save Record"),
            )

          ],
        ),
      ),
    );
  }
}
