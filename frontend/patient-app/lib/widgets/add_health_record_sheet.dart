import 'package:flutter/material.dart';

class AddHealthRecordSheet extends StatelessWidget {
  const AddHealthRecordSheet({super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16),

      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ADD HEALTH RECORDS
            const Text(
              "Add Health Records",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                recordButton(Icons.science, "Lab Reports"),
                recordButton(Icons.description, "Upload Prescription"),
                recordButton(Icons.note, "Doctor Notes"),
                recordButton(Icons.image, "Imaging"),
                recordButton(Icons.vaccines, "Vaccination"),
                recordButton(Icons.receipt, "Medical Expense"),

              ],
            ),

            const SizedBox(height: 30),

            /// ADD HEALTH DATA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [

                Text(
                  "Add Health Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    Icon(Icons.mic, color: Colors.blue),
                    SizedBox(width: 6),
                    Text("Add log through voice")
                  ],
                )

              ],
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                dataCard(Icons.monitor_heart, "Blood Pressure"),
                dataCard(Icons.bloodtype, "Post Prandial Sugar"),
                dataCard(Icons.bloodtype_outlined, "Fasting Blood Sugar"),
                dataCard(Icons.bloodtype, "Random Blood Sugar"),
                dataCard(Icons.thermostat, "Body Temperature"),
                dataCard(Icons.favorite, "Pulse Rate"),
                dataCard(Icons.monitor_weight, "Weight"),
                dataCard(Icons.air, "Oxygen Saturation"),
                dataCard(Icons.lungs, "Respiration Rate"),

              ],
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }

  /// RECORD BUTTON
  static Widget recordButton(IconData icon, String title) {

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        children: [

          Icon(icon, color: Colors.blue),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          )

        ],
      ),
    );
  }

  /// DATA CARD
  static Widget dataCard(IconData icon, String title) {

    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        children: [

          Icon(icon, color: Colors.blue),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),

        ],
      ),
    );
  }
}