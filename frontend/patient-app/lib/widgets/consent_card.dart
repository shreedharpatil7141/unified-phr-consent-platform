import 'package:flutter/material.dart';

class ConsentCard extends StatelessWidget {

  final String consentId;
  final String doctor;
  final String request;
  final String duration;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ConsentCard({
    super.key,
    required this.consentId,
    required this.doctor,
    required this.request,
    required this.duration,
    required this.showActions,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.only(bottom:12),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              doctor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:6),

            Text("Request: $request"),
            Text("Duration: $duration"),

            if(showActions)
              const SizedBox(height:10),

            if(showActions)
              Row(
                children: [

                  ElevatedButton(
                    onPressed: onApprove,
                    child: const Text("Approve"),
                  ),

                  const SizedBox(width:10),

                  OutlinedButton(
                    onPressed: onReject,
                    child: const Text("Reject"),
                  )

                ],
              )

          ],
        ),
      ),
    );
  }
}