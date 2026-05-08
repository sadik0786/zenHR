import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/controllers/user/employee_controller.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/model/auth/register_request_model.dart';
import 'package:zen_hr/services/auth_api_service.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/core/app_constants.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final mobile = TextEditingController();

  // Reactive states
  final loading = false.obs;
  final roleLoading = false.obs;

  final userName = ''.obs;
  final currentUserRole = ''.obs;

  RxList<Map<String, dynamic>> admins = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> roles = <Map<String, dynamic>>[].obs;
  RxBool adminLoading = false.obs;
  RxnInt selectedAdminId = RxnInt();

  final selectedRoleId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    name.dispose();
    email.dispose();
    password.dispose();
    mobile.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    await loadUserRole();
    await loadRoles();
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString(AppConstants.nameKey) ?? "Employee";
    currentUserRole.value = prefs.getString(AppConstants.roleKey)?.trim().toLowerCase() ?? '';
  }

  Future<void> loadRoles() async {
    roleLoading.value = true;
    try {
      final fetchedRoles = await AuthApiService.getRoles();
      roles.value = fetchedRoles.map((role) {
        return {...role, "RoleName": (role["RoleName"] ?? "").toString().trim().toUpperCase()};
      }).toList();
    } catch (e) {
      print("Error loading roles: $e");
    } finally {
      roleLoading.value = false;
    }
  }

  Future<void> loadAssignableUsers(String selectedRoleName) async {
    adminLoading.value = true;

    try {
      final myRole = currentUserRole.value.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final selRoleClean = selectedRoleName.trim().toLowerCase();

      print("--- RegisterController Trace ---");
      print("My Role: '$myRole'");
      print("Selected Role: '$selRoleClean'");

      // Clear previous selection
      selectedAdminId.value = null;
      admins.clear();

      if (myRole == AppConstants.roleCeo) {
        // CEO case: Auto-select self
        selectedAdminId.value = prefs.getInt(AppConstants.userIdKey);
        admins.assignAll([
          {"ID": selectedAdminId.value, "Name": "Self (${userName.value})"},
        ]);
        print("CEO Case: Auto-selected self (ID: ${selectedAdminId.value})");
      } else if (myRole == AppConstants.roleHr) {
        if (selRoleClean == AppConstants.roleAdmin) {
          // Admin assigned to Manager
          final users = await AuthApiService.getUsersByRoles(AppConstants.roleManager);
          admins.assignAll(users);
          print("HR Case (Admin): Found ${users.length} Managers");
          print("Managers List: $users");
        } else if (selRoleClean == AppConstants.roleEmployee) {
          // Employee assigned to Admin or Manager
          final users = await AuthApiService.getUsersByRoles(
            "${AppConstants.roleAdmin},${AppConstants.roleManager}",
          );
          admins.assignAll(users);
          print("HR Case (Employee): Found ${users.length} Admins/Managers");
          print("Admins/Managers List: $users");
        }

        // Auto-select the first person if available for HR
        if (admins.isNotEmpty) {
          selectedAdminId.value = admins[0]["ID"];
        } else {
          print("HR Case: No assignable users found for $selRoleClean");
        }
      }
    } catch (e) {
      print("Error loading assignable users: $e");
    } finally {
      adminLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    final roleId = selectedRoleId.value;
    if (roleId == null) {
      CustomSnackBar.error("Please select a role");
      return;
    }

    loading.value = true;

    try {
      print("--- Registration Data Trace ---");
      print("Role ID: $roleId");
      print("Reporting ID (Assign To): ${selectedAdminId.value}");

      final reportingId = selectedAdminId.value;
      print("Final selectedAdminId before sending: $reportingId");

      final request = RegisterRequestModel(
        name: name.text.trim(),
        email: email.text.trim(),
        mobile: mobile.text.trim(),
        password: password.text.trim(),
        roleId: roleId,
        reportingId: reportingId,
      );

      print("Request JSON: ${jsonEncode(request.toJson())}");

      final response = await AuthApiService.registerEmployee(request);

      if (response.success == true) {
        CustomSnackBar.success("Added successfully!");

        // Refresh employee list if it exists
        if (Get.isRegistered<EmployeeController>()) {
          Get.find<EmployeeController>().fetchEmployees();
        }

        // ✅ CLEAR FIELDS
        name.clear();
        email.clear();
        password.clear();
        mobile.clear();
        selectedRoleId.value = null;
        selectedAdminId.value = null;

        // ✅ Go Back
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed(Routes.dashboard);
        });
      } else {
        CustomSnackBar.error(response.message ?? "Failed to add employee");
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      CustomSnackBar.error("Something went wrong: $e");
    } finally {
      loading.value = false;
    }
  }
}
