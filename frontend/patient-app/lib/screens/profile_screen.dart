import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:health/health.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  bool watchConnected = false;
  bool fitConnected = false;

  Future<void> openGoogleFit() async {
    final Uri url = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.google.android.apps.fitness",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> openHealthConnect() async {
    final Uri url = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
  Future<void> checkWatchConnection() async {
  try {

    final health = Health();

    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));

    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
    ];

    bool requested = await health.requestAuthorization(types);

    if (requested) {

      List data = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      if (data.isNotEmpty) {
        setState(() {
          watchConnected = true;
        });
      }

    }

  } catch (e) {
    print("Health check failed");
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Profile"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// Profile Header
          Row(
            children: const [

              CircleAvatar(
                radius: 35,
                child: Icon(Icons.person, size: 40),
              ),

              SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Rohan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text("ABHA ID: 1234-5678-9012"),

                ],
              )

            ],
          ),

          const SizedBox(height: 30),

          /// Linked Devices
          const Text(
            "Linked Devices",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// Smartwatch
          ListTile(
            leading: const Icon(Icons.watch),
            title: const Text("Smartwatch"),
            subtitle: Text(
              watchConnected ? "Connected" : "Not Connected",
              style: TextStyle(
                color: watchConnected ? Colors.green : Colors.grey,
              ),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
  await openHealthConnect();
  await checkWatchConnection();
},
          ),

          /// Google Fit
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text("Google Fit"),
            subtitle: Text(
              fitConnected ? "Connected" : "Not Connected",
              style: TextStyle(
                color: fitConnected ? Colors.green : Colors.grey,
              ),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: openGoogleFit,
          ),

          const SizedBox(height: 10),

          const Text(
            "Install Google Fit or Health Connect and allow this app to read steps and heart rate data.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const Divider(),

          /// Family Profiles
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text("Manage Family Profiles"),
            onTap: () {},
          ),

          /// Privacy
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy & Security"),
            onTap: () {},
          ),

          /// Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            onTap: () {},
          ),

          const Divider(),

          /// Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Logout feature coming soon"),
                ),
              );

            },
          ),

        ],
      ),
    );
  }
}