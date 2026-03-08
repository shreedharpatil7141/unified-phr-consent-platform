import '../models/consent_model.dart';

class ConsentRepository {

  static final List<Consent> _consents = [

    Consent(
      id: "1",
      doctor: "Dr Mehta",
      request: "Cardiology Reports",
      duration: "1 hour",
      status: "pending",
    ),

    Consent(
      id: "2",
      doctor: "Dr Sharma",
      request: "Prescription History",
      duration: "Completed",
      status: "history",
    ),

    Consent(
      id: "3",
      doctor: "Dr Rao",
      request: "Lab Reports",
      duration: "40 mins",
      status: "active",
    ),

  ];

  static List<Consent> getAll(){
    return _consents;
  }

  static void approve(String id){

    final index = _consents.indexWhere((c) => c.id == id);

    if(index != -1){
      _consents[index].status = "active";
    }

  }

  static void reject(String id){

    _consents.removeWhere((c) => c.id == id);

  }

}