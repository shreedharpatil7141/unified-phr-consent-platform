import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';

class MedicalBasicsScreen extends StatefulWidget {
  final bool showSkip;

  const MedicalBasicsScreen({super.key, this.showSkip = true});

  @override
  State<MedicalBasicsScreen> createState() => _MedicalBasicsScreenState();
}

class _MedicalBasicsScreenState extends State<MedicalBasicsScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final allergiesController = TextEditingController();
  final conditionsController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final emergencyController = TextEditingController();
  final ageController = TextEditingController();
  String selectedGender = "Prefer not to say";
  bool saving = false;

  Future<void> saveProfile() async {
    setState(() {
      saving = true;
    });

    try {
      await ApiService.updateProfile({
        "height_cm": double.tryParse(heightController.text.trim()),
        "weight_kg": double.tryParse(weightController.text.trim()),
        "allergies": allergiesController.text.trim(),
        "blood_group": bloodGroupController.text.trim(),
        "chronic_conditions": conditionsController.text.trim(),
        "emergency_contact": emergencyController.text.trim(),
        "gender": selectedGender,
        "age": int.tryParse(ageController.text.trim()),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not save profile: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Basics"),
        actions: [
          if (widget.showSkip)
            TextButton(
              onPressed: saving
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      );
                    },
              child: const Text("Skip"),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set up your health profile",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "These details help doctors understand your baseline health whenever you share access.",
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            _InputField(controller: heightController, label: "Height (cm)", keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _InputField(controller: weightController, label: "Weight (kg)", keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _InputField(controller: ageController, label: "Age", keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
                DropdownMenuItem(value: "Prefer not to say", child: Text("Prefer not to say")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value ?? selectedGender;
                });
              },
            ),
            const SizedBox(height: 14),
            _InputField(controller: bloodGroupController, label: "Blood group"),
            const SizedBox(height: 14),
            _InputField(controller: allergiesController, label: "Allergies", maxLines: 2),
            const SizedBox(height: 14),
            _InputField(controller: conditionsController, label: "Chronic conditions", maxLines: 2),
            const SizedBox(height: 14),
            _InputField(controller: emergencyController, label: "Emergency contact"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : saveProfile,
                child: Text(saving ? "Saving..." : "Save and continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
