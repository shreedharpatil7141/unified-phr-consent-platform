class Consent {

  final String id;
  final String doctor;
  final String request;
  final String duration;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  String status; // pending, active, history

  Consent({
    required this.id,
    required this.doctor,
    required this.request,
    required this.duration,
    this.requestedAt,
    this.approvedAt,
    this.expiresAt,
    this.status = "pending",
  });

}
