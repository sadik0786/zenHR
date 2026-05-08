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
                  "${controller.appliedLeaves.length} Total",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.appliedLeaves.isEmpty) {
                return PageLoader();
              }

              if (controller.appliedLeaves.isEmpty) {
                return Center(child: NoTasksWidget(message: "No Leave Requests"));
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 0.w),
                itemCount: controller.appliedLeaves.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final leave = controller.appliedLeaves[index];
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
    switch (leave.status.toString().toUpperCase()) {
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
                      leave.leaveTypeName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${CommonFn.formatDate(leave.fromDate)} to ${CommonFn.formatDate(leave.toDate)}",
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
                    leave.status,
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
                _infoItem(context, "Duration", "${leave.totalDays} Days"),
                _infoItem(context, "Session", leave.sessionDay == 1 ? "Full Day" : "Half Day"),
                _infoItem(context, "Applied on", CommonFn.formatDate(leave.fromDate)),
              ],
            ),
            if (leave.reason != null && leave.reason!.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Reason", style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    leave.reason!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (leave.status.toString().toUpperCase() == "REJECTED" &&
                leave.rejectReason != null &&
                leave.rejectReason!.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Reject Reason", style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    leave.rejectReason!,
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            if (leave.approverName != null && leave.approverName!.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leave.status.toString().toUpperCase() == "REJECTED"
                        ? "Rejected by"
                        : "Approved by",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    leave.approverName!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
