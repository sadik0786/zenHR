import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/attendance_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/theme.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  // Use putIfAbsent to ensure controller exists even if navigating directly
  late AttendanceController controller;
  late UserController userController;

  DateTime selectedDate = DateTime.now();
  String? filterUserId;
  String? filterUserName;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AttendanceController());
    userController = Get.find<UserController>();
    
    // Check if filtering for a specific user (passed from Admin view)
    if (Get.arguments != null) {
      filterUserId = Get.arguments['userId'];
      filterUserName = Get.arguments['name'];
    }

    // Fetch data after the first frame to prevent UI lag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    controller.fetchMonthlyAttendance(
      selectedDate.month, 
      selectedDate.year, 
      userId: filterUserId
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHR =
        userController.currentUser.value?.role?.toLowerCase() == 'ceo' ||
        userController.currentUser.value?.role?.toLowerCase() == 'hr';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          filterUserName != null ? "$filterUserName's Logs" : "Attendance Reports", 
          style: Theme.of(context).textTheme.titleLarge
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => selectedDate = date);
                _refresh();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(isHR),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: PageLoader());
              }
              if (controller.attendanceLogs.isEmpty) {
                return const Center(child: Text("No records found for this period"));
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: controller.attendanceLogs.length,
                itemBuilder: (context, index) => _buildReportItem(controller.attendanceLogs[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(bool isHR) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                isHR ? "Company Wide Records" : "My Personal Records",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
          Icon(Icons.filter_list_rounded, color: ThemeClass.primaryGreen),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> log) {
    final clockIn = DateTime.parse(log['clock_in']);
    final clockOut = log['clock_out'] != null ? DateTime.parse(log['clock_out']) : null;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  DateFormat('dd').format(clockIn),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: ThemeClass.primaryGreen,
                  ),
                ),
                Text(
                  DateFormat('EEE').format(clockIn).toUpperCase(),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log['users']?['name'] ?? "Unknown",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.login_rounded, size: 14.sp, color: Colors.green),
                      SizedBox(width: 4.w),
                      Text(
                        DateFormat('hh:mm a').format(clockIn),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.logout_rounded, size: 14.sp, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        clockOut != null ? DateFormat('hh:mm a').format(clockOut) : "Working",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (log['total_hours'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ThemeClass.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "${log['total_hours']}h",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: ThemeClass.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
