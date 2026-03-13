import '../services/api_service.dart';
import '../models/consent_model.dart';
import '../utils/server_time.dart';

class ConsentRepository {

  static List<Consent> _consents = [];

  //////////////////////////////////////////////////////
  /// FORMAT CATEGORY NAMES
  //////////////////////////////////////////////////////

  static String formatCategories(List categories) {

    Map<String,String> names = {
      "cardiology": "Cardiology",
      "hematology": "Hematology",
      "radiology": "Radiology",
      "lab_reports": "Lab Reports",
      "prescriptions": "Prescriptions",
      "vitals": "Vitals"
    };

    return categories
        .map((c) => names[c] ?? c)
        .join(", ");
  }

  //////////////////////////////////////////////////////
  /// FETCH CONSENTS FROM BACKEND
  //////////////////////////////////////////////////////

  static Future<List<Consent>> fetchConsents() async {

    final data = await ApiService.getMyConsents();

    if(data == null) {
      return [];
    }

    _consents = data.map<Consent>((c) {

      return Consent(
        id: c["consent_id"].toString(),
        doctor: c["doctor_id"] ?? "Unknown Doctor",
        request: formatCategories(c["categories"] ?? []),
        duration: (c["access_duration_minutes"] ?? 0).toString(),
        requestedAt: parseServerTime(c["requested_at"]),
        approvedAt: parseServerTime(c["approved_at"]),
        expiresAt: parseServerTime(c["expires_at"]),
        status: c["status"] ?? "pending",
      );

    }).toList();

    return _consents;
  }

  //////////////////////////////////////////////////////
  /// GET ALL CONSENTS (LOCAL CACHE)
  //////////////////////////////////////////////////////

  static List<Consent> getAll() {
    return _consents;
  }

  //////////////////////////////////////////////////////
  /// APPROVE CONSENT
  //////////////////////////////////////////////////////

  static Future approve(String id) async {

    await ApiService.approveConsent(id);

    final index = _consents.indexWhere((c) => c.id == id);

    if(index != -1){
      _consents[index].status = "approved";
    }

  }

  //////////////////////////////////////////////////////
  /// REJECT CONSENT
  //////////////////////////////////////////////////////

  static Future reject(String id) async {

    await ApiService.rejectConsent(id);

    final index = _consents.indexWhere((c) => c.id == id);

    if(index != -1){
      _consents[index].status = "rejected";
    }

  }

}
