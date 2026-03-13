import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/data_segregation_service.dart';
import '../services/health_record_repository.dart';
import '../services/data_normalization_service.dart';

class HealthInputScreen extends StatefulWidget {

  final String title;
  final String unit;

  const HealthInputScreen({
    super.key,
    required this.title,
    required this.unit,
  });

  @override
  State<HealthInputScreen> createState() => _HealthInputScreenState();
}

class _HealthInputScreenState extends State<HealthInputScreen> {

  final TextEditingController valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter ${widget.title}",
                suffixText: widget.unit,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {

                String enteredValue = valueController.text;

                if (enteredValue.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter value")),
                  );
                  return;
                }

                final mapping =
    DataSegregationService.segregate(widget.title);

                final timestamp = DateTime.now();
                final normalizedType =
                    DataNormalizationService.normalizeType(mapping["type"]!);

                final email = await ApiService.getUserEmail();
                if (email == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not logged in")),
                  );
                  return;
                }

                try {
                  // Sync to backend first
                  final response = await ApiService.addHealthRecord(
                    patientId: email,
                    source: "manual",
                    category: mapping["category"]!,
                    recordType: normalizedType,
                    domain: mapping["domain"]!,
                    value: enteredValue,
                    unit: widget.unit,
                    timestamp: timestamp,
                  );

                  // Add to local repository
                  HealthRecordRepository.addRecord(
                    HealthRecord(
                      id: timestamp.millisecondsSinceEpoch.toString(),
                      category: mapping["category"]!,
                      type: normalizedType,
                      domain: mapping["domain"]!,
                      value: enteredValue,
                      unit: widget.unit,
                      source: "manual",
                      timestamp: timestamp,
                    ),
                  );

                  // Reload from server to get the saved record
                  await HealthRecordRepository.loadFromServer();

                  if (!mounted) return;

                  final direction = (response["change_direction"] ?? "").toString();
                  final isOverwrite = response["overwritten"] == true;
                  String feedback = "Record saved successfully";
                  if (isOverwrite) {
                    if (direction == "increased") {
                      feedback = "Record updated: increased vs last upload";
                    } else if (direction == "decreased") {
                      feedback = "Record updated: decreased vs last upload";
                    } else if (direction == "unchanged") {
                      feedback = "Record updated: unchanged vs last upload";
                    } else {
                      feedback = "Record updated";
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(feedback),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  Navigator.pop(context, true); // Return true to signal refresh
                } catch (e) {
                  if (!mounted) return;
                  
                  print("SAVE RECORD ERROR: $e");
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to save: ${e.toString()}"),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save"),
            )

          ],
        ),
      ),
    );
  }
}
