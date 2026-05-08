import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/model/auth/login_request_model.dart';
import 'package:zen_hr/model/auth/login_response_model.dart';
import 'package:zen_hr/model/auth/register_request_model.dart';
import 'package:zen_hr/model/auth/register_response_model.dart';

String get baseUrl => dotenv.env['baseApiUrl'] ?? '';

class AuthApiService {
  /// ------------------- Token Management -------------------
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.userIdKey);
  }

  /// ------------------- Internet Check -------------------
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on Exception {
      return false;
    }
  }

  // Validate current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
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
  
  static Future<String?> getCurrentUserRole() async {
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
  
  // Register new emp
  static Future<RegisterResponseModel> registerEmployee(RegisterRequestModel request) async {
    try {
      final token = await getToken();
      if (token == null) return RegisterResponseModel(success: false);

      final res = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(res.body);
      return RegisterResponseModel.fromJson(data);
    } catch (e) {
      return RegisterResponseModel(success: false);
    }
  }
  
  // Login
  static Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      final loginResponse = LoginResponseModel.fromJson(data);

      if (loginResponse.success == true &&
          loginResponse.token != null &&
          loginResponse.user != null) {
        await saveToken(loginResponse.token!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.userIdKey, loginResponse.user!.id ?? 0);
        await prefs.setString(AppConstants.nameKey, loginResponse.user!.name ?? '');
        await prefs.setString(AppConstants.emailKey, loginResponse.user!.email ?? '');
        await prefs.setString(AppConstants.mobileKey, loginResponse.user!.mobile ?? '');
        await prefs.setInt(AppConstants.roleIdKey, loginResponse.user!.roleId ?? 0);
        await prefs.setString(AppConstants.roleKey, loginResponse.user!.role?.toLowerCase() ?? '');
        return loginResponse;
      } else {
        return LoginResponseModel(success: false, message: loginResponse.message ?? "Login failed");
      }
    } catch (e) {
      return LoginResponseModel(success: false, message: "Network error: ${e.toString()}");
    }
  }

  // Get all roles
  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse("$baseUrl/auth/roles"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["roles"] != null) {
          return List<Map<String, dynamic>>.from(data["roles"]);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get users by roles
  static Future<List<Map<String, dynamic>>> getUsersByRoles(String roles) async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse("$baseUrl/auth/users?role=$roles"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true && data["users"] != null) {
          return List<Map<String, dynamic>>.from(data["users"]);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
