import 'package:flutter/material.dart';
import 'package:health1/screens/vital_detail_screen.dart';
import '../services/api_service.dart';
import 'package:health1/screens/health_input_screen.dart';
import 'package:health1/screens/upload_record_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:health1/screens/health_timeline_screen.dart';
import '../services/health_service.dart';
import 'lab_reports_screen.dart';
import 'prescriptions_screen.dart';
import 'vaccines_screen.dart';
import '../services/health_record_repository.dart';
import 'package:health1/screens/vitals_history_screen.dart';
import '../models/health_record.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import '../models/consent_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final HealthService healthService = HealthService();

  List<HealthRecord> records = [];
  List<Consent> pendingConsents = [];   // ADD THIS LINE

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
    loadSmartwatchData();
    loadConsents();   
  }
   Future loadRecords() async {

  await Future.delayed(const Duration(milliseconds: 300));

  setState(() {
    records = HealthRecordRepository.getAllRecords();
    print("Records loaded: ${records.length}");
    loading = false;
  });

}

Future loadConsents() async {

  try {

    final data = await ApiService.getMyConsents();

    List<Consent> consents = data.map<Consent>((c) {

      return Consent(
        id: c["consent_id"],
        doctor: c["doctor_id"],
        request: c["categories"].join(", "),
        duration: c["access_duration_minutes"].toString(),
        status: c["status"],
      );

    }).toList();

    setState(() {
      pendingConsents =
          consents.where((c) => c.status == "pending").toList();
    });

  } catch (e) {

    print("CONSENT LOAD ERROR: $e");

  }

}
@override
void didChangeDependencies() {
  super.didChangeDependencies();

  setState(() {
    records = HealthRecordRepository.getAllRecords();
  });
}
  
  Future loadSmartwatchData() async {

  var data = await healthService.getHealthData();

  for (var point in data) {

    String type = "";

    if (point.type == HealthDataType.STEPS) {
      type = "Steps";
    }
    else if (point.type == HealthDataType.HEART_RATE) {
      type = "Heart Rate";
    }
    else if (point.type == HealthDataType.DISTANCE_DELTA) {
      type = "Distance";
    }
    else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
      type = "Calories Burned";
    }
    else if (point.type == HealthDataType.SLEEP_ASLEEP) {
      type = "Sleep";
    }
    else {
      type = point.type.toString();
    }

    String value =
        point.value.toString().replaceAll(RegExp('[^0-9.]'), '');

    HealthRecordRepository.addRecord(
      HealthRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: "wearable",
        type: type,
        domain: "wellness",
        value: value,
        unit: "",
        source: "smartwatch",
        timestamp: point.dateFrom,
      ),
    );

  }

  setState(() {
    records = HealthRecordRepository.getAllRecords();
  });

}

////////////////////////////////////////////////////////////
/// ADD THIS FUNCTION HERE
////////////////////////////////////////////////////////////

String getLatestValue(String type) {

  try {

    final rec = records.lastWhere((r) => r.type == type);

    return rec.value.toString();

  } catch (e) {

    return "0";

  }

}

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("My Health"),
        actions: [

  IconButton(
    icon: const Icon(Icons.timeline),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HealthTimelineScreen(),
        ),
      );
    },
  ),
  const SizedBox(height: 30),

  ElevatedButton.icon(
  icon: const Icon(Icons.monitor_heart),
  label: const Text("View Vitals History"),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VitalsHistoryScreen(),
      ),
    );
  },
),

  const Icon(Icons.notifications),

],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Today's Vitals
            const Text(
              "Today's Vitals",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
      const SizedBox(height: 30),

const Text(
  "Watch Data",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

const SizedBox(height: 12),

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),

  child: Column(
    children:[

      WatchItem(title: "Steps", value: getLatestValue("Steps")),
WatchItem(title: "Distance", value: getLatestValue("Distance")),
WatchItem(title: "Calories Burned", value: getLatestValue("Calories Burned")),
WatchItem(title: "Sleep", value: getLatestValue("Sleep")),
WatchItem(title: "Heart Rate", value: getLatestValue("Heart Rate")),

    ],
  ),
),

            const SizedBox(height: 30),

            /// Health Locker
            const Text(
              "Health Locker",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                LockerItem(
                  icon: Icons.science,
                  title: "Lab Reports",
                  color: Colors.blue,
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LabReportsPage(),
                      ),
                    );

                  },
                ),

                LockerItem(
                  icon: Icons.description,
                  title: "Prescriptions",
                  color: Colors.purple,
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrescriptionsPage(),
                      ),
                    );

                  },
                ),

                LockerItem(
                  icon: Icons.vaccines,
                  title: "Vaccines",
                  color: Colors.orange,
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VaccinesPage(),
                      ),
                    );

                  },
                ),

              ],
            ),

            const SizedBox(height: 30),

            /// Sharing Activity
            const Text(
              "Sharing Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

           Column(
  children: pendingConsents.map((consent) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 6,
          )
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                consent.doctor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Text(
                consent.request,
                style: const TextStyle(color: Colors.grey),
              ),

            ],
          ),

          ElevatedButton(
            onPressed: () async {

              await ApiService.approveConsent(consent.id);

              setState(() {
                pendingConsents.removeWhere((c) => c.id == consent.id);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Consent Approved"),
                ),
              );

            },
            child: const Text("Approve"),
          )

        ],
      ),
    );

  }).toList(),
),

            const SizedBox(height: 30),

            /// Recent Records
            const Text(
              "Recent Records",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...records.reversed.take(5).map((record) {

              return ListTile(
                leading: Icon(
  record.category == "lab_report"
      ? Icons.science
      : record.category == "prescription"
          ? Icons.description
          : record.category == "vaccination"
              ? Icons.vaccines
              : Icons.monitor_heart,
),
                title: Text(record.recordName ?? record.type),
                subtitle: Text(record.category),
              );

            }).toList(),

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddHealthRecordSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String getUnit(String title) {

    switch(title){

      case "Blood Pressure":
        return "mmHg";

      case  "Blood Sugar":
        return "mg/dL";

      case "Body Temperature":
        return "°C";

      case "Pulse Rate":
        return "BPM";

      case "Weight":
        return "kg";

      case "Oxygen Saturation":
        return "%";

      case "Respiration Rate":
        return "breaths/min";

      default:
        return "";
    }

  }
}

////////////////////////////////////////////////////////
/// Vital Card
////////////////////////////////////////////////////////

class VitalCard extends StatelessWidget {

  final String title;
  final String value;

  const VitalCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(title),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}
class WatchItem extends StatelessWidget {

  final String title;
  final String value;

  const WatchItem({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  String getUnit() {
    switch (title) {
      case "Steps":
        return "steps";
      case "Distance":
        return "km";
      case "Calories Burned":
        return "cal";
      case "Sleep":
        return "hrs";
      case "Heart Rate":
        return "BPM";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VitalDetailScreen(
              title: title,
              unit: getUnit(),
            ),
          ),
        );
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),

            Row(
              children: [

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),

              ],
            )

          ],
        ),
      ),
    );
  }
}

    
////////////////////////////////////////////////////////
/// Locker Item
////////////////////////////////////////////////////////

class LockerItem extends StatelessWidget {

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const LockerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,

      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(height: 8),

          Text(title),

        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// Extra Pages
////////////////////////////////////////////////////////


class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Vitals History Page")),
    );
  }
}

class AddHealthRecordSheet extends StatelessWidget {
  const AddHealthRecordSheet({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.75,

      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Add Health Records
            const Text(
              "Add Health Records",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                recordButton(context, Icons.science, "Lab Reports"),
                recordButton(context, Icons.description, "Upload Prescription"),
                recordButton(context, Icons.note, "Doctor Notes"),
                recordButton(context, Icons.vaccines, "Vaccination"),
                recordButton(context, Icons.receipt_long, "Medical Expense"),

              ],
            ),

            const SizedBox(height: 30),

            /// Add Health Data
            
               const Text(
                  "Add Health Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),


            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                dataCard(context, Icons.monitor_heart, "Blood Pressure"),
                dataCard(context, Icons.bloodtype,  "Blood Sugar"),
                dataCard(context, Icons.thermostat, "Body Temperature"),
                dataCard(context, Icons.favorite, "Pulse Rate"),
                dataCard(context, Icons.monitor_weight, "Weight"),
                dataCard(context, Icons.air, "Oxygen Saturation"),
                dataCard(context, Icons.health_and_safety, "Respiration Rate"),

              ],
            ),

          ],
        ),
      ),
    );
  }

  /// Record Upload Buttons
  Widget recordButton(BuildContext context, IconData icon, String title) {

    return GestureDetector(
      onTap: () async {

   await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UploadRecordScreen(
      title: title,
      ),
  ),
);
      
if(context.mounted){
  (context as Element).markNeedsBuild();
}

},

      child: Container(
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
      ),
    );
  }

  /// Health Data Cards
  Widget dataCard(BuildContext context, IconData icon, String title) {

    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthInputScreen(
              title: title,
              unit: _getUnit(title),
            ),
          ),
        );

      },
      child: Container(
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
    ),
  );
}
Future pickFile() async {

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
  );

  if (result != null) {

    String filePath = result.files.single.path!;
    String fileName = result.files.single.name;

    print("Selected file: $fileName");

  } else {
    print("User canceled");
  }
}


String _getUnit(String title) {

    switch(title){

      case "Blood Pressure":
        return "mmHg";

      case "Post Prandial Sugar":
      case "Fasting Blood Sugar":
      case "Random Blood Sugar":
        return "mg/dL";

      case "Body Temperature":
        return "°C";

      case "Pulse Rate":
        return "BPM";

      case "Weight":
        return "kg";

      case "Oxygen Saturation":
        return "%";

      case "Respiration Rate":
        return "breaths/min";

      default:
        return "";
    }

  }
}