import 'package:flutter/material.dart';
import '../models/consent_model.dart';
import '../services/consent_repository.dart';
import '../widgets/consent_card.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 3,
      child: Scaffold(

        appBar: AppBar(
          title: const Text("Consent Manager"),
          centerTitle: true,
          elevation: 2,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "Pending"),
              Tab(icon: Icon(Icons.verified), text: "Active"),
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            PendingConsents(),
            ActiveConsents(),
            ConsentHistory(),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// PENDING CONSENTS
////////////////////////////////////////////////////

class PendingConsents extends StatefulWidget {
  const PendingConsents({super.key});

  @override
  State<PendingConsents> createState() => _PendingConsentsState();
}

class _PendingConsentsState extends State<PendingConsents> {

  List<Consent> consents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadConsents();
  }

  Future loadConsents() async {

  try {

    final data = await ConsentRepository.fetchConsents();

    consents = data.where((c) => c.status == "pending").toList();

  } catch (e) {

    print("CONSENT LOAD ERROR: $e");

    consents = [];

  }

  setState(() {
    loading = false;
  });

}

  Future approve(String id) async {

    await ConsentRepository.approve(id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Consent approved"))
    );

    loadConsents();
  }

  Future reject(String id) async {

    await ConsentRepository.reject(id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Consent rejected"))
    );

    loadConsents();
  }

  @override
  Widget build(BuildContext context) {

    if(loading){
      return const Center(child: CircularProgressIndicator());
    }

    if(consents.isEmpty){
      return const Center(
        child: Text(
          "No pending consent requests",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(

      onRefresh: loadConsents,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consents.length,

        itemBuilder: (context,index){

          final consent = consents[index];

          return ConsentCard(
            consentId: consent.id,
            doctor: consent.doctor,
            request: consent.request,
            duration: consent.duration,
            showActions: true,

            onApprove: () => approve(consent.id),
            onReject: () => reject(consent.id),
          );

        },
      ),
    );
  }
}

////////////////////////////////////////////////////
/// ACTIVE CONSENTS
////////////////////////////////////////////////////

class ActiveConsents extends StatefulWidget {
  const ActiveConsents({super.key});

  @override
  State<ActiveConsents> createState() => _ActiveConsentsState();
}

class _ActiveConsentsState extends State<ActiveConsents> {

  List<Consent> active = [];

  @override
  void initState() {
    super.initState();
    loadActive();
  }

  Future loadActive() async {

    final data = await ConsentRepository.fetchConsents();

    active = data.where((c) => c.status == "approved").toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if(active.isEmpty){
      return const Center(
        child: Text(
          "No active consents",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(

      onRefresh: loadActive,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: active.length,

        itemBuilder: (context,index){

          final consent = active[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),

            child: ListTile(

              leading: const Icon(
                Icons.verified,
                color: Colors.green,
              ),

              title: Text(consent.doctor),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Request: ${consent.request}"),
                  Text("Duration: ${consent.duration} min"),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////
/// CONSENT HISTORY
////////////////////////////////////////////////////

class ConsentHistory extends StatefulWidget {
  const ConsentHistory({super.key});

  @override
  State<ConsentHistory> createState() => _ConsentHistoryState();
}

class _ConsentHistoryState extends State<ConsentHistory> {

  List<Consent> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future loadHistory() async {

    final data = await ConsentRepository.fetchConsents();

    history = data
        .where((c) => c.status == "rejected" || c.status == "revoked")
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if(history.isEmpty){
      return const Center(
        child: Text(
          "No consent history",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(

      onRefresh: loadHistory,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,

        itemBuilder: (context,index){

          final consent = history[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),

            child: ListTile(

              leading: const Icon(
                Icons.cancel,
                color: Colors.red,
              ),

              title: Text(consent.doctor),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Request: ${consent.request}"),
                  Text("Duration: ${consent.duration} min"),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}