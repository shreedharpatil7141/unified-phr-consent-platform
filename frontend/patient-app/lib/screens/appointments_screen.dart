import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/server_time.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final doctorEmailController = TextEditingController();
  final reasonController = TextEditingController(text: "General consultation");
  final notesController = TextEditingController();

  DateTime scheduledFor = DateTime.now().add(const Duration(hours: 2));
  bool loading = true;
  bool submitting = false;
  List<dynamic> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getMyAppointments();
      if (!mounted) return;
      setState(() => appointments = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load appointments: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledFor,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledFor),
    );
    if (time == null) return;

    setState(() {
      scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> requestAppointment() async {
    final doctorEmail = doctorEmailController.text.trim().toLowerCase();
    final reason = reasonController.text.trim();
    if (doctorEmail.isEmpty || reason.isEmpty) return;

    setState(() => submitting = true);
    try {
      await ApiService.requestAppointment(
        doctorEmail: doctorEmail,
        scheduledFor: scheduledFor,
        reason: reason,
        notes: notesController.text.trim(),
      );
      doctorEmailController.clear();
      reasonController.text = "General consultation";
      notesController.clear();
      await loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment requested")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to request appointment: $e")),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await ApiService.cancelAppointment(appointmentId: appointmentId);
      await loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel appointment: $e")),
      );
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await ApiService.deleteAppointment(appointmentId: appointmentId);
      await loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete appointment: $e")),
      );
    }
  }

  String fmt(dynamic value) {
    final date = parseServerTime(value);
    if (date == null) return "N/A";
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool isExpired(dynamic item) {
    final status = (item["status"] ?? "").toString();
    if (status == "completed" || status == "cancelled") return true;
    if (status != "confirmed") return false;
    final endTime = parseServerTime(item["ends_at"]);
    if (endTime == null) return false;
    return endTime.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Appointments")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAppointments,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Book a doctor appointment",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: doctorEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Doctor email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Notes (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickDateTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      "Preferred: ${scheduledFor.day}/${scheduledFor.month}/${scheduledFor.year} ${scheduledFor.hour.toString().padLeft(2, '0')}:${scheduledFor.minute.toString().padLeft(2, '0')}",
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting ? null : requestAppointment,
                      child: Text(submitting ? "Requesting..." : "Request appointment"),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "My appointments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (appointments.isEmpty)
                    const Text("No appointments yet", style: TextStyle(color: Colors.black54))
                  else
                    ...appointments.map((item) {
                      final status = (item["status"] ?? "requested").toString();
                      final removable = isExpired(item);
                      final cancellable = (status == "requested" || status == "confirmed") && !removable;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["doctor_email"] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text("Status: $status"),
                              Text("Reason: ${item["reason"] ?? "General consultation"}"),
                              Text("Requested: ${fmt(item["requested_at"])}"),
                              Text("Scheduled: ${fmt(item["scheduled_for"])}"),
                              if ((item["confirmation_note"] ?? "").toString().isNotEmpty)
                                Text("Note: ${item["confirmation_note"]}"),
                              if (cancellable) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => cancelAppointment(item["appointment_id"]),
                                  child: const Text("Cancel appointment"),
                                ),
                              ],
                              if (removable) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => deleteAppointment(item["appointment_id"]),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
