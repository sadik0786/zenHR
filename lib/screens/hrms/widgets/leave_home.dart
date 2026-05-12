import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/utils/common_fn.dart';

class LeaveHome extends StatelessWidget {
  const LeaveHome({super.key});

  @override
  Widget build(BuildContext context) {
    final LeaveController controller = Get.find<LeaveController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Leave Requests", style: Theme.of(context).textTheme.titleLarge),
              Obx(
                () => Text(
                  "${controller.myLeavesRequest.length} Total",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.myLeavesRequest.isEmpty) {
                return const PageLoader();
              }

              if (controller.myLeavesRequest.isEmpty) {
                return Center(child: NoTasksWidget(message: "No Leave Requests"));
              }

              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: controller.myLeavesRequest.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final leave = controller.myLeavesRequest[index];
                  return _leaveHistoryCard(context, leave);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _leaveHistoryCard(BuildContext context, dynamic leave) {
    Color statusColor;
    final status = (leave["status"] ?? "PENDING").toString().toUpperCase();
    
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.greenAccent;
        break;
      case 'REJECTED':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.orangeAccent;
    }

    return Card(
      color: ThemeClass.darkCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave["leave_types"]?["leave_name"] ?? "Leave",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${CommonFn.formatDate(leave["from_date"])} to ${CommonFn.formatDate(leave["to_date"])}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem(context, "Duration", "${leave["total_days"]} Days"),
                _infoItem(context, "Session", leave["session_type"] ?? "Full Day"),
                _infoItem(context, "Applied on", CommonFn.formatDate(leave["applied_at"])),
              ],
            ),
            if (leave["reason"] != null && leave["reason"].toString().isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Reason", style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    leave["reason"],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (status == "REJECTED" && leave["reject_reason"] != null) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Reject Reason", style: Theme.of(context).textTheme.bodySmall),
                  Text(leave["reject_reason"], style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            if (leave["approver"]?["name"] != null) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status == "REJECTED" ? "Rejected by" : "Approved by",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    leave["approver"]["name"],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9.sp)),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
