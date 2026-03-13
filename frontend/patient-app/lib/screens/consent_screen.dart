import 'dart:async';

import 'package:flutter/material.dart';

import '../models/consent_model.dart';
import '../services/api_service.dart';
import '../services/app_refresh_notifier.dart';
import '../services/consent_repository.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> with WidgetsBindingObserver {
  List<Consent> consents = [];
  bool loading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadConsents();
    refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => loadConsents(showLoader: false));
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
    if (state == AppLifecycleState.resumed) {
      loadConsents(showLoader: false);
    }
  }

  void _handleExternalRefresh() {
    loadConsents(showLoader: false);
  }

  Future<void> loadConsents({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await ConsentRepository.fetchConsents();
      if (!mounted) return;
      setState(() {
        consents = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  List<Consent> get pending => consents.where((c) => c.status == "pending").toList();
  List<Consent> get active => consents.where((c) => c.status == "approved").toList()
    ..sort((a, b) => (a.expiresAt ?? DateTime(9999)).compareTo(b.expiresAt ?? DateTime(9999)));
  List<Consent> get history => consents.where((c) => c.status == "rejected" || c.status == "revoked" || c.status == "expired").toList();

  Future<void> approve(Consent consent) async {
    await ApiService.approveConsent(consent.id);
    await loadConsents(showLoader: false);
    AppRefreshNotifier.notify();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Consent approved")),
    );
  }

  Future<void> reject(Consent consent) async {
    await ApiService.rejectConsent(consent.id);
    await loadConsents(showLoader: false);
    AppRefreshNotifier.notify();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Consent rejected")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Consent Center"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _ConsentList(
                    emptyText: "No pending consent requests",
                    consents: pending,
                    showActions: true,
                    onApprove: approve,
                    onReject: reject,
                  ),
                  _ConsentList(
                    emptyText: "No active consents",
                    consents: active,
                  ),
                  _ConsentList(
                    emptyText: "No consent history",
                    consents: history,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ConsentList extends StatefulWidget {
  final List<Consent> consents;
  final String emptyText;
  final bool showActions;
  final Future<void> Function(Consent consent)? onApprove;
  final Future<void> Function(Consent consent)? onReject;

  const _ConsentList({
    required this.consents,
    required this.emptyText,
    this.showActions = false,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_ConsentList> createState() => _ConsentListState();
}

class _ConsentListState extends State<_ConsentList> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startOrStopTimer();
  }

  @override
  void didUpdateWidget(covariant _ConsentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startOrStopTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startOrStopTimer() {
    final hasActiveCountdown = widget.consents.any(
      (consent) => consent.status == "approved" && consent.expiresAt != null,
    );

    if (!hasActiveCountdown) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }

    if (_countdownTimer != null) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  String _countdown(DateTime? expiresAt) {
    if (expiresAt == null) return "No timer";
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return "Expired";
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    return "${hours}h ${minutes}m ${seconds}s left";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.consents.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    return RefreshIndicator(
      onRefresh: () async => AppRefreshNotifier.notify(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.consents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final consent = widget.consents[index];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDE9E7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        consent.doctor,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _StatusBadge(status: consent.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(consent.request, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniInfo(label: "Duration", value: "${consent.duration} min"),
                    if (consent.requestedAt != null)
                      _MiniInfo(label: "Requested", value: "${consent.requestedAt!.day}/${consent.requestedAt!.month} ${consent.requestedAt!.hour}:${consent.requestedAt!.minute.toString().padLeft(2, '0')}"),
                    if (consent.status == "approved")
                      _MiniInfo(label: "Remaining", value: _countdown(consent.expiresAt)),
                  ],
                ),
                if (widget.showActions) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => widget.onApprove?.call(consent),
                          child: const Text("Approve"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => widget.onReject?.call(consent),
                          child: const Text("Reject"),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      "approved" => const Color(0xFFDCFCE7),
      "pending" => const Color(0xFFFFF7ED),
      _ => const Color(0xFFF1F5F9),
    };
    final text = switch (status) {
      "approved" => const Color(0xFF15803D),
      "pending" => const Color(0xFFC2410C),
      _ => const Color(0xFF475569),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
