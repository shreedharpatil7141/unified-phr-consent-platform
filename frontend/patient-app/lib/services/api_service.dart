import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const baseUrl = "http://10.63.72.14:8000";

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

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);

      print("TOKEN SAVED: $token");

      return data;

    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  //////////////////////////////////////////////////////
  /// REGISTER
  //////////////////////////////////////////////////////

  static Future register(String name, String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": "patient"
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

  static Future uploadRecord(String filePath, String fileName) async {

    String? token = await getToken();

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/health/upload"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        filePath,
        filename: fileName,
      ),
    );

    var response = await request.send();

    print("UPLOAD STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Upload failed");
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

}