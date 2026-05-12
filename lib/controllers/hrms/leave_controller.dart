import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class LeaveController extends GetxController {
  final _supabase = Supabase.instance.client;
  final _userController = Get.find<UserController>();

  // --- Leave Type Management (New Features) ---
  // --- Leave Type Management (New Features) ---
  final addLeaveTypeFormKey = GlobalKey<FormState>();
  final leaveNameController = TextEditingController();
  final leaveDaysController = TextEditingController();
  final financialYearController = TextEditingController(text: "2025-2026");
  final Rxn<int> editingId = Rxn<int>();

  // --- Apply Leave Logic (Recovered Old Code) ---
  final applyLeaveFormKey = GlobalKey<FormState>();
  final reasonController = TextEditingController();
  final Rxn<int> selectedLeaveTypeId = Rxn<int>();
  final Rx<DateTime> fromDate = DateTime.now().obs;
  final Rx<DateTime> toDate = DateTime.now().obs;
  final Rxn<String> selectedSessionId = Rxn<String>();
  
  final List<Map<String, String>> leaveSessions = [
    {"id": "FULL_DAY", "name": "Full Day"},
    {"id": "FIRST_HALF", "name": "First Half"},
    {"id": "SECOND_HALF", "name": "Second Half"},
  ];

  final RxList<Map<String, dynamic>> leaveTypes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> myLeavesRequest = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> otherLeavesRequest = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentDashboardIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaveTypes();
    fetchLeaveRequests();
  }

  void clearApplyForm() {
    selectedLeaveTypeId.value = null;
    fromDate.value = DateTime.now();
    toDate.value = DateTime.now();
    selectedSessionId.value = null;
    reasonController.clear();
  }

  // --- Computed Properties ---
  Map<String, dynamic>? get selectedLeaveType {
    if (selectedLeaveTypeId.value == null) return null;
    return leaveTypes.firstWhereOrNull((e) => e['id'] == selectedLeaveTypeId.value);
  }

  // --- Logic Methods ---

  Future<void> fetchLeaveTypes() async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) return;

      final data = await _supabase
          .from('leave_types')
          .select()
          .eq('company_id', user.companyId!)
          .eq('financial_year', financialYearController.text.trim())
          .order('created_at', ascending: false);

      leaveTypes.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching leave types: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLeaveRequests() async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      if (user == null) return;

      // 1. My Requests
      final myData = await _supabase
          .from('leave_requests')
          .select('*, leave_types(leave_name, financial_year)')
          .eq('employee_id', user.id)
          .eq('financial_year', financialYearController.text.trim())
          .order('applied_at', ascending: false);
      myLeavesRequest.assignAll(myData.cast<Map<String, dynamic>>());

      // 2. Approval Requests (Role-based Hierarchy)
      final currentUserRole = user.role?.toLowerCase() ?? "";
      
      var query = _supabase
          .from('leave_requests')
          .select('*, applicant:users!employee_id(name, role_master(role_name), reporting_to), leave_types(leave_name, financial_year)')
          .eq('company_id', user.companyId!)
          .eq('status', 'PENDING')
          .neq('employee_id', user.id);

      final otherData = await query.order('applied_at', ascending: false);
      print("🔍 DB Records Found: ${otherData.length}");

      final filteredData = otherData.where((req) {
        final applicant = req['applicant'];
        if (applicant == null) return false;

        // Extract applicant role
        String applicantRole = "";
        final roleData = applicant['role_master'];
        if (roleData is List && roleData.isNotEmpty) {
          applicantRole = (roleData[0]['role_name'] ?? "").toString().trim().toLowerCase();
        } else if (roleData is Map) {
          applicantRole = (roleData['role_name'] ?? "").toString().trim().toLowerCase();
        }

        final reportingTo = applicant['reporting_to'];
        print("👤 Checking: Applicant(${applicant['name']}) Role($applicantRole) reportingTo($reportingTo) vs Me(${user.id})");

        if (currentUserRole == 'ceo') {
          // CEO sees HR, Manager, Admin
          return ['hr', 'manager', 'admin'].contains(applicantRole);
        } else if (currentUserRole == 'hr') {
          // HR sees Employees
          return applicantRole == 'employee';
        } else if (currentUserRole == 'manager') {
          // Manager sees only their direct reports
          return reportingTo == user.id;
        }
        return false;
      }).toList();

      otherLeavesRequest.assignAll(filteredData.cast<Map<String, dynamic>>());
      print("🚀 Total Visible for $currentUserRole: ${otherLeavesRequest.length}");
    } catch (e) {
      print("Error fetching leave requests: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitLeaveRequest() async {
    if (!applyLeaveFormKey.currentState!.validate()) return;
    if (selectedLeaveTypeId.value == null) {
      CustomSnackBar.error("Please select leave category");
      return;
    }

    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      
      await _supabase.from('leave_requests').insert({
        'company_id': user!.companyId,
        'employee_id': user.id,
        'leave_type_id': selectedLeaveTypeId.value,
        'from_date': fromDate.value.toIso8601String(),
        'to_date': toDate.value.toIso8601String(),
        'total_days': calculateLeaveDays(),
        'session_type': selectedSessionId.value ?? 'FULL_DAY',
        'reason': reasonController.text.trim(),
        'financial_year': financialYearController.text.trim(), // Added FY
        'status': 'PENDING',
      });

      CustomSnackBar.success("Leave request submitted!");
      clearApplyForm();
      fetchLeaveRequests();
      currentDashboardIndex.value = 0; // Redirect to index 0
    } catch (e) {
      CustomSnackBar.error("Error submitting leave: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLeaveStatus(dynamic id, String status, {String? rejectReason, String? approvalRemarks}) async {
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;

      await _supabase
          .from('leave_requests')
          .update({
            'status': status,
            'reject_reason': rejectReason,
            'approval_remarks': approvalRemarks,
            'approver_id': user!.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      CustomSnackBar.success("Request $status successfully!");
      fetchLeaveRequests();
    } catch (e) {
      CustomSnackBar.error("Error updating status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- Calculations ---

  double calculateLeaveDays() {
    final days = toDate.value.difference(fromDate.value).inDays + 1;
    if (selectedSessionId.value == 'FIRST_HALF' || selectedSessionId.value == 'SECOND_HALF') {
      return 0.5;
    }
    return days.toDouble();
  }

  double calculateUsedLeaves(String leaveName) {
    return myLeavesRequest
        .where((l) => l['leave_types']?['leave_name'] == leaveName && l['status'] == 'APPROVED')
        .fold(0.0, (sum, l) => sum + (l['total_days'] ?? 0).toDouble());
  }

  double calculatePendingLeaves(String leaveName) {
    return myLeavesRequest
        .where((l) => l['leave_types']?['leave_name'] == leaveName && l['status'] == 'PENDING')
        .fold(0.0, (sum, l) => sum + (l['total_days'] ?? 0).toDouble());
  }

  // --- Helpers ---

  Future<void> pickDate(BuildContext context, bool isFrom) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate.value : toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      if (isFrom) {
        fromDate.value = date;
        if (toDate.value.isBefore(date)) toDate.value = date;
      } else {
        toDate.value = date;
      }
    }
  }

  // --- Admin Leave Type Methods ---

  Future<void> saveLeaveType() async {
    if (!addLeaveTypeFormKey.currentState!.validate()) return;
    try {
      isLoading.value = true;
      final user = _userController.currentUser.value;
      final payload = {
        'company_id': user!.companyId,
        'leave_name': leaveNameController.text.trim(),
        'leave_count': double.parse(leaveDaysController.text.trim()),
        'financial_year': financialYearController.text.trim(),
      };

      if (editingId.value != null) {
        await _supabase.from('leave_types').update(payload).eq('id', editingId.value!);
        CustomSnackBar.success("Updated!");
      } else {
        await _supabase.from('leave_types').insert(payload);
        CustomSnackBar.success("Added!");
      }
      resetForm();
      fetchLeaveTypes();
    } catch (e) {
      CustomSnackBar.error("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void startEditing(Map<String, dynamic> type) {
    editingId.value = type['id'];
    leaveNameController.text = type['leave_name'];
    leaveDaysController.text = type['leave_count'].toString();
  }

  void resetForm() {
    editingId.value = null;
    leaveNameController.clear();
    leaveDaysController.clear();
  }
}
