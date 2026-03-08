import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_record_repository.dart';
import '../services/ai_service.dart';

class VitalDetailScreen extends StatefulWidget {

  final String title;
  final String unit;

  const VitalDetailScreen({
    super.key,
    required this.title,
    required this.unit,
  });

  @override
  State<VitalDetailScreen> createState() => _VitalDetailScreenState();
}

class _VitalDetailScreenState extends State<VitalDetailScreen> {

  String selectedRange = "year";
  String aiInsight = "Generating AI insight...";

  @override
  void initState() {
    super.initState();
    generateInsight();
  }

  //////////////////////////////////////////////////////
  /// RANGE FILTER
  //////////////////////////////////////////////////////

  DateTime getStartDate(){

    if(selectedRange == "week"){
      return DateTime.now().subtract(const Duration(days: 7));
    }

    if(selectedRange == "month"){
      return DateTime.now().subtract(const Duration(days: 30));
    }

    return DateTime.now().subtract(const Duration(days: 365));
  }

  //////////////////////////////////////////////////////
  /// GET RECORDS
  //////////////////////////////////////////////////////

  List getRecords(){

    return HealthRecordRepository.getRecordsByTypeAndRange(
        widget.title,
        getStartDate()
    );
  }

  //////////////////////////////////////////////////////
  /// GRAPH DATA
  //////////////////////////////////////////////////////

  List<FlSpot> generateSpots(){

    final records = getRecords();

    List<FlSpot> spots = [];

    for(int i=0;i<records.length;i++){

      double value =
          double.tryParse(records[i].value) ?? 0;

      spots.add(
        FlSpot(i.toDouble(), value),
      );
    }

    return spots;
  }

  //////////////////////////////////////////////////////
  /// VALUES FOR AI
  //////////////////////////////////////////////////////

  List<double> getValues(){

    final records = getRecords();

    return records
        .map((e)=>double.tryParse(e.value) ?? 0)
        .toList();
  }

  //////////////////////////////////////////////////////
  /// HEART RATE VARIATION DETECTION
  //////////////////////////////////////////////////////

  bool detectHeartRisk(){

    if(widget.title != "Heart Rate") return false;

    List<double> values = getValues();

    if(values.length < 5) return false;

    double maxValue = values.reduce((a,b)=>a>b?a:b);
    double minValue = values.reduce((a,b)=>a<b?a:b);

    double variation = maxValue - minValue;

    return variation > 40;
  }

  //////////////////////////////////////////////////////
  /// 3 MONTH TREND DETECTION
  //////////////////////////////////////////////////////

  bool detectThreeMonthTrend(){

    if(widget.title != "Heart Rate") return false;

    DateTime now = DateTime.now();

    DateTime month1 = now.subtract(const Duration(days: 90));
    DateTime month2 = now.subtract(const Duration(days: 60));
    DateTime month3 = now.subtract(const Duration(days: 30));

    final m1 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month1);
    final m2 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month2);
    final m3 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month3);

    double avg(List records){

      if(records.isEmpty) return 0;

      double sum = 0;

      for(var r in records){
        sum += double.tryParse(r.value) ?? 0;
      }

      return sum / records.length;
    }

    double avg1 = avg(m1);
    double avg2 = avg(m2);
    double avg3 = avg(m3);

    return avg1 < avg2 && avg2 < avg3;
  }

  //////////////////////////////////////////////////////
  /// OPENAI AI INSIGHT
  //////////////////////////////////////////////////////

  Future generateInsight() async {

    List<double> values = getValues();

    if(values.isEmpty){
      setState(() {
        aiInsight = "Not enough smartwatch data for analysis.";
      });
      return;
    }

    try{

      String result =
          await AIService.generateInsight(widget.title, values);

      setState(() {
        aiInsight = result;
      });

    }catch(e){

      setState(() {
        aiInsight = "AI insight unavailable.";
      });

    }

  }

  //////////////////////////////////////////////////////
  /// BUILD UI
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context){

    bool risk = detectHeartRisk();
    bool trendRisk = detectThreeMonthTrend();

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            //////////////////////////////////////////////////////
            /// RANGE BUTTONS
            //////////////////////////////////////////////////////

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                rangeButton("week"),
                rangeButton("month"),
                rangeButton("year"),

              ],
            ),

            const SizedBox(height: 20),

            //////////////////////////////////////////////////////
            /// GRAPH
            //////////////////////////////////////////////////////

            SizedBox(
              height: 220,

              child: LineChart(

                LineChartData(

                  gridData: FlGridData(show: true),

                  titlesData: FlTitlesData(show: true),

                  borderData: FlBorderData(show: true),

                  lineBarsData: [

                    LineChartBarData(

                      spots: generateSpots().isEmpty
                          ? [const FlSpot(0,0)]
                          : generateSpots(),

                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),

                    )

                  ],

                ),

              ),
            ),

            const SizedBox(height: 30),

            //////////////////////////////////////////////////////
            /// HEART VARIATION ALERT
            //////////////////////////////////////////////////////

            if(risk)

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Text(
                  "⚠ Significant heart rate variation detected in recent months. Consider scheduling a doctor appointment.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

            if(risk)
              const SizedBox(height: 20),

            //////////////////////////////////////////////////////
            /// 3 MONTH TREND ALERT
            //////////////////////////////////////////////////////

            if(trendRisk)

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.red.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Text(
                  "⚠ Your resting heart rate has been gradually increasing for the past 3 months. We recommend scheduling a cardiology consultation.",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            if(trendRisk)
              const SizedBox(height: 10),

            if(trendRisk)

              ElevatedButton.icon(

                icon: const Icon(Icons.calendar_month),

                label: const Text("Book Doctor Appointment"),

                onPressed: () {

                  Navigator.pushNamed(context, "/doctorDashboard");

                },

              ),

            const SizedBox(height: 20),

            //////////////////////////////////////////////////////
            /// AI INSIGHT
            //////////////////////////////////////////////////////

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Text(
                aiInsight,
                style: const TextStyle(fontSize: 15),
              ),
            )

          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// RANGE BUTTON
  //////////////////////////////////////////////////////

  Widget rangeButton(String value){

    bool active = selectedRange == value;

    return ElevatedButton(

      style: ElevatedButton.styleFrom(
        backgroundColor:
        active ? Colors.blue : Colors.grey.shade300,

        foregroundColor:
        active ? Colors.white : Colors.black,
      ),

      onPressed: (){

        setState(() {
          selectedRange = value;
        });

        generateInsight();

      },

      child: Text(value.toUpperCase()),
    );
  }

}