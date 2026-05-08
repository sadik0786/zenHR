import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/services/auth_api_service.dart';

String get baseUrl => dotenv.env['baseApiUrl'] ?? '';

class TaskApiService {
  // NEW: Get Tasks with Hierarchy
  static Future<Map<String, dynamic>> getTasks() async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "Authentication required"};
      }

      final res = await http
          .get(
            Uri.parse("$baseUrl/tasks"),
            headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data;
      } else {
        return {
          "success": false,
          "error": data['error'] ?? "Failed to fetch tasks (${res.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // NEW: Create Task
  static Future<Map<String, dynamic>> createTask({
    required int projectId,
    required int subProjectId,
    required String title,
    required String taskDetails,
    required String mode,
    required String status,
    required String startDate,
    required String endDate,
    required int createdBy,
  }) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "Authentication required"};
      }

      final taskData = {
        "ProjectID": projectId,
        "SubProjectID": subProjectId,
        "title": title.trim(),
        "taskDetails": taskDetails.trim(),
        "mode": mode,
        "status": status,
        "startDate": startDate,
        "endDate": endDate,
        "CreatedBy": createdBy,
      };
      print("📤 Sent from Flutter: ${jsonEncode(taskData)}");

      final res = await http.post(
        Uri.parse("$baseUrl/task/addTask"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(taskData),
      );
      print("📥 Response status: ${res.statusCode}");
      print("📥 Response body: ${res.body}");

      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // Update an existing task
  static Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required int projectId,
    required int subProjectId,
    required String title,
    required String taskDetails,
    required String mode,
    required String status,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await AuthApiService.getToken();
      if (token == null) {
        return {"success": false, "error": "Authentication required"};
      }
      final updateTaskData = {
        // "taskId": taskId,
        "ProjectID": projectId,
        "SubProjectID": subProjectId,
        "title": title,
        "taskDetails": taskDetails,
        "mode": mode,
        "status": status,
        "startDate": startDate,
        "endDate": endDate,
      };
      print("📤 Sent from Flutter: ${jsonEncode(updateTaskData)}");
      final url = Uri.parse("$baseUrl/task/updateTask/$taskId");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(updateTaskData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          "success": false,
          "error": "Failed to update task. Status code: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // Delete task
  static Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        return {"success": false, "error": "Authentication required"};
      }

      final res = await http.post(
        Uri.parse("$baseUrl/task/deleteTask/$taskId"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data;
      } else {
        return {"success": false, "error": data["error"] ?? "Failed to delete task"};
      }
    } catch (e) {
      print("❌ deleteTask error: $e");
      return {"success": false, "error": "Network error: ${e.toString()}"};
    }
  }

  // get task admin / employee
  static Future<List<dynamic>> fetchTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) return [];

      final res = await http.get(
        Uri.parse("$baseUrl/task/getTask"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("📥 Tasks API Response status: ${res.statusCode}");

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        final tasks = data["tasks"] ?? [];

        print("✅ Successfully loaded ${tasks.length} tasks");

        return tasks.map<Map<String, dynamic>>((task) {
          return {
            "id": task["id"]?.toString() ?? "",
            "project": task["project"]?.toString() ?? "Unknown Project",
            "subProject": task["subProject"]?.toString() ?? "Unknown Sub Project",
            "title": task["title"]?.toString() ?? "",
            "description": task["description"]?.toString() ?? "",
            "mode": task["mode"]?.toString() ?? "",
            "status": task["status"]?.toString() ?? "",
            "startTime": task["startTime"]?.toString() ?? "",
            "endTime": task["endTime"]?.toString() ?? "",
            "createdAt": task["createdAt"]?.toString() ?? "",
            "projectId": task["projectId"],
            "subProjectId": task["subProjectId"],
            "userId": task["userId"],
            "userName": task["userName"]?.toString() ?? "",
            "userEmail": task["userEmail"]?.toString() ?? "",
          };
        }).toList();
      } else {
        throw Exception(data["error"] ?? "Failed to fetch tasks");
      }
    } catch (e) {
      print("❌ Error fetching tasks: $e");
      return [];
    }
  }

  // Add project  (Only admin)
  static Future<Map<String, dynamic>> addProject(String projectName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.post(
      Uri.parse("$baseUrl/admin/addProject"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"projectName": projectName}),
    );
    return jsonDecode(res.body);
  }

  // Get all projects
  static Future<List<dynamic>> fetchProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/admin/listProject"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data["success"] == true) {
      // return data["projects"] ?? [];
      return List<Map<String, dynamic>>.from(data["projects"]);
    } else {
      throw Exception(data["error"] ?? "Failed to fetch projects");
    }
  }

  // Add sub project  (Only admin)
  static Future<Map<String, dynamic>> addSubProject({
    required int projectId,
    required String subProjectName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.post(
      Uri.parse("$baseUrl/admin/addSubProject"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"projectId": projectId, "subProjectName": subProjectName}),
    );
    return jsonDecode(res.body);
  }

  // Get all sub projects
  static Future<List<dynamic>> fetchSubProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final url = "$baseUrl/admin/listSubProject";
      // print("🌐 Calling SubProjects API: $url");
      // print("🔑 Token available: ${token != null && token.isNotEmpty}");

      final res = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      // print("📡 Response status: ${res.statusCode}");
      // print("📡 Response headers: ${res.headers}");
      // print("📡 Response body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          // print("✅ SubProjects fetched successfully: ${data["subProjects"]?.length ?? 0} items");
          return List<Map<String, dynamic>>.from(data["subProjects"] ?? []);
        } else {
          throw Exception(data["error"] ?? "API returned success: false");
        }
      } else {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      print("❌ fetchSubProjects error: $e");
      rethrow;
    }
  }

  // show employee task (Only admin)
  static Future<List<dynamic>> fetchTasksByEmployee(int empId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      // Uri.parse("$baseUrl/admin/emp_tasks/$empId"),
      Uri.parse("$baseUrl/admin/emp_tasks/$empId"),
      headers: {"Authorization": "Bearer ${token ?? ''}"},
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data["success"] == true) {
      return data["tasks"] ?? [];
    } else {
      throw Exception(data["error"] ?? "Failed to fetch tasks");
    }
  }

  // show all employee task (Only admin)
  static Future<List<dynamic>> fetchAllTasksByEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/admin/all_task_emp"),
      headers: {"Authorization": "Bearer ${token ?? ''}"},
    );
    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["success"] == true) {
      return data["tasks"] ?? [];
    } else {
      throw Exception(data["error"] ?? "Failed to fetch tasks");
    }
  }

  // show all admin tasks (Only Superadmin)
  static Future<List<dynamic>> fetchAllAdminTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/admin/all_task_admin"),
      headers: {"Authorization": "Bearer ${token ?? ''}"},
    );
    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["success"] == true) {
      return data["tasks"] ?? [];
    } else {
      throw Exception(data["error"] ?? "Failed to fetch admin tasks");
    }
  }
}
