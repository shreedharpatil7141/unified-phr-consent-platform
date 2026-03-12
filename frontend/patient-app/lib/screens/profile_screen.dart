import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/api_service.dart';
import 'family_profiles_screen.dart';
import 'medical_basics_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  bool watchConnected = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      profile = data;
      watchConnected = true;
    } catch (_) {}

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> openHealthConnect() async {
    final uri = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HealthSyncApp()),
      (route) => false,
    );
  }

  Widget infoChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE9E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = profile?["name"]?.toString().trim().isNotEmpty == true
        ? profile!["name"].toString()
        : "Your Profile";

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 34, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?["email"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            children: [
              if (profile?["height_cm"] != null) infoChip("Height", "${profile?["height_cm"]} cm"),
              if (profile?["weight_kg"] != null) infoChip("Weight", "${profile?["weight_kg"]} kg"),
              if ((profile?["blood_group"] ?? "").toString().isNotEmpty) infoChip("Blood Group", profile?["blood_group"]),
              if ((profile?["allergies"] ?? "").toString().isNotEmpty) infoChip("Allergies", profile?["allergies"]),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety, color: Color(0xFF0F766E)),
              title: const Text("Edit medical basics"),
              subtitle: const Text("Height, weight, allergies, blood group and more"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicalBasicsScreen()),
                );
                await loadProfile();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF0F766E)),
              title: const Text("Health Connect"),
              subtitle: Text(
                watchConnected
                    ? "Connected. Sync your wearable data through Health Connect."
                    : "Connect Health Connect to sync steps, heart rate, sleep, and distance.",
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: openHealthConnect,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Suggestion: open Health Connect, allow HealthSync permissions, and sync your wearable source app there first.",
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.family_restroom, color: Color(0xFF2563EB)),
              title: const Text("Manage Family Profiles"),
              subtitle: const Text("Store family members for future caregiving workflows"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
