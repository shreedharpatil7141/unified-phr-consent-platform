import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const baseUrl = "http://192.168.0.104:8000";

  //////////////////////////////////////////////////////
  /// LOGIN
  //////////////////////////////////////////////////////

  static Future login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: {
        "username": email,
        "password": password
      },
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);
      String token = data["access_token"];
      String email = data["email"] ?? "";

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);
      await prefs.setString("email", email);
      await prefs.setString("name", data["name"] ?? "");
      await prefs.setBool("profile_complete", data["profile_complete"] ?? false);

      print("TOKEN SAVED: $token");
      print("EMAIL SAVED: $email");

      return data;

    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  //////////////////////////////////////////////////////
  /// REGISTER
  //////////////////////////////////////////////////////

  static Future register(String name, String email, String password) async {
    return registerWithProfile(
      name: name,
      email: email,
      password: password,
    );
  }

  static Future registerWithProfile({
    required String name,
    required String email,
    required String password,
    double? heightCm,
    double? weightKg,
    String? allergies,
    String? bloodGroup,
    String? chronicConditions,
    String? emergencyContact,
    String? gender,
    int? age,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": "patient",
        "height_cm": heightCm,
        "weight_kg": weightKg,
        "allergies": allergies,
        "blood_group": bloodGroup,
        "chronic_conditions": chronicConditions,
        "emergency_contact": emergencyContact,
        "gender": gender,
        "age": age,
      }),
    );

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Registration failed");
    }
  }

  //////////////////////////////////////////////////////
  /// UPLOAD RECORD
  //////////////////////////////////////////////////////

  static String resolveFileUrl(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) {
      return "";
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri != null && uri.hasScheme) {
      return fileUrl;
    }

    return "$baseUrl$fileUrl";
  }

  static Future<Map<String, dynamic>> uploadRecord({
    required String filePath,
    required String fileName,
    required String category,
    required String recordType,
    required String domain,
    String? provider,
    String? recordName,
    String? doctor,
    String? hospital,
    String? notes,
  }) async {

    String? token = await getToken();

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/health/upload"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // get the logged-in patient's email; field requires a non-null string
    String? email = await getUserEmail();
    if (email == null) {
      throw Exception('Cannot upload record: no user email available');
    }
    request.fields['patient_id'] = email;
    request.fields['category'] = category;
    request.fields['record_type'] = recordType;
    request.fields['domain'] = domain;
    if (provider != null && provider.isNotEmpty) {
      request.fields['provider'] = provider;
    }
    if (recordName != null && recordName.isNotEmpty) {
      request.fields['record_name'] = recordName;
    }
    if (doctor != null && doctor.isNotEmpty) {
      request.fields['doctor'] = doctor;
    }
    if (hospital != null && hospital.isNotEmpty) {
      request.fields['hospital'] = hospital;
    }
    if (notes != null && notes.isNotEmpty) {
      request.fields['notes'] = notes;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        filePath,
        filename: fileName,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("UPLOAD STATUS: ${response.statusCode}");
    print("UPLOAD BODY: $responseBody");

    if (response.statusCode != 200) {
      throw Exception("Upload failed: $responseBody");
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addHealthRecord({
    required String patientId,
    required String source,
    required String category,
    required String recordType,
    required String domain,
    required String value,
    required String unit,
    required DateTime timestamp,
    String? provider,
    String? notes,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/health/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "patient_id": patientId,
        "source": source,
        "category": category,
        "record_type": recordType,
        "type": recordType,
        "domain": domain,
        "provider": provider,
        "timestamp": timestamp.toIso8601String(),
        "metrics": [
          {
            "name": recordType,
            "value": double.tryParse(value) ?? 0,
            "unit": unit,
          }
        ],
        "value": value,
        "unit": unit,
        "notes": notes,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to add health record: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> syncWearableRecords(
    List<Map<String, dynamic>> records,
  ) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/health/sync-wearables"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "records": records,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to sync wearable records: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getVitalsSyncSummary() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/health/vitals-sync-summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to load vitals sync summary: ${response.body}");
    }
  }

  //////////////////////////////////////////////////////
  /// GET TOKEN
  //////////////////////////////////////////////////////

  static Future<String?> getToken() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    print("TOKEN FROM STORAGE: $token");

    return token;
  }

  //////////////////////////////////////////////////////
  /// USER INFO
  //////////////////////////////////////////////////////

  static Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("email");
  }

  static Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("name");
  }

  static Future<bool> isProfileComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("profile_complete") ?? false;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.get(
      Uri.parse("$baseUrl/user/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("name", data["name"] ?? "");
      await prefs.setBool("profile_complete", data["profile_complete"] ?? false);
      return data;
    }

    throw Exception("Failed to load profile");
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.put(
      Uri.parse("$baseUrl/user/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("name", data["name"] ?? "");
      await prefs.setBool("profile_complete", data["profile_complete"] ?? false);
      return data;
    }

    throw Exception("Failed to update profile");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("email");
    await prefs.remove("name");
    await prefs.remove("profile_complete");
  }

  //////////////////////////////////////////////////////
  /// GET PATIENT RECORDS
  //////////////////////////////////////////////////////

  static Future getMyRecords() async {

    String? token = await getToken();

    if (token == null) {
      throw Exception("User not logged in");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/data/my-records"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    print("RECORDS STATUS: ${response.statusCode}");
    print("RECORDS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load records");
    }
  }

  //////////////////////////////////////////////////////
  /// GET ALERTS
  //////////////////////////////////////////////////////

  static Future getAlerts() async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.get(
      Uri.parse("$baseUrl/alerts/my-alerts"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load alerts");
    }
  }

  //////////////////////////////////////////////////////
  /// GET CONSENT REQUESTS
  //////////////////////////////////////////////////////

  static Future getMyConsents() async {

    String? token = await getToken();

    if (token == null) {
      throw Exception("User not logged in");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/consent/my-requests"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    print("CONSENT STATUS: ${response.statusCode}");
    print("CONSENT BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch consents");
    }
  }

  //////////////////////////////////////////////////////
  /// APPROVE CONSENT
  //////////////////////////////////////////////////////

  static Future approveConsent(String consentId) async {

    String? token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/consent/$consentId/approve"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    print("APPROVE STATUS: ${response.statusCode}");
    print("APPROVE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Consent approval failed");
    }
  }

  //////////////////////////////////////////////////////
  /// REJECT CONSENT
  //////////////////////////////////////////////////////

  static Future rejectConsent(String consentId) async {

    String? token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/consent/$consentId/reject"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    print("REJECT STATUS: ${response.statusCode}");
    print("REJECT BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Consent rejection failed");
    }
  }

  //////////////////////////////////////////////////////
  /// NOTIFICATIONS
  //////////////////////////////////////////////////////

  static Future getNotifications() async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.get(
      Uri.parse("$baseUrl/notifications/my"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch notifications");
    }
  }

  static Future markNotificationRead(String id) async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("$baseUrl/notifications/mark-read/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to mark notification read");
    }
  }

  static Future<void> deleteNotification(String id) async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.delete(
      Uri.parse("$baseUrl/notifications/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete notification");
    }
  }

  static Future<void> deleteRecord(String recordId) async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.delete(
      Uri.parse("$baseUrl/health/record/$recordId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete record");
    }
  }

  //////////////////////////////////////////////////////
  /// AI INSIGHT
  //////////////////////////////////////////////////////

  static Future<Map<String, dynamic>> generateInsight({
    required String metric,
    required List<double> values,
    required String unit,
    required String rangeLabel,
  }) async {
    String? token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("$baseUrl/ai/insight"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "metric": metric,
        "values": values,
        "unit": unit,
        "range_label": rangeLabel,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to generate AI insight: ${response.body}");
    }
  }

}
