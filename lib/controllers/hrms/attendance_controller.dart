import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class AttendanceController extends GetxController {
  final _supabase = Supabase.instance.client;
  final _userController = Get.find<UserController>();

  final RxList<Map<String, dynamic>> attendanceLogs = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCheckedIn = false.obs;
  final Rxn<Map<String, dynamic>> currentAttendance = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchAttendance();
    checkTodayStatus();
  }

  Future<void> fetchAttendance() async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) return;

      var query = _supabase.from('attendance').select('*, users:user_id(name)');

      // Default to showing only current user's logs
      query = query.eq('user_id', user.id);

      final data = await query
          .order('clock_in', ascending: false)
          .limit(10); // Show last 10 on home
      attendanceLogs.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching attendance: $e");
    } finally {
      isLoading.value = false;
    }
  }

  final RxList<Map<String, dynamic>> allEmployeesStatus = <Map<String, dynamic>>[].obs;

  Future<void> fetchAllEmployeesTodayStatus() async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Fetch all users in the company with their roles
      final employees = await _supabase
          .from('users')
          .select(
            'id, name, employee_code, role_master(role_name), attendance(clock_in, clock_out)',
          )
          .eq('company_id', user.companyId!)
          .filter('attendance.log_date', 'eq', today);

      allEmployeesStatus.assignAll(employees.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching all employees status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMonthlyAttendance(int month, int year, {String? userId}) async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) return;

      var query = _supabase.from('attendance').select('*, users:user_id(name)');

      // If userId is provided (e.g. HR viewing an employee), use it.
      // Otherwise, always show the current user's own logs.
      if (userId != null) {
        query = query.eq('user_id', userId);
      } else {
        query = query.eq('user_id', user.id);
      }

      final data = await query
          .gte('log_date', '$year-${month.toString().padLeft(2, '0')}-01')
          .lte('log_date', '$year-${month.toString().padLeft(2, '0')}-31')
          .order('log_date', ascending: false);

      attendanceLogs.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching monthly attendance: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkTodayStatus() async {
    try {
      final user = _userController.currentUser.value;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Find the LATEST entry for today where clock_out IS NULL
      final data = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', today)
          .filter('clock_out', 'is', null) // Stable null check
          .order('clock_in', ascending: false)
          .maybeSingle();

      if (data != null) {
        currentAttendance.value = data;
        isCheckedIn.value = true;
      } else {
        isCheckedIn.value = false;
        currentAttendance.value = null;
      }
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  Future<void> punchIn() async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) throw "User not found";

      print("🚀 Multiple Punch: Punching In for User: ${user.id}");

      await _supabase.from('attendance').insert({
        'user_id': user.id,
        'company_id': user.companyId,
        'log_date': DateTime.now().toIso8601String().split('T')[0],
        'clock_in': DateTime.now().toIso8601String(),
        'status': 'Present',
      });

      await checkTodayStatus();
      await fetchAttendance();
      CustomSnackBar.success("Punched In successfully!");
    } catch (e) {
      print("❌ Punch In Error: $e");
      CustomSnackBar.error("Failed to check in: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> punchOut() async {
    try {
      isLoading.value = true;
      if (currentAttendance.value == null) throw "No active check-in found";

      final recordId = currentAttendance.value!['id'];
      final clockInTime = DateTime.parse(currentAttendance.value!['clock_in']);
      final clockOutTime = DateTime.now();

      final difference = clockOutTime.difference(clockInTime).inMinutes / 60.0;

      print("🚀 Punching Out for Record ID: $recordId");

      await _supabase
          .from('attendance')
          .update({
            'clock_out': clockOutTime.toIso8601String(),
            'total_hours': double.parse(difference.toStringAsFixed(2)),
          })
          .eq('id', recordId);

      await checkTodayStatus();
      await fetchAttendance();
      CustomSnackBar.success("Punched Out successfully!");
    } catch (e) {
      print("❌ Punch Out Error: $e");
      CustomSnackBar.error("Failed to check out: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
