import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/health_record_repository.dart';

class ManualHealthDataScreen extends StatefulWidget {
  const ManualHealthDataScreen({super.key});

  @override
  State<ManualHealthDataScreen> createState() => _ManualHealthDataScreenState();
}

class _ManualHealthDataScreenState extends State<ManualHealthDataScreen> {
  bool _loading = true;
  List<HealthRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await HealthRecordRepository.loadFromServer();
    final all = HealthRecordRepository.getAllRecords();
    final manualVitals = all
        .where((r) => r.source.toLowerCase() == "manual" && r.category.toLowerCase() == "vitals")
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) return;
    setState(() {
      _records = manualVitals;
      _loading = false;
    });
  }

  String _prettyType(String type) {
    final t = type.replaceAll("_", " ").trim();
    if (t.isEmpty) return "Metric";
    return t
        .split(" ")
        .map((part) => part.isEmpty ? part : "${part[0].toUpperCase()}${part.substring(1)}")
        .join(" ");
  }

  Widget _trendChip(HealthRecord record) {
    final direction = (record.changeDirection ?? "").toLowerCase();
    Color bg = const Color(0xFFE5E7EB);
    Color fg = const Color(0xFF334155);
    String text = "No previous comparison";

    if (direction == "increased") {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      text = "Increased vs last upload";
    } else if (direction == "decreased") {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      text = "Decreased vs last upload";
    } else if (direction == "unchanged") {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      text = "Unchanged vs last upload";
    } else if (direction == "new") {
      text = "First manual entry";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  String _formattedDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manual Health Data")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _records.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            "No manual vitals uploaded yet",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (_, index) {
                        final r = _records[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _prettyType(r.type),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    _trendChip(r),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${r.value} ${r.unit}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if ((r.previousValue ?? "").isNotEmpty)
                                  Text(
                                    "Previous: ${r.previousValue} ${r.unit}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  "Updated: ${_formattedDate(r.timestamp)}",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

