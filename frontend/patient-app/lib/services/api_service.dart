import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const baseUrl = "http://10.0.2.2:8000";

  /// LOGIN
  static Future login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Login failed");
    }
  }

  /// GET PATIENT RECORDS
  static Future getMyRecords(String token) async {

    final response = await http.get(
      Uri.parse("$baseUrl/data/my-records"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load records");
    }
  }

  /// GET PATIENT CONSENT REQUESTS
  static Future getMyConsents(String token) async {

    final response = await http.get(
      Uri.parse("$baseUrl/consent/my-requests"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch consents");
    }
  }

  /// APPROVE CONSENT
  static Future approveConsent(String consentId, String token) async {

    final response = await http.post(
      Uri.parse("$baseUrl/consent/$consentId/approve"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Consent approval failed");
    }
  }

  /// REJECT CONSENT
  static Future rejectConsent(String consentId, String token) async {

    final response = await http.post(
      Uri.parse("$baseUrl/consent/$consentId/reject"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Consent rejection failed");
    }
  }

  /// GENERIC CONSENT UPDATE (optional)
  static Future<void> sendConsent(String consentId, String status, String token) async {

    try {

      final endpoint = status == "approve"
          ? "$baseUrl/consent/$consentId/approve"
          : "$baseUrl/consent/$consentId/reject";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print('Consent updated successfully');
      } else {
        throw Exception('Failed to update consent: ${response.statusCode}');
      }

    } catch (e) {
      print('Error sending consent: $e');
      rethrow;
    }
  }

}