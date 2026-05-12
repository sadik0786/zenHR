import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/attendance_controller.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/core/theme.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text("Attendance", style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.fetchAttendance(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.attendanceLogs.isEmpty) {
          return const Center(child: PageLoader());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPunchCard(context, controller),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Activity",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.attendanceReport),
                    child: const Text(
                      "View All",
                      style: TextStyle(color: ThemeClass.secondaryLightBlue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              _buildAttendanceList(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPunchCard(BuildContext context, AttendanceController controller) {
    Theme.of(context);
    final bool checkedIn = controller.isCheckedIn.value;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: checkedIn
              ? [Colors.orange.shade400, Colors.orange.shade700]
              : [ThemeClass.primaryGreen, ThemeClass.tealGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: (checkedIn ? Colors.orange : Colors.green).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.sp),
          ),
          SizedBox(height: 5.h),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              return Text(
                DateFormat('hh:mm:ss a').format(DateTime.now()),
                style: TextStyle(color: Colors.white, fontSize: 25.sp, fontWeight: FontWeight.bold),
              );
            },
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(
              checkedIn ? Icons.logout_rounded : Icons.login_rounded,
              size: 40.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: 150.w,
            child: ElevatedButton(
              onPressed: () => checkedIn ? controller.punchOut() : controller.punchIn(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: checkedIn ? Colors.orange : Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                checkedIn ? "PUNCH OUT" : "PUNCH IN",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceController controller) {
    if (controller.attendanceLogs.isEmpty) {
      return const Center(child: Text("No attendance records found"));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.attendanceLogs.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final log = controller.attendanceLogs[index];
        final clockIn = DateTime.parse(log['clock_in']);
        final clockOut = log['clock_out'] != null ? DateTime.parse(log['clock_out']) : null;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (log['status'] == 'Present' ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: log['status'] == 'Present' ? Colors.green : Colors.red,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM, yyyy').format(clockIn),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                    ),
                    Text(
                      log['users']?['name'] ?? "Unknown",
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "In: ${DateFormat('hh:mm a').format(clockIn)}",
                    style: TextStyle(fontSize: 12.sp, color: Colors.green),
                  ),
                  Text(
                    clockOut != null
                        ? "Out: ${DateFormat('hh:mm a').format(clockOut)}"
                        : "Working...",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: clockOut != null ? Colors.orange : Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
