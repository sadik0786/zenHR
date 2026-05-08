import 'package:get/get.dart';
import 'package:zen_hr/services/user_api_service.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class EmployeeController extends GetxController {
  RxBool loading = false.obs;
  RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    loading.value = true;

    final result = await UserApiService.getAllEmployees();
    employees.value = result;

    loading.value = false;
  }

  Future<void> deleteEmployee(int empId) async {
    final success = await UserApiService.deleteEmployee(empId);
    if (success) {
      employees.removeWhere((emp) => emp["ID"] == empId);
      CustomSnackBar.success("Employee deleted successfully");
    }
  }
}
