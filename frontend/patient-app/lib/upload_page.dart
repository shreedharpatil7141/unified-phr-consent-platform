import 'package:flutter/material.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Health Records"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),

              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Title
            const Text(
              "Add Health Records",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// Grid buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 3,

                children: const [

                  UploadButton(
                    icon: Icons.science,
                    text: "Lab Reports",
                  ),

                  UploadButton(
                    icon: Icons.receipt_long,
                    text: "Upload Prescription",
                  ),

                  UploadButton(
                    icon: Icons.note_alt,
                    text: "Doctor Notes",
                  ),

                  UploadButton(
                    icon: Icons.medical_information,
                    text: "Imaging",
                  ),

                  UploadButton(
                    icon: Icons.vaccines,
                    text: "Vaccination",
                  ),

                  UploadButton(
                    icon: Icons.currency_rupee,
                    text: "Medical Expense",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// Upload Button Widget
////////////////////////////////////////////////////

class UploadButton extends StatelessWidget {

  final IconData icon;
  final String text;

  const UploadButton({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () {
        print("$text clicked");
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),

        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: Colors.blue,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}