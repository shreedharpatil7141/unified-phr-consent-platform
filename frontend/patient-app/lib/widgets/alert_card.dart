import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "⚠ Smart Alert",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height:8),

            Text("Resting HR rising for 3 months"),

            SizedBox(height:10),

            Row(
              children: [
                Text("View Trend", style: TextStyle(color: Colors.blue)),
                SizedBox(width:20),
                Text("Share with Doctor", style: TextStyle(color: Colors.blue))
              ],
            )

          ],
        ),
      ),
    );
  }
}