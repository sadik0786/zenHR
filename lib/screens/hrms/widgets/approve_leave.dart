import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/utils/common_fn.dart';

class ApproveLeave extends StatelessWidget {
  const ApproveLeave({super.key});

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
              Text("Approval Requests", style: Theme.of(context).textTheme.titleLarge),
              Obx(() => Text("${controller.otherLeavesRequest.length} Pending")),
            ],
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.otherLeavesRequest.isEmpty) {
                return const PageLoader();
              }

              if (controller.otherLeavesRequest.isEmpty) {
                return Center(child: NoTasksWidget(message: "No pending requests"));
              }

              return ListView.separated(
                itemCount: controller.otherLeavesRequest.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final leave = controller.otherLeavesRequest[index];
                  return _approvalCard(context, controller, leave);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _approvalCard(BuildContext context, LeaveController controller, dynamic leave) {
    return Card(
      color: ThemeClass.darkCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: ThemeClass.primaryGreen,
                child: Text((leave["applicant"]?["name"] ?? "U")[0].toUpperCase()),
              ),
              title: Text(
                leave["applicant"]?["name"] ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${leave["leave_types"]?["leave_name"]} | ${leave["total_days"]} Days",
              ),
              trailing: Text(
                CommonFn.formatDate(leave["from_date"]),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const Divider(color: Colors.white10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApproval(context, controller, leave),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Approve"),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDecisionDialog(context, controller, leave["id"], false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Reject"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleApproval(BuildContext context, LeaveController controller, dynamic leave) {
    // Check if current user is HR and applicant has a reporting manager
    final currentUserRole = Get.find<UserController>().currentUser.value?.role?.toLowerCase() ?? "";
    final hasManager = leave["applicant"]?["reporting_to"] != null;

    if (currentUserRole == 'hr' && hasManager) {
      // HR needs to provide reason for overriding manager's approval
      _showDecisionDialog(context, controller, leave["id"], true);
    } else {
      // Direct approval for Managers/CEO or HR approving direct employees
      controller.updateLeaveStatus(leave["id"], "APPROVED");
    }
  }

  void _showDecisionDialog(
    BuildContext context,
    LeaveController controller,
    dynamic id,
    bool isApprove,
  ) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(isApprove ? "Approval Remarks (HR Override)" : "Reject Reason"),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: isApprove ? "Why are you approving this?" : "Enter rejection reason",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (isApprove) {
                controller.updateLeaveStatus(
                  id,
                  "APPROVED",
                  approvalRemarks: reasonController.text,
                );
              } else {
                controller.updateLeaveStatus(id, "REJECTED", rejectReason: reasonController.text);
              }
              Get.back();
            },
            child: Text(
              isApprove ? "Approve" : "Reject",
              style: TextStyle(color: isApprove ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
