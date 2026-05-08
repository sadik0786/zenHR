import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/services/auth_api_service.dart';

String get baseUrl => dotenv.env['baseApiUrl'] ?? '';

class UserApiService {
  // Get all employees (CEO & HR only)
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse("$baseUrl/user/employees"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["employees"] != null) {
          return List<Map<String, dynamic>>.from(data["employees"]);
        }
      }

      return [];
    } catch (e) {
      print("getAllEmployees error: $e");
      return [];
    }
  }

  // Validate current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await AuthApiService.getToken();
    if (token == null) return {"success": false, "error": "No token"};

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/auth/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["user"] != null) {
          return {"success": true, "user": data["user"]};
        }
        return {"success": false, "error": "User not found"};
      }

      return {"success": false, "error": "Server returned ${res.statusCode}"};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // GET roles (server already filters based on logged-in user's role)
  static Future<Map<String, dynamic>> getRoles() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "Authentication required"};
      }

      final res = await http
          .get(
            Uri.parse("$baseUrl/auth/roles"),
            headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data;
      } else {
        return {
          "success": false,
          "error": data['error'] ?? "Failed to fetch roles (${res.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // Get current logged-in user's profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return null;
      final res = await http
          .get(
            Uri.parse("$baseUrl/auth/profile"),
            headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["user"] != null) {
          return data["user"];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  //update mobile
  static Future<bool> updateMobile(String mobile) async {
    try {
      final token = await AuthApiService.getToken();

      final res = await http.post(
        Uri.parse("$baseUrl/auth/mobileUpdate"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"mobile": mobile}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("updateMobile error: $e");
      return false;
    }
  }

  // add profile photo
  static Future<String?> uploadAvatar(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("User token not found");

    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/auth/upload"));

    request.headers["Authorization"] = "Bearer $token";

    // Attach file
    request.files.add(await http.MultipartFile.fromPath("avatar", file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["url"];
    } else {
      throw Exception("Failed to upload avatar: ${response.body}");
    }
  }

  static Future<List<dynamic>> fetchEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse("$baseUrl/admin/employee"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return data["employees"] ?? [];
      }
      throw Exception(data["error"] ?? "Failed to fetch employees");
    } catch (e) {
      print("Error fetching employees: $e");
      rethrow;
    }
  }

  // delete employee (Admin or Superadmin)
  static Future<bool> deleteEmployee(int empId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return false;

    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/user/employee/$empId"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("Delete response: ${res.statusCode} -> ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["success"] == true;
      } else {
        final data = jsonDecode(res.body);
        print("Delete failed: ${data["error"]}");
      }
      return false;
    } catch (e) {
      print("Delete employee  error: $e");
      return false;
    }
  }
}
