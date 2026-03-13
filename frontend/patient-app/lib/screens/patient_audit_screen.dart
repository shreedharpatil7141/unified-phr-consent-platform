import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PatientAuditScreen extends StatefulWidget {
  const PatientAuditScreen({super.key});

  @override
  State<PatientAuditScreen> createState() => _PatientAuditScreenState();
}

class _PatientAuditScreenState extends State<PatientAuditScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  int _daysBack = 30;
  Map<String, int> _appointmentSummary = {
    "total": 0,
    "requested": 0,
    "confirmed": 0,
    "completed": 0,
    "cancelled": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  Future<void> _loadAudit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await ApiService.getPatientAccessAudit(daysBack: _daysBack);
      final appointments = await ApiService.getMyAppointments();
      final summary = (payload["audit_summary"] as Map?)?.cast<String, dynamic>() ?? {};
      final cutoff = DateTime.now().subtract(Duration(days: _daysBack));
      final appointmentSummary = {
        "total": 0,
        "requested": 0,
        "confirmed": 0,
        "completed": 0,
        "cancelled": 0,
      };
      for (final row in appointments) {
        final source = row is Map ? row : <String, dynamic>{};
        final requestedAt = source["requested_at"];
        DateTime? when;
        if (requestedAt is String) {
          when = DateTime.tryParse(requestedAt)?.toLocal();
        }
        if (when != null && when.isBefore(cutoff)) continue;
        appointmentSummary["total"] = (appointmentSummary["total"] ?? 0) + 1;
        final status = (source["status"] ?? "requested").toString().toLowerCase();
        if (appointmentSummary.containsKey(status)) {
          appointmentSummary[status] = (appointmentSummary[status] ?? 0) + 1;
        }
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _appointmentSummary = appointmentSummary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<MapEntry<String, dynamic>> _doctorEntries() {
    final byDoctor = (_summary["by_doctor"] as Map?)?.cast<String, dynamic>() ?? {};
    final entries = byDoctor.entries.toList();
    entries.sort((a, b) => (b.value as num).compareTo(a.value as num));
    return entries;
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE9E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0F766E), size: 20),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = (_summary["total_accesses"] ?? 0).toString();
    final success = (_summary["successful_accesses"] ?? 0).toString();
    final denied = (_summary["denied_accesses"] ?? 0).toString();
    final doctorEntries = _doctorEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Access Audit Logs"),
        actions: [
          PopupMenuButton<int>(
            initialValue: _daysBack,
            onSelected: (value) {
              _daysBack = value;
              _loadAudit();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text("Last 7 days")),
              PopupMenuItem(value: 30, child: Text("Last 30 days")),
              PopupMenuItem(value: 90, child: Text("Last 90 days")),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Failed to load audit logs.\n$_error",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAudit,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        "Who accessed your health data",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _metricCard("Total Accesses", total, Icons.analytics_outlined),
                          const SizedBox(width: 10),
                          _metricCard("Successful", success, Icons.check_circle_outline),
                          const SizedBox(width: 10),
                          _metricCard("Denied", denied, Icons.block_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Accesses by doctor",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (doctorEntries.isEmpty)
                        const Text(
                          "No doctor access logs found in this period.",
                          style: TextStyle(color: Colors.black54),
                        )
                      else
                        ...doctorEntries.map(
                          (entry) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDDE9E7)),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFD6F5EF),
                                  child: Icon(Icons.medical_services_outlined, color: Color(0xFF0F766E), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  "${entry.value} accesses",
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        "Appointment activity",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDE9E7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total: ${_appointmentSummary["total"] ?? 0}"),
                            Text("Requested: ${_appointmentSummary["requested"] ?? 0}"),
                            Text("Confirmed: ${_appointmentSummary["confirmed"] ?? 0}"),
                            Text("Completed: ${_appointmentSummary["completed"] ?? 0}"),
                            Text("Cancelled: ${_appointmentSummary["cancelled"] ?? 0}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
