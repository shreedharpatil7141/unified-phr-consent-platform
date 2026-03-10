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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Doctor Name
            Text(
              doctor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// Request Type
            Text(
              "Request: $request",
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 4),

            /// Duration
            Text(
              "Duration: $duration",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            /// Buttons
            if (showActions) const SizedBox(height: 12),

            if (showActions)
              Row(
                children: [

                  /// Approve Button
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Approve"),
                  ),

                  const SizedBox(width: 10),

                  /// Reject Button
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
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