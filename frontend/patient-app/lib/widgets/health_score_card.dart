import 'package:flutter/material.dart';

class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "❤️ Cardiac Health Score: 72%",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height:8),

            Text("Slight upward trend detected"),

            SizedBox(height:10),

            Text(
              "View Insights",
              style: TextStyle(color: Colors.blue),
            )

          ],
        ),
      ),
    );
  }
}