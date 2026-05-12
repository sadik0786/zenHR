import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class EmployeeController extends GetxController {
  final _supabase = Supabase.instance.client;
  UserController get _userController => Get.find<UserController>();

  RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      isLoading.value = true;
      final companyId = _userController.currentUser.value?.companyId;
      
      if (companyId == null) {
        // If it's a superAdmin, they might want to see ALL or select a company.
        // For now, let's fetch based on the logged-in user's company.
        return;
      }

      final List<dynamic> data = await _supabase
          .from('users')
          .select('*, role_master(role_name)')
          .eq('company_id', companyId)
          .order('name');

      employees.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      CustomSnackBar.error("Error fetching employees: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addEmployee(Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;
      final companyId = _userController.currentUser.value?.companyId;

      await _supabase.from('users').insert({
        'name': userData['name'],
        'email': userData['email'],
        'password': userData['password'], // Note: In production, use Supabase Auth
        'designation': userData['designation'],
        'department': userData['department'],
        'company_id': companyId,
        'role_id': userData['role_id'] ?? 5, // Default to 'employee'
      });

      CustomSnackBar.success("Employee added successfully!");
      fetchEmployees();
    } catch (e) {
      CustomSnackBar.error("Failed to add employee: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await _supabase.from('users').delete().eq('id', id);
      CustomSnackBar.success("Employee removed");
      fetchEmployees();
    } catch (e) {
      CustomSnackBar.error("Delete failed: $e");
    }
  }
}
