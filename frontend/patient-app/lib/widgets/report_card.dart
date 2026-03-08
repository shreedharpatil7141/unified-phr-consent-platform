import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {

  final String title;
  final String date;
  final String type;

  const ReportCard({
    super.key,
    required this.title,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.only(bottom:12),

      child: ListTile(

        leading: const Icon(Icons.description),

        title: Text(title),

        subtitle: Text("$date • $type"),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("View report"),
                  ),
                );

              },
            ),

            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Share report"),
                  ),
                );

              },
            ),

          ],
        ),
      ),
    );
  }
}