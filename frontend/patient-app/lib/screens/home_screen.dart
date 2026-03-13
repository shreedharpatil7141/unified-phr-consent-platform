import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

import '../models/consent_model.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';
import '../services/app_refresh_notifier.dart';
import '../services/health_record_repository.dart';
import '../services/health_service.dart';
import '../utils/server_time.dart';
import 'alerts_screen.dart';
import 'appointments_screen.dart';
import 'health_timeline_screen.dart';
import 'lab_reports_screen.dart';
import 'notifications_screen.dart';
import 'prescriptions_screen.dart';
import 'vaccines_screen.dart';
import 'vital_detail_screen.dart';
import 'vitals_graphs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final HealthService healthService = HealthService();

  List<HealthRecord> records = [];
  List<Consent> pendingConsents = [];
  List notifications = [];
  bool loading = true;
  bool _isRefreshing = false;
  bool _isSyncingWatchRecords = false;
  bool _isManualVitalsSyncing = false;
  String? _vitalsSyncStatus;
  String? _lastVitalsSyncAt;
  int _backendHeartRateCount = 0;
  int _backendVitalCount = 0;
  Timer? refreshTimer;
  static const _wearableBackfillDoneKey = "wearable_backfill_done";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeScreen();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => initializeScreen(showLoading: false),
    );
    AppRefreshNotifier.signal.addListener(_handleExternalRefresh);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    AppRefreshNotifier.signal.removeListener(_handleExternalRefresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isRefreshing) {
      initializeScreen(showLoading: false);
    }
  }

  void _handleExternalRefresh() {
    initializeScreen(showLoading: false);
  }

  Future<void> initializeScreen({bool showLoading = true}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    if (showLoading && mounted) {
      setState(() {
        loading = true;
      });
    }

    final watchData = await buildSmartwatchRecords();
    HealthRecordRepository.setWatchRecords(watchData);
    await HealthRecordRepository.loadFromServer();

    final consentData = await ApiService.getMyConsents();
    final fetchedNotifications = await ApiService.getNotifications();
    await refreshVitalsSyncStatus();

    final serverRecords = HealthRecordRepository.getAllRecords()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) {
      _isRefreshing = false;
      return;
    }

    setState(() {
      records = serverRecords;
      pendingConsents = consentData
          .map<Consent>((c) => Consent(
                id: c["consent_id"],
                doctor: c["doctor_id"],
                request: (c["categories"] as List<dynamic>).join(", "),
                duration: c["access_duration_minutes"].toString(),
                status: c["status"],
                requestedAt: parseServerTime(c["requested_at"]),
                approvedAt: parseServerTime(c["approved_at"]),
                expiresAt: parseServerTime(c["expires_at"]),
              ))
          .where((c) => c.status == "pending")
          .toList();
      notifications = fetchedNotifications;
      loading = false;
    });

    unawaited(syncWatchRecordsToBackend(watchData));
    _isRefreshing = false;
  }

  Future<void> refreshVitalsSyncStatus() async {
    try {
      final summary = await ApiService.getVitalsSyncSummary();
      final total = summary["total_vital_records"] ?? 0;
      final types = (summary["types"] as Map<String, dynamic>? ?? {});
      final heartRateCount =
          (types["heart_rate"]?["count"] ?? types["heart rate"]?["count"] ?? 0);
      final lastSyncRaw = summary["last_sync_at"]?.toString();
      final lastSyncAt = lastSyncRaw != null ? parseServerTime(lastSyncRaw) : null;
      _backendHeartRateCount = heartRateCount;
      _backendVitalCount = total;
      _lastVitalsSyncAt = lastSyncAt?.toString();
      _vitalsSyncStatus = "Backend synced vitals: $total total, heart rate: $heartRateCount";
    } catch (e) {
      _vitalsSyncStatus = "Vitals sync status unavailable";
    }
  }

  Future<List<HealthRecord>> buildSmartwatchRecords() async {
    final data = await healthService.getHealthData(
      startTime: DateTime.now().subtract(const Duration(days: 365)),
    );
    final recordsByType = <String, List<HealthRecord>>{};

    for (final point in data) {
      String type;
      String unit = "";
      if (point.type == HealthDataType.STEPS) {
        type = "Steps";
        unit = "steps";
      } else if (point.type == HealthDataType.HEART_RATE ||
          point.type == HealthDataType.RESTING_HEART_RATE) {
        type = "Heart Rate";
        unit = "bpm";
      } else if (point.type == HealthDataType.DISTANCE_DELTA) {
        type = "Distance";
        unit = "km";
      } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        type = "Calories Burned";
        unit = "kcal";
      } else if (point.type == HealthDataType.SLEEP_ASLEEP) {
        type = "Sleep";
        unit = "hours";
      } else {
        type = point.type.toString();
      }

      final rawValue = point.value.toString();
      final numericMatch = RegExp(r'[-+]?\d*\.?\d+').firstMatch(rawValue);
      final parsedValue = double.tryParse(numericMatch?.group(0) ?? "");
      if (parsedValue == null) continue;

      final normalizedValue = switch (point.type) {
        // Health Connect distance delta is meters; store internally as km.
        HealthDataType.DISTANCE_DELTA => parsedValue / 1000.0,
        // Some providers emit sleep in minutes.
        HealthDataType.SLEEP_ASLEEP => parsedValue > 24 ? parsedValue / 60.0 : parsedValue,
        _ => parsedValue,
      };
      final value = normalizedValue.toStringAsFixed(
        point.type == HealthDataType.DISTANCE_DELTA ? 3 : 2,
      );

      recordsByType.putIfAbsent(type, () => []).add(
            HealthRecord(
              id: "${type}_${point.dateFrom.millisecondsSinceEpoch}",
              category: "wearable",
              type: type,
              domain: type == "Heart Rate" ? "cardiac" : "wellness",
              value: value,
              unit: unit,
              source: "wearable",
              timestamp: point.dateFrom,
            ),
          );
    }

    return recordsByType.values.expand((records) => records).toList();
  }

  Future<void> syncWatchRecordsToBackend(List<HealthRecord> watchRecords) async {
    if (_isSyncingWatchRecords || watchRecords.isEmpty) return;
    _isSyncingWatchRecords = true;
    try {
      final payload = watchRecords.take(250).map((record) {
        return {
          "source": "smartwatch",
          "category": "vitals",
          "record_type": record.type,
          "domain": record.domain,
          "value": record.value,
          "unit": record.unit,
          "timestamp": record.timestamp.toIso8601String(),
          "provider": "Health Connect",
        };
      }).toList();
      await ApiService.syncWearableRecords(payload);
      await refreshVitalsSyncStatus();
      if (mounted) setState(() {});
    } catch (_) {
    } finally {
      _isSyncingWatchRecords = false;
    }
  }

  Future<void> syncVitalsNow() async {
    if (_isManualVitalsSyncing) return;
    setState(() {
      _isManualVitalsSyncing = true;
      _vitalsSyncStatus = "Syncing wearable vitals to backend...";
    });
    try {
      final watchData = await buildSmartwatchRecords();
      HealthRecordRepository.setWatchRecords(watchData);
      await syncWatchRecordsToBackend(watchData);
      await HealthRecordRepository.loadFromServer();
      if (!mounted) return;
      setState(() {
        records = HealthRecordRepository.getAllRecords()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wearable vitals synced to backend")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vitals sync failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isManualVitalsSyncing = false;
        });
      }
    }
  }

  String getLatestValue(String type) {
    final vitalRecords = records
        .where((r) => r.type == type && (r.source == "wearable" || r.source == "smartwatch"))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (vitalRecords.isEmpty) return "0";

    final now = DateTime.now();
    bool isSameDay(DateTime value) =>
        value.year == now.year && value.month == now.month && value.day == now.day;

    // Heart rate should reflect latest sample, not a daily sum.
    if (type == "Heart Rate") {
      final latest = vitalRecords.last;
      final latestValue = double.tryParse(latest.value) ?? 0;
      return latestValue.toStringAsFixed(0);
    }

    final todayRecords = vitalRecords.where((r) => isSameDay(r.timestamp)).toList();
    if (todayRecords.isEmpty) return "0";

    bool looksCumulative(List<double> values) {
      if (values.length < 3) return false;
      int nonDecreasing = 0;
      for (int i = 1; i < values.length; i++) {
        if (values[i] >= values[i - 1]) nonDecreasing++;
      }
      return nonDecreasing >= (values.length - 1) * 0.8;
    }

    if (type == "Steps") {
      final values = todayRecords
          .map((r) => double.tryParse(r.value) ?? 0)
          .where((v) => v > 0)
          .toList()
        ..sort();
      if (values.isEmpty) return "0";

      final value = looksCumulative(values)
          ? values.last
          : values.fold<double>(0, (sum, v) => sum + v);
      return value.toStringAsFixed(0);
    }

    if (type == "Distance") {
      final normalized = <double>[];
      for (final record in todayRecords) {
        var value = double.tryParse(record.value) ?? 0;
        final unit = record.unit.toLowerCase();
        if (unit == "m" || unit == "meter" || unit == "meters") {
          value = value / 1000.0;
        } else if (unit == "km" && value > 20) {
          // Backward compatibility: older app builds could save meter deltas as km.
          value = value / 1000.0;
        }
        normalized.add(value);
      }
      final cleaned = normalized.where((v) => v > 0).toList()..sort();
      if (cleaned.isEmpty) return "0";
      final value = looksCumulative(cleaned)
          ? cleaned.last
          : cleaned.fold<double>(0, (sum, v) => sum + v);
      return value.toStringAsFixed(2);
    }

    if (type == "Sleep") {
      final values = todayRecords
          .map((r) => double.tryParse(r.value) ?? 0)
          .where((v) => v > 0)
          .toList();
      if (values.isEmpty) return "0";
      final totalHours = values.fold<double>(0, (sum, value) => sum + value);
      return totalHours.toStringAsFixed(1);
    }

    final latest = todayRecords.last;
    return latest.value;
  }

  Future<void> deleteRecord(HealthRecord record) async {
    if (record.source == "smartwatch" || record.source == "wearable") return;
    await ApiService.deleteRecord(record.id);
    HealthRecordRepository.removeRecord(record.id);
    if (!mounted) return;
    setState(() {
      records.removeWhere((r) => r.id == record.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uploadedRecords = records.where((record) => (record.filePath ?? "").isNotEmpty).take(5).toList();
    final unreadNotifications = notifications.where((item) => item["read"] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Health"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Appointments",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthTimelineScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  initializeScreen(showLoading: false);
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      unreadNotifications.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => initializeScreen(showLoading: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Connected health overview",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your latest vitals, uploaded records, and doctor requests in one place.",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _TopStat(title: "Pending Requests", value: pendingConsents.length.toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _TopStat(title: "Uploaded Files", value: records.where((r) => (r.filePath ?? "").isNotEmpty).length.toString())),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Vitals overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _VitalCard(title: "Heart Rate", value: getLatestValue("Heart Rate"), unit: "BPM"),
                _VitalCard(title: "Steps", value: getLatestValue("Steps"), unit: "steps"),
                _VitalCard(title: "Distance", value: getLatestValue("Distance"), unit: "km"),
                _VitalCard(title: "Sleep", value: getLatestValue("Sleep"), unit: "hrs"),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE9E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Health Connect sync", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(_vitalsSyncStatus ?? "Vitals sync status unavailable"),
                  const SizedBox(height: 4),
                  Text("Last backend sync: ${_lastVitalsSyncAt ?? 'Not synced yet'}"),
                  Text("Heart-rate points synced: $_backendHeartRateCount"),
                  Text("Total vital points synced: $_backendVitalCount"),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isManualVitalsSyncing ? null : syncVitalsNow,
                    icon: _isManualVitalsSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(_isManualVitalsSyncing ? "Syncing..." : "Sync vitals now"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Health locker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickNavCard(
                    icon: Icons.science,
                    title: "Lab Reports",
                    subtitle: "PDFs and report images",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabReportsPage())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickNavCard(
                    icon: Icons.description,
                    title: "Prescriptions",
                    subtitle: "Doctor-issued documents",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionsPage())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickNavCard(
                    icon: Icons.vaccines,
                    title: "Vaccines",
                    subtitle: "Immunization records",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccinesPage())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickNavCard(
                    icon: Icons.show_chart,
                    title: "Vitals History",
                    subtitle: "View charts and trends",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VitalsGraphsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Sharing activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (pendingConsents.isEmpty)
              const Text("No pending doctor requests right now", style: TextStyle(color: Colors.black54))
            else
              ...pendingConsents.map(
                (consent) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDE9E7)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFD6F5EF),
                        child: Icon(Icons.verified_user, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(consent.doctor, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(consent.request, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await ApiService.approveConsent(consent.id);
                          AppRefreshNotifier.notify();
                          await initializeScreen(showLoading: false);
                        },
                        child: const Text("Approve"),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text("Recent uploaded records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (uploadedRecords.isEmpty)
              const Text("No uploaded records yet", style: TextStyle(color: Colors.black54))
            else
              ...uploadedRecords.map(
                (record) => Card(
                  child: ListTile(
                    leading: Icon(record.category == "lab_report" ? Icons.science : Icons.insert_drive_file_rounded),
                    title: Text(record.recordName ?? record.type),
                    subtitle: Text("${record.category} • ${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => deleteRecord(record),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String title;
  final String value;
  const _TopStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _VitalCard({required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE9E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE9E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFD6F5EF),
              child: Icon(icon, color: const Color(0xFF0F766E)),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
