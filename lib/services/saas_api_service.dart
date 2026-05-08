import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:zen_hr/services/auth_api_service.dart';

String get baseUrl => dotenv.env['baseApiUrl'] ?? '';

class SaasApiService {
  // Super Admin: Get all companies
  static Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse("$baseUrl/saas/companies"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["data"] != null) {
          return List<Map<String, dynamic>>.from(data["data"]);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Super Admin: Create new company
  static Future<Map<String, dynamic>> createCompany(Map<String, dynamic> request) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return {"success": false, "message": "Unauthorized"};
      final res = await http.post(
        Uri.parse("$baseUrl/saas/create-company"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(request),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // Super Admin: Update company
  static Future<Map<String, dynamic>> updateCompany(Map<String, dynamic> request) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return {"success": false, "message": "Unauthorized"};
      final res = await http.put(
        Uri.parse("$baseUrl/saas/update-company"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(request),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // Super Admin: Delete company
  static Future<Map<String, dynamic>> deleteCompany(int companyId) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return {"success": false, "message": "Unauthorized"};
      final res = await http.delete(
        Uri.parse("$baseUrl/saas/delete-company/$companyId"),
        headers: {"Authorization": "Bearer $token"},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
