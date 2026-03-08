class Consent {

  final String id;
  final String doctor;
  final String request;
  final String duration;

  String status; // pending, active, history

  Consent({
    required this.id,
    required this.doctor,
    required this.request,
    required this.duration,
    this.status = "pending",
  });

}