import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {

  Future<void> _pickFile(BuildContext context) async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf','jpg','jpeg','png'],
    );

    if (result == null) return;

    String filePath = result.files.single.path!;
    String fileName = result.files.single.name;

    print("Selected file: $fileName");

    await ApiService.uploadRecord(
      filePath: filePath,
      fileName: fileName,
      category: "lab_report",
      recordType: "document",
      domain: "general",
      recordName: fileName,
    );

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Report")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload Health Report"),
          onPressed: () => _pickFile(context),
        ),
      ),
    );
  }
}
