import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/health_record.dart';
import '../services/ai_service.dart';
import '../services/health_record_repository.dart';

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

class _ChartBucket {
  final DateTime start;
  final DateTime end;
  final List<double> values;

  const _ChartBucket({
    required this.start,
    required this.end,
    required this.values,
  });

  double get min => values.reduce((a, b) => a < b ? a : b);
  double get max => values.reduce((a, b) => a > b ? a : b);
  double get avg => values.reduce((a, b) => a + b) / values.length;
  double get latest => values.last;
}

class _VitalDetailScreenState extends State<VitalDetailScreen> {
  String selectedRange = "day";
  String aiInsight = "Generating AI insight...";

  @override
  void initState() {
    super.initState();
    generateInsight();
  }

  bool get _isHeartRate => widget.title.toLowerCase() == "heart rate";

  Color get _accentColor {
    final title = widget.title.toLowerCase();
    if (title.contains("heart")) return const Color(0xFFFF6B81);
    if (title.contains("step")) return const Color(0xFF4ADE80);
    if (title.contains("distance")) return const Color(0xFFFACC15);
    return const Color(0xFF60A5FA);
  }

  Color get _accentGlow => _accentColor.withOpacity(0.22);

  DateTime getStartDate() {
    final now = DateTime.now();

    switch (selectedRange) {
      case "day":
        return DateTime(now.year, now.month, now.day);
      case "week":
        return now.subtract(const Duration(days: 6));
      case "month":
        return now.subtract(const Duration(days: 29));
      case "year":
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  List<HealthRecord> getRecords() {
    final records = HealthRecordRepository.getRecordsByTypeAndRange(
      widget.title,
      getStartDate(),
    );
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }

  double _parseValue(HealthRecord record) {
    return double.tryParse(record.value) ?? 0;
  }

  List<double> getValues() {
    return getRecords().map(_parseValue).where((value) => value > 0).toList();
  }

  DateTime _bucketStart(DateTime timestamp) {
    switch (selectedRange) {
      case "day":
        return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
          timestamp.hour,
        );
      case "week":
        return DateTime(timestamp.year, timestamp.month, timestamp.day);
      case "month":
        return DateTime(timestamp.year, timestamp.month, timestamp.day);
      case "year":
        return DateTime(timestamp.year, timestamp.month);
      default:
        return DateTime(timestamp.year, timestamp.month, timestamp.day);
    }
  }

  DateTime _bucketEnd(DateTime start) {
    switch (selectedRange) {
      case "day":
        return start.add(const Duration(hours: 1));
      case "week":
        return start.add(const Duration(days: 1));
      case "month":
        return start.add(const Duration(days: 1));
      case "year":
        return DateTime(start.year, start.month + 1);
      default:
        return start.add(const Duration(days: 1));
    }
  }

  List<_ChartBucket> _buildBuckets(List<HealthRecord> records) {
    final grouped = <DateTime, List<double>>{};

    for (final record in records) {
      final value = _parseValue(record);
      if (value <= 0) {
        continue;
      }
      final bucket = _bucketStart(record.timestamp);
      grouped.putIfAbsent(bucket, () => []).add(value);
    }

    final buckets = grouped.entries
        .map(
          (entry) => _ChartBucket(
            start: entry.key,
            end: _bucketEnd(entry.key),
            values: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return buckets;
  }

  List<FlSpot> _generateSpots(List<_ChartBucket> buckets) {
    return List.generate(
      buckets.length,
      (index) => FlSpot(index.toDouble(), buckets[index].avg),
    );
  }

  double _summaryCurrent(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return 0;
    return buckets.last.latest;
  }

  double _summaryAverage(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return 0;
    final values = buckets.map((bucket) => bucket.avg).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _summaryMin(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return 0;
    return buckets.map((bucket) => bucket.min).reduce((a, b) => a < b ? a : b);
  }

  double _summaryMax(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return 0;
    return buckets.map((bucket) => bucket.max).reduce((a, b) => a > b ? a : b);
  }

  double getMinY(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return 0;
    final minValue = _summaryMin(buckets);
    final padding = _isHeartRate ? 8.0 : (minValue == 0 ? 1.0 : minValue * 0.15);
    return (minValue - padding).clamp(0, double.infinity);
  }

  double getMaxY(List<_ChartBucket> buckets) {
    if (buckets.isEmpty) return _isHeartRate ? 120 : 10;
    final maxValue = _summaryMax(buckets);
    final padding = _isHeartRate ? 8.0 : (maxValue == 0 ? 1.0 : maxValue * 0.15);
    return maxValue + padding;
  }

  double _leftAxisInterval(List<_ChartBucket> buckets) {
    if (_isHeartRate) {
      return 10;
    }

    final span = getMaxY(buckets) - getMinY(buckets);
    if (span <= 5) return 1;
    if (span <= 20) return 5;
    if (span <= 100) return 10;
    return span / 4;
  }

  String _rangeLabel() {
    final now = DateTime.now();

    switch (selectedRange) {
      case "day":
        return DateFormat('EEEE, d MMMM yyyy').format(now);
      case "week":
        final start = getStartDate();
        return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(now)}';
      case "month":
        return DateFormat('MMMM yyyy').format(now);
      case "year":
        return DateFormat('yyyy').format(now);
      default:
        return DateFormat('d MMM yyyy').format(now);
    }
  }

  String _bottomAxisLabel(DateTime timestamp) {
    switch (selectedRange) {
      case "day":
        return DateFormat('h a').format(timestamp).toLowerCase();
      case "week":
        return DateFormat('E').format(timestamp);
      case "month":
        return DateFormat('d MMM').format(timestamp);
      case "year":
        return DateFormat('MMM').format(timestamp);
      default:
        return DateFormat('d MMM').format(timestamp);
    }
  }

  String _tooltipLabel(_ChartBucket bucket) {
    switch (selectedRange) {
      case "day":
        return DateFormat('d MMM, h a').format(bucket.start);
      case "week":
        return DateFormat('EEE, d MMM').format(bucket.start);
      case "month":
        return DateFormat('d MMM yyyy').format(bucket.start);
      case "year":
        return DateFormat('MMMM yyyy').format(bucket.start);
      default:
        return DateFormat('d MMM yyyy').format(bucket.start);
    }
  }

  bool detectHeartRisk() {
    if (!_isHeartRate) return false;

    final values = getValues();
    if (values.length < 5) return false;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    return (maxValue - minValue) > 40;
  }

  bool detectThreeMonthTrend() {
    if (!_isHeartRate) return false;

    final now = DateTime.now();
    final month1 = now.subtract(const Duration(days: 90));
    final month2 = now.subtract(const Duration(days: 60));
    final month3 = now.subtract(const Duration(days: 30));

    final m1 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month1);
    final m2 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month2);
    final m3 = HealthRecordRepository.getRecordsByTypeAndRange(widget.title, month3);

    double avg(List<HealthRecord> records) {
      if (records.isEmpty) return 0;
      var sum = 0.0;
      for (final record in records) {
        sum += _parseValue(record);
      }
      return sum / records.length;
    }

    final avg1 = avg(m1);
    final avg2 = avg(m2);
    final avg3 = avg(m3);

    return avg1 < avg2 && avg2 < avg3;
  }

  Future<void> generateInsight() async {
    final values = getValues();

    if (values.isEmpty) {
      setState(() {
        aiInsight = "Not enough smartwatch data for analysis.";
      });
      return;
    }

    try {
      final result = await AIService.generateInsight(
        widget.title,
        values,
        unit: widget.unit,
        rangeLabel: _rangeLabel(),
      );
      if (!mounted) return;
      setState(() {
        aiInsight = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        aiInsight = "AI insight unavailable.";
      });
    }
  }

  Widget statChip(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget rangeButton(String value) {
    final active = selectedRange == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRange = value;
        });
        generateInsight();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? Colors.white : Colors.white12,
          ),
        ),
        child: Text(
          value[0].toUpperCase() + value.substring(1),
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = getRecords();
    final buckets = _buildBuckets(records);
    final spots = _generateSpots(buckets);
    final risk = detectHeartRisk();
    final trendRisk = detectThreeMonthTrend();

    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090B10),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _rangeLabel(),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_summaryCurrent(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average ${_summaryAverage(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                statChip("Current", '${_summaryCurrent(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}'),
                statChip("Average", '${_summaryAverage(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}'),
                statChip("Minimum", '${_summaryMin(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}'),
                statChip("Maximum", '${_summaryMax(buckets).toStringAsFixed(_isHeartRate ? 0 : 2)} ${widget.unit}'),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF12151D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: _accentGlow,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: 320,
                  width: constraints.maxWidth,
                  child: buckets.isEmpty
                      ? Center(
                          child: Text(
                            "No Health Connect data available for this metric",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        )
                      : LineChart(
                        LineChartData(
                          minY: getMinY(buckets),
                          maxY: getMaxY(buckets),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _leftAxisInterval(buckets),
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.white.withOpacity(0.08),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                interval: _leftAxisInterval(buckets),
                                getTitlesWidget: (value, meta) => Text(
                                  value.toStringAsFixed(_isHeartRate ? 0 : 2),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: buckets.length > 6
                                    ? (buckets.length / 5).ceilToDouble()
                                    : 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= buckets.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      _bottomAxisLabel(buckets[index].start),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withOpacity(0.12)),
                              right: BorderSide(color: Colors.white.withOpacity(0.12)),
                              left: BorderSide.none,
                              top: BorderSide.none,
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 14,
                              getTooltipColor: (_) => const Color(0xFF0D1016),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final bucket = buckets[spot.x.toInt()];
                                  final rangeText = _tooltipLabel(bucket);
                                  final avgText = bucket.avg.toStringAsFixed(_isHeartRate ? 0 : 2);
                                  final minText = bucket.min.toStringAsFixed(_isHeartRate ? 0 : 2);
                                  final maxText = bucket.max.toStringAsFixed(_isHeartRate ? 0 : 2);
                                  return LineTooltipItem(
                                    '$rangeText\nAvg $avgText ${widget.unit}\nMin $minText  Max $maxText',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.28,
                              color: _accentColor,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    _accentColor.withOpacity(0.24),
                                    _accentColor.withOpacity(0.02),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                  radius: 3.8,
                                  color: const Color(0xFF12151D),
                                  strokeWidth: 2.4,
                                  strokeColor: _accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                rangeButton("day"),
                rangeButton("week"),
                rangeButton("month"),
                rangeButton("year"),
              ],
            ),
            const SizedBox(height: 26),
            if (risk)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF251317),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.30)),
                ),
                child: const Text(
                  "Significant heart rate variation detected in recent data. Consider scheduling a doctor appointment.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (risk) const SizedBox(height: 16),
            if (trendRisk)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF30181A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.35)),
                ),
                child: const Text(
                  "Your resting heart rate has been gradually increasing over the past 3 months. We recommend scheduling a cardiology consultation.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (trendRisk) const SizedBox(height: 12),
            if (trendRisk)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text("Book Doctor Appointment"),
                onPressed: () {
                  Navigator.pushNamed(context, "/doctorDashboard");
                },
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                aiInsight,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
