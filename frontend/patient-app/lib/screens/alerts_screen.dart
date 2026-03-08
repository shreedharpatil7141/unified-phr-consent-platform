import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Health Alerts"),
      ),

      body: ListView(
        children: const [

          ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text("Heart rate increasing"),
            subtitle: Text("Detected trend in last 3 months"),
          ),

          ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text("Cholesterol normal"),
            subtitle: Text("Latest test result"),
          )

        ],
      ),
    );
  }
}