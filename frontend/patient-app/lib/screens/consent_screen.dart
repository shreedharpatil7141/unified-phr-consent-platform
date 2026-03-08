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
          title: const Text("Consent"),
          bottom: const TabBar(
            tabs: [

              Tab(text: "Pending"),
              Tab(text: "Active"),
              Tab(text: "History"),

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

///////////////////////////////////////////////////////
/// Pending Consents
///////////////////////////////////////////////////////

class PendingConsents extends StatefulWidget {
  const PendingConsents({super.key});

  @override
  State<PendingConsents> createState() => _PendingConsentsState();
}

class _PendingConsentsState extends State<PendingConsents> {

  List<Consent> consents = [];

  @override
  void initState() {
    super.initState();
    loadConsents();
  }

  void loadConsents(){

    consents = ConsentRepository
        .getAll()
        .where((c) => c.status == "pending")
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if(consents.isEmpty){
      return const Center(
        child: Text("No pending consent requests"),
      );
    }

    return ListView.builder(
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
        );

      },
    );
  }
}

///////////////////////////////////////////////////////
/// Active Consents
///////////////////////////////////////////////////////

class ActiveConsents extends StatelessWidget {
  const ActiveConsents({super.key});

  @override
  Widget build(BuildContext context) {

    final active = ConsentRepository
        .getAll()
        .where((c) => c.status == "active")
        .toList();

    if(active.isEmpty){
      return const Center(
        child: Text("No active consents"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,

      itemBuilder: (context,index){

        final consent = active[index];

        return ConsentCard(
          consentId: consent.id,
          doctor: consent.doctor,
          request: consent.request,
          duration: consent.duration,
          showActions: false,
        );

      },
    );
  }
}

///////////////////////////////////////////////////////
/// Consent History
///////////////////////////////////////////////////////

class ConsentHistory extends StatelessWidget {
  const ConsentHistory({super.key});

  @override
  Widget build(BuildContext context) {

    final history = ConsentRepository
        .getAll()
        .where((c) => c.status == "history")
        .toList();

    if(history.isEmpty){
      return const Center(
        child: Text("No consent history"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,

      itemBuilder: (context,index){

        final consent = history[index];

        return ConsentCard(
          consentId: consent.id,
          doctor: consent.doctor,
          request: consent.request,
          duration: consent.duration,
          showActions: false,
        );

      },
    );
  }
}