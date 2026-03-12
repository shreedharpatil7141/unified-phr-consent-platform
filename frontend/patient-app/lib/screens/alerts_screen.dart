import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future loadAlerts() async {
    try {
      final data = await ApiService.getAlerts();
      setState(() {
        alerts = data;
        loading = false;
      });
    } catch (e) {
      print('LOAD ALERTS ERROR: $e');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Alerts"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
              ? const Center(child: Text("No alerts"))
              : ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final a = alerts[index];
                    return ListTile(
                      leading: Icon(
                        a["metric"] != null ? Icons.warning : Icons.info,
                        color: Colors.orange,
                      ),
                      title: Text(a["message"] ?? ""),
                      subtitle: Text(a["created_at"] ?? ""),
                    );
                  },
                ),
    );
  }
}