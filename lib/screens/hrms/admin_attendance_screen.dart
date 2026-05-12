import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/attendance_controller.dart';
import 'package:zen_hr/core/routes.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final AttendanceController controller = Get.put(AttendanceController());
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllEmployeesTodayStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text("Employee Attendance", style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchAllEmployeesTodayStatus(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const PageLoader();

              var filteredList = controller.allEmployeesStatus.where((emp) {
                return emp['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                    emp['employee_code'].toString().toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
              }).toList();

              if (filteredList.isEmpty) {
                return const Center(child: Text("No employees found"));
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemCount: filteredList.length,
                itemBuilder: (context, index) => _buildEmployeeTile(filteredList[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      int total = controller.allEmployeesStatus.length;
      int present = controller.allEmployeesStatus
          .where((e) => (e['attendance'] as List).isNotEmpty)
          .length;

      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            _card("Total", total.toString(), Colors.blue),
            SizedBox(width: 12.w),
            _card("Present", present.toString(), Colors.green),
            SizedBox(width: 12.w),
            _card("Absent", (total - present).toString(), Colors.red),
          ],
        ),
      );
    });
  }

  Widget _card(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextField(
        controller: searchController,
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: "Search Employee...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> emp) {
    final attendance = emp['attendance'] as List;
    final bool isPresent = attendance.isNotEmpty;
    final lastLog = isPresent ? attendance.last : null;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: ListTile(
        onTap: () {
          // Navigate to individual report
          Get.toNamed(
            Routes.attendanceReport,
            arguments: {'userId': emp['id'], 'name': emp['name']},
          );
        },
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Text(
            emp['name'][0],
            style: TextStyle(color: isPresent ? Colors.green : Colors.red),
          ),
        ),
        title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${emp['employee_code'] ?? 'N/A'} | ${emp['role_master']?['role_name'] ?? 'No Role'}",
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isPresent ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text(
                isPresent ? "PRESENT" : "ABSENT",
                style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ),
            if (isPresent && lastLog['clock_in'] != null)
              Text(
                "In: ${DateFormat('hh:mm a').format(DateTime.parse(lastLog['clock_in']))}",
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
