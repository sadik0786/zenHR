import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this
import 'package:zen_hr/controllers/user/employee_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class RegisterController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Use lazy getter to prevent "UserController not found" crash during field initialization
  UserController get _userController => Get.find<UserController>();

  final formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController employeeCode = TextEditingController();
  final TextEditingController email = TextEditingController();
  final password = TextEditingController();
  final mobile = TextEditingController();

  final loading = false.obs;
  final roleLoading = false.obs;
  final adminLoading = false.obs;

  final userName = ''.obs;
  final currentUserRole = ''.obs;

  RxList<Map<String, dynamic>> admins = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> roles = <Map<String, dynamic>>[].obs;
  
  final selectedAdminId = Rxn<dynamic>();
  final selectedRoleId = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      userName.value = _userController.currentUser.value?.name ?? "Admin";
      currentUserRole.value = _userController.currentUser.value?.role?.toLowerCase() ?? '';
      await loadRoles();
    } catch (e) {
      print("Init data error: $e");
    }
  }

  Future<void> loadRoles() async {
    try {
      roleLoading.value = true;
      final List<dynamic> data = await _supabase.from('role_master').select().eq('is_active', true);

      List<Map<String, dynamic>> filteredRoles = data.cast<Map<String, dynamic>>().toList();

      // Prevent non-owners from creating Owners, CEOs, or superAdmins
      if (!AppConstants.isSuperUser(currentUserRole.value)) {
        filteredRoles.removeWhere((r) {
          final role = r['role_name'].toString().toLowerCase();
          return role == 'owner' || role == 'ceo' || role == 'superadmin';
        });
      }

      roles.assignAll(filteredRoles);
    } catch (e) {
      print("Error loading roles: $e");
    } finally {
      roleLoading.value = false;
    }
  }

  Future<void> loadAssignableUsers(String selectedRoleName) async {
    try {
      adminLoading.value = true;
      final companyId = _userController.currentUser.value?.companyId;
      if (companyId == null) return;

      final List<dynamic> data = await _supabase
          .from('users')
          .select('id, name')
          .eq('company_id', companyId);
      
      admins.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error loading users: $e");
    } finally {
      adminLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedRoleId.value == null) {
      CustomSnackBar.error("Please select a role");
      return;
    }

    try {
      loading.value = true;
      final companyId = _userController.currentUser.value?.companyId;

      // 1. Create Auth User
      print("Step 1: Creating Auth user via Admin API...");
      final adminClient = SupabaseClient(
        dotenv.get('SUPABASE_URL'),
        dotenv.get('SUPABASE_SERVICE_ROLE_KEY'),
      );

      final adminRes = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email.text.trim(),
          password: password.text.trim(),
          emailConfirm: true,
        ),
      );

      if (adminRes.user == null) throw "Auth user creation failed (Admin API)";
      final String authId = adminRes.user!.id;
      print("✅ Step 1 Success: Auth ID $authId");

      // 2. Insert Profile
      print("Step 2: Inserting Profile for Company ID $companyId...");
      try {
        await adminClient.from('users').insert({
          'id': authId, 
          'name': name.text.trim(),
          'employee_code': employeeCode.text.trim(),
          'email': email.text.trim(),
          'phone': mobile.text.trim(),
          'company_id': companyId,
          'role_id': selectedRoleId.value,
          'password': password.text.trim(),
          'is_active': true,
        });
        print("✅ Step 2 Success: Profile Created");
      } catch (insertErr) {
        print("❌ Step 2 FAILED: $insertErr");
        throw "Profile creation failed: $insertErr";
      }

      // 3. UI Feedback
      print("Step 3: Navigating and clearing...");
      
      _clearFields();
      await Future.delayed(const Duration(milliseconds: 200));
      CustomSnackBar.success("Employee onboarded successfully!");

      if (Get.context != null) {
        Navigator.pop(Get.context!);
      } else {
        Get.back();
      }

      if (Get.isRegistered<EmployeeController>()) {
        Get.find<EmployeeController>().fetchEmployees();
      }
    } catch (e) {
      print("❌ FULL REGISTRATION ERROR: $e");
      CustomSnackBar.error(e.toString());
    } finally {
      loading.value = false;
    }
  }

  void _clearFields() {
    name.clear();
    employeeCode.clear();
    email.clear();
    password.clear();
    mobile.clear();
    selectedRoleId.value = null;
    selectedAdminId.value = null;
  }
  @override
  void onClose() {
    name.dispose();
    email.dispose();
    password.dispose();
    mobile.dispose();
    super.onClose();
  }
}
