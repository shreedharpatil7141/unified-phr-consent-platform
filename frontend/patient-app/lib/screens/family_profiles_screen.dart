import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/server_time.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  final emailController = TextEditingController();
  final relationController = TextEditingController(text: "Family");

  bool loading = true;
  bool submitting = false;
  List<dynamic> incoming = [];
  List<dynamic> outgoing = [];
  List<dynamic> linked = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final incomingData = await ApiService.getIncomingFamilyRequests();
      final outgoingData = await ApiService.getOutgoingFamilyRequests();
      final linkedData = await ApiService.getLinkedFamilyProfiles();
      if (!mounted) return;
      setState(() {
        incoming = incomingData;
        outgoing = outgoingData;
        linked = (linkedData["profiles"] as List?) ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load family profiles: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendRequest() async {
    final email = emailController.text.trim().toLowerCase();
    final relation = relationController.text.trim();
    if (email.isEmpty || relation.isEmpty) return;

    setState(() => submitting = true);
    try {
      await ApiService.requestFamilyLink(
        memberEmail: email,
        relation: relation,
      );
      emailController.clear();
      relationController.text = "Family";
      await loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Family invite sent")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> respond(String linkId, String action) async {
    try {
      await ApiService.respondFamilyRequest(linkId: linkId, action: action);
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to $action request: $e")),
      );
    }
  }

  String _formatTime(dynamic value) {
    final date = parseServerTime(value);
    if (date == null) return "Unknown";
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Family Profiles")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Invite family by email",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Family member email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: relationController,
                    decoration: const InputDecoration(
                      labelText: "Relation (e.g. Father, Mother)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: submitting ? null : sendRequest,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(submitting ? "Sending..." : "Send request"),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle("Incoming requests"),
                  if (incoming.isEmpty)
                    const Text("No pending family requests", style: TextStyle(color: Colors.black54))
                  else
                    ...incoming.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["requester_email"] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text("Relation: ${item["relation"] ?? "Family"}"),
                                Text("Requested: ${_formatTime(item["requested_at"])}"),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    FilledButton(
                                      onPressed: () => respond(item["link_id"], "accept"),
                                      child: const Text("Accept"),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: () => respond(item["link_id"], "reject"),
                                      child: const Text("Reject"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),

                  _sectionTitle("Linked family overview"),
                  if (linked.isEmpty)
                    const Text("No accepted family links yet", style: TextStyle(color: Colors.black54))
                  else
                    ...linked.map((item) {
                      final profile = (item["profile"] as Map?)?.cast<String, dynamic>() ?? {};
                      final overview = (item["overview"] as Map?)?.cast<String, dynamic>() ?? {};
                      final lastVisit = (overview["last_doctor_visit"] as Map?)?.cast<String, dynamic>();
                      final heart = (overview["latest_heart_rate"] as Map?)?.cast<String, dynamic>();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile["name"]?.toString().isNotEmpty == true
                                    ? profile["name"].toString()
                                    : (profile["email"] ?? "").toString(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text("Email: ${profile["email"] ?? "N/A"}"),
                              Text("Relation: ${item["relation"] ?? "Family"}"),
                              if (profile["age"] != null) Text("Age: ${profile["age"]}"),
                              if ((profile["blood_group"] ?? "").toString().isNotEmpty)
                                Text("Blood group: ${profile["blood_group"]}"),
                              const Divider(height: 18),
                              Text(
                                "Last doctor visit: ${lastVisit == null ? "No visits yet" : _formatTime(lastVisit["scheduled_for"])}",
                              ),
                              Text(
                                "Latest heart rate: ${heart == null ? "No data" : "${heart["value"]} ${heart["unit"] ?? "bpm"}"}",
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  _sectionTitle("Outgoing requests"),
                  if (outgoing.isEmpty)
                    const Text("No sent requests", style: TextStyle(color: Colors.black54))
                  else
                    ...outgoing.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(item["member_email"] ?? ""),
                          subtitle: Text(
                            "Relation: ${item["relation"] ?? "Family"}\nRequested: ${_formatTime(item["requested_at"])}",
                          ),
                          trailing: Chip(
                            label: Text((item["status"] ?? "pending").toString()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
