import 'package:flutter/material.dart';
import 'vital_detail_screen.dart';

class VitalsGraphsScreen extends StatefulWidget {
  const VitalsGraphsScreen({super.key});

  @override
  State<VitalsGraphsScreen> createState() => _VitalsGraphsScreenState();
}

class _VitalsGraphsScreenState extends State<VitalsGraphsScreen> {
  final List<Map<String, String>> vitals = [
    {"title": "Heart Rate", "unit": "BPM"},
    {"title": "Steps", "unit": "steps"},
    {"title": "Distance", "unit": "km"},
    {"title": "Sleep", "unit": "hrs"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090B10),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Vitals Graphs"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a vital to view detailed graph",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...vitals.map(
              (vital) => VitalGraphCard(
                title: vital["title"]!,
                unit: vital["unit"]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VitalDetailScreen(
                        title: vital["title"]!,
                        unit: vital["unit"]!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitalGraphCard extends StatelessWidget {
  final String title;
  final String unit;
  final VoidCallback onTap;

  const VitalGraphCard({
    required this.title,
    required this.unit,
    required this.onTap,
  });

  Color get _accentColor {
    final titleLower = title.toLowerCase();
    if (titleLower.contains("heart")) return const Color(0xFFFF6B81);
    if (titleLower.contains("step")) return const Color(0xFF4ADE80);
    if (titleLower.contains("distance")) return const Color(0xFFFACC15);
    if (titleLower.contains("sleep")) return const Color(0xFF60A5FA);
    return const Color(0xFF60A5FA);
  }

  IconData get _icon {
    final titleLower = title.toLowerCase();
    if (titleLower.contains("heart")) return Icons.favorite;
    if (titleLower.contains("step")) return Icons.directions_walk;
    if (titleLower.contains("distance")) return Icons.straighten;
    if (titleLower.contains("sleep")) return Icons.bedtime;
    return Icons.trending_up;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12151D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: _accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "View detailed graph in $unit",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
