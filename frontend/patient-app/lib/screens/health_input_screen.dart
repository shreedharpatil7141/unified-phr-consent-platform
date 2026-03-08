import 'package:flutter/material.dart';
import '../models/health_record.dart';
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
              onPressed: () {

                String enteredValue = valueController.text;

                if (enteredValue.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter value")),
                  );
                  return;
                }

                final mapping =
    DataSegregationService.segregate(widget.title);

HealthRecordRepository.addRecord(
  HealthRecord(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    category: mapping["category"]!,
    type: DataNormalizationService.normalizeType(mapping["type"]!),
    domain: mapping["domain"]!, // NEW
    value: enteredValue,
    unit: widget.unit,
    source: "manual",
    timestamp: DateTime.now(),
  ),
);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Record Saved")),
                );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            )

          ],
        ),
      ),
    );
  }
}