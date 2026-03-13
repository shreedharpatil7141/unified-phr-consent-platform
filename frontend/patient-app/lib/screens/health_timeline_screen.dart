import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/health_record_repository.dart';
import '../utils/server_time.dart';

class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {
  List<_TimelineEvent> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final uploadedRecords = HealthRecordRepository.getAllRecords()
        .where((record) => (record.filePath ?? "").isNotEmpty)
        .map(
          (record) => _TimelineEvent(
            title: record.recordName ?? record.type,
            subtitle: "${record.category} • ${record.hospitalName ?? "Uploaded document"}",
            timestamp: record.timestamp,
            icon: Icons.upload_file,
            color: const Color(0xFF2563EB),
          ),
        )
        .toList();

    final notificationEvents = <_TimelineEvent>[];
    try {
      final notifications = await ApiService.getNotifications();
      for (final item in notifications) {
        final message = (item["message"] ?? "").toString();
        if (!message.toLowerCase().contains("request") &&
            !message.toLowerCase().contains("alert") &&
            !message.toLowerCase().contains("approved")) {
          continue;
        }
        notificationEvents.add(
          _TimelineEvent(
            title: message,
            subtitle: "System activity",
            timestamp: parseServerTime(item["created_at"]) ?? DateTime.now(),
            icon: message.toLowerCase().contains("alert") ? Icons.warning_amber_rounded : Icons.verified_user,
            color: message.toLowerCase().contains("alert")
                ? const Color(0xFFEA580C)
                : const Color(0xFF0F766E),
          ),
        );
      }
    } catch (_) {}

    final combined = [...uploadedRecords, ...notificationEvents]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        events = combined;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Timeline")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? const Center(child: Text("No uploaded records or activity yet"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: event.color.withOpacity(0.14),
                              child: Icon(event.icon, size: 15, color: event.color),
                            ),
                            Container(width: 2, height: 92, color: const Color(0xFFDDE9E7)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFDDE9E7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year} • ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.subtitle,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class _TimelineEvent {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
