import 'package:flutter/material.dart';

import '../services/health_record_repository.dart';
import 'health_input_screen.dart';
import 'upload_record_screen.dart';

class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> {
  void _reloadData() {
    setState(() {
      // Trigger rebuild to refresh vitals
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Hub")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add records and baseline health data",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload documents to your health locker or enter structured health measurements that can appear in doctor access flows.",
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            const _SectionTitle("Upload medical documents"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _HubActionCard(icon: Icons.science, title: "Lab Reports"),
                _HubActionCard(icon: Icons.description, title: "Upload Prescription"),
                _HubActionCard(icon: Icons.vaccines, title: "Vaccination"),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionTitle("Store health data"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HealthDataCard(
                  icon: Icons.monitor_heart,
                  title: "Blood Pressure",
                  unit: "mmHg",
                  onSave: _reloadData,
                ),
                _HealthDataCard(
                  icon: Icons.bloodtype,
                  title: "Blood Sugar",
                  unit: "mg/dL",
                  onSave: _reloadData,
                ),
                _HealthDataCard(
                  icon: Icons.favorite,
                  title: "Pulse Rate",
                  unit: "BPM",
                  onSave: _reloadData,
                ),
                _HealthDataCard(
                  icon: Icons.monitor_weight,
                  title: "Weight",
                  unit: "kg",
                  onSave: _reloadData,
                ),
                _HealthDataCard(
                  icon: Icons.air,
                  title: "Oxygen Saturation",
                  unit: "%",
                  onSave: _reloadData,
                ),
                _HealthDataCard(
                  icon: Icons.thermostat,
                  title: "Body Temperature",
                  unit: "°C",
                  onSave: _reloadData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _HubActionCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UploadRecordScreen(title: title)),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE9E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFD6F5EF),
                child: Icon(icon, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Store it in your locker and make it available for consented sharing.",
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String unit;
  final VoidCallback? onSave;

  const _HealthDataCard({
    required this.icon,
    required this.title,
    required this.unit,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HealthInputScreen(title: title, unit: unit),
            ),
          );
          // If save was successful (returned true), reload data
          if (result == true && onSave != null) {
            onSave!();
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE9E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE6F2FF),
                child: Icon(icon, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Save as structured data in $unit for doctor access and trends.",
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
