import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  final nameController = TextEditingController();
  final relationController = TextEditingController();
  final ageController = TextEditingController();
  List<Map<String, dynamic>> profiles = [];

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("family_profiles");
    if (raw != null && raw.isNotEmpty) {
      profiles = List<Map<String, dynamic>>.from(jsonDecode(raw));
    }
    if (mounted) setState(() {});
  }

  Future<void> saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("family_profiles", jsonEncode(profiles));
  }

  Future<void> addProfile() async {
    if (nameController.text.trim().isEmpty || relationController.text.trim().isEmpty) {
      return;
    }
    profiles.insert(0, {
      "name": nameController.text.trim(),
      "relation": relationController.text.trim(),
      "age": ageController.text.trim(),
    });
    await saveProfiles();
    nameController.clear();
    relationController.clear();
    ageController.clear();
    if (mounted) setState(() {});
  }

  Future<void> deleteProfile(int index) async {
    profiles.removeAt(index);
    await saveProfiles();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family Profiles")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage loved ones",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "Store basic family records for future caregiving workflows.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: "Relation", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: addProfile,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("Add family profile"),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: profiles.isEmpty
                  ? const Center(child: Text("No family profiles added yet"))
                  : ListView.builder(
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final item = profiles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
                            title: Text(item["name"] ?? ""),
                            subtitle: Text("${item["relation"] ?? ""}${(item["age"] ?? "").toString().isNotEmpty ? " • Age ${item["age"]}" : ""}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => deleteProfile(index),
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
