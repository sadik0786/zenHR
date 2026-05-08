import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:zen_hr/services/auth_api_service.dart';

import 'package:zen_hr/model/hrms/leave_apply_request_model.dart';

String get baseUrl => dotenv.env['baseApiUrl'] ?? '';

class HrmsApiService {
  // add leave type
  static Future<Map<String, dynamic>> addLeaveType({
    required String leaveName,
    required int leaveCount,
  }) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "No token found"};
      }
      final res = await http.post(
        Uri.parse("$baseUrl/hrms/leave-types"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"leaveName": leaveName, "leaveCount": leaveCount}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // get all leaves type
  static Future<List<dynamic>> fetchAllLeaveTypes() async {
    final token = await AuthApiService.getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/hrms/leave-types"),
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["success"] == true) {
      return data["data"] ?? [];
    }
    throw Exception(data["error"] ?? "Failed to fetch leave");
  }

  // apply leave
  static Future<Map<String, dynamic>> applyLeave(LeaveApplyRequestModel model) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "No token found"};
      }
      final res = await http.post(
        Uri.parse("$baseUrl/hrms/apply-leave"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(model.toJson()),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<List<dynamic>> fetchMyAppliedLeaves() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) throw Exception("No token found");

      final res = await http.get(
        Uri.parse("$baseUrl/hrms/my-leaves"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        return data["data"];
      } else {
        throw data["message"] ?? "Failed to fetch leaves";
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> fetchOtherLeaves() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) throw Exception("No token found");

      final res = await http.get(
        Uri.parse("$baseUrl/hrms/other-leaves"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        return data["data"];
      } else {
        throw data["message"] ?? "Failed to fetch other leaves";
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateLeaveStatus(
    int leaveId,
    String status,
    String remarks,
  ) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) return {"success": false, "error": "No token found"};

      final res = await http.put(
        Uri.parse("$baseUrl/hrms/update-leave-status/$leaveId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"status": status, "remarks": remarks}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }
}
