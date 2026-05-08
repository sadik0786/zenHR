import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/model/hrms/leave_request_model.dart';
import 'package:zen_hr/utils/common_fn.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class ApproveLeave extends StatefulWidget {
  const ApproveLeave({super.key});

  @override
  State<ApproveLeave> createState() => _ApproveLeaveState();
}

class _ApproveLeaveState extends State<ApproveLeave> {
  final LeaveController leaveController = Get.find<LeaveController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: isDark ? ThemeClass.zenAccent : ThemeClass.zenPrimary,
            labelColor: isDark ? ThemeClass.zenAccent : ThemeClass.zenPrimary,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.grey[400],
            indicatorWeight: 3.r,
            labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 15.h),
          child: Obx(() {
            if (leaveController.isLoading.value && leaveController.otherLeavesRequest.isEmpty) {
              return const PageLoader();
            }

            final pendingLeaves = leaveController.otherLeavesRequest
                .where((e) => e.status.toString().toUpperCase() == "PENDING")
                .toList();

            final completedLeaves = leaveController.otherLeavesRequest
                .where(
                  (e) =>
                      e.status.toString().toUpperCase() == "APPROVED" ||
                      e.status.toString().toUpperCase() == "REJECTED",
                )
                .toList()
                .reversed
                .toList(); 

            return TabBarView(
              children: [
                // PENDING TAB
                RefreshIndicator(
                  onRefresh: () => leaveController.fetchOtherLeaves(),
                  child: pendingLeaves.isEmpty
                      ? Center(child: NoTasksWidget(message: "No pending leave requests"))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: pendingLeaves.length,
                          itemBuilder: (context, index) {
                            return _approvalCard(context, pendingLeaves[index]);
                          },
                        ),
                ),

                // COMPLETED TAB
                RefreshIndicator(
                  onRefresh: () => leaveController.fetchOtherLeaves(),
                  child: completedLeaves.isEmpty
                      ? Center(child: NoTasksWidget(message: "No completed leave records"))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: completedLeaves.length,
                          itemBuilder: (context, index) {
                            return _completedCard(context, completedLeaves[index]);
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// ---------------- COMPLETED CARD ----------------
  Widget _completedCard(BuildContext context, LeaveRequestModel leave) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isApproved = leave.status.toString().toUpperCase() == "APPROVED";

    return GestureDetector(
      onTap: () => _showLeaveDetailBottomSheet(context, leave),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
              child: Icon(
                isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isApproved ? Colors.green : Colors.red,
                size: 26.sp,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave.employeeName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "${CommonFn.formatDate(leave.fromDate)} - ${CommonFn.formatDate(leave.toDate)}",
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusIndicatorChip(leave.status.toString().toUpperCase()),
                SizedBox(height: 4.h),
                Text(
                  "${leave.totalDays}d",
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicatorChip(String status) {
    final bool isApproved = status == "APPROVED";
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.red,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showLeaveDetailBottomSheet(BuildContext context, LeaveRequestModel leave) {
    final theme = Theme.of(context);
    final bool isApproved = leave.status.toString().toUpperCase() == "APPROVED";

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Leave Details",
                    style: theme.textTheme.titleLarge,
                  ),
                  _statusIndicatorChip(leave.status.toString().toUpperCase()),
                ],
              ),
              SizedBox(height: 25.h),
              _detailRow(context, Icons.person_outline_rounded, "Employee", leave.employeeName),
              _detailRow(context, Icons.category_outlined, "Leave Type", leave.leaveTypeName),
              _detailRow(
                context,
                Icons.calendar_today_rounded,
                "Duration",
                "${CommonFn.formatDate(leave.fromDate)} to ${CommonFn.formatDate(leave.toDate)} (${leave.totalDays} Days)",
              ),
              _detailRow(context, Icons.text_fields_rounded, "Employee Reason", leave.reason ?? "N/A"),
              Divider(height: 30.h, color: theme.dividerColor),
              _detailRow(
                context,
                isApproved ? Icons.verified_user_outlined : Icons.report_gmailerrorred_rounded,
                isApproved ? "Approved By" : "Rejected By",
                leave.approverName ?? "System",
                valueColor: isApproved ? Colors.green : Colors.red,
              ),
              _detailRow(
                context,
                Icons.comment_bank_outlined,
                "Admin Remarks",
                leave.rejectReason ?? "No remarks provided",
                isLast: true,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: CustomButton(text: "Close", onPressed: () => Get.back()),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: theme.colorScheme.primary),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- APPROVAL CARD ----------------
  Widget _approvalCard(BuildContext context, LeaveRequestModel leave) {
    final theme = Theme.of(context);
    final isHr = leaveController.userRole.value.toLowerCase() == "hr";

    leaveController.hrApprovalMap.putIfAbsent(leave.id, () => false);

    return Card(
      margin: EdgeInsets.only(bottom: 14.h),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.2),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.employeeName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                _statusChip(context, "${leave.totalDays} days"),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.leaveTypeName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  "${CommonFn.formatDate(leave.fromDate)} to ${CommonFn.formatDate(leave.toDate)}",
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            if (leave.reason != null && leave.reason!.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                "Reason: ${leave.reason}",
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: isHr ? 5.h : 15.h),

            if (isHr)
              Obx(
                () => GestureDetector(
                  onTap: () {
                    final currentVal = leaveController.hrApprovalMap[leave.id] ?? false;
                    leaveController.hrApprovalMap[leave.id] = !currentVal;
                    if (leaveController.hrApprovalMap[leave.id] == true) {
                      _showHrReasonBottomSheet(context, leave.id, isReject: false);
                    }
                  },
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: leaveController.hrApprovalMap[leave.id] ?? false,
                          activeColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.dividerColor),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            leaveController.hrApprovalMap[leave.id] = val!;
                            if (val) {
                              _showHrReasonBottomSheet(context, leave.id, isReject: false);
                            }
                          },
                        ),
                      ),
                      Text(
                        "Approve as HR with reason",
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),

            // ACTION BUTTONS
            SwipeApproveReject(leave: leave),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
      ),
    );
  }

  void _showHrReasonBottomSheet(BuildContext context, int leaveId, {bool isReject = false}) {
    final theme = Theme.of(context);
    final TextEditingController reasonCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isReject ? "Reject Reason" : "HR Approval Reason",
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              hintText: "Enter reason here...",
              keyboardType: TextInputType.text,
              controller: reasonCtrl,
              maxLines: 2,
            ),
            SizedBox(height: 30.h),
            CustomButton(
              text: isReject ? "Reject" : "Approve",
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  CustomSnackBar.error("Reason required");
                  return;
                }

                final status = isReject ? "REJECTED" : "APPROVED";
                leaveController.updateLeaveStatus(leaveId, status, reasonCtrl.text.trim());
                Get.back();
              },
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}

class SwipeApproveReject extends StatefulWidget {
  final LeaveRequestModel leave;
  const SwipeApproveReject({super.key, required this.leave});

  @override
  State<SwipeApproveReject> createState() => _SwipeApproveRejectState();
}

class _SwipeApproveRejectState extends State<SwipeApproveReject> {
  double dragPosition = 0.0; 
  bool isCompleted = false; 
  final LeaveController leaveController = Get.find<LeaveController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 45.h,
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // LEFT TEXT (Reject)
          Positioned(
            left: 20.w,
            child: Opacity(
              opacity: dragPosition < 0 ? 1.0 : 0.5,
              child: Text(
                "REJECT",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),

          // RIGHT TEXT (Approve)
          Positioned(
            right: 20.w,
            child: Opacity(
              opacity: dragPosition > 0 ? 1.0 : 0.5,
              child: Text(
                "APPROVE",
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
            ),
          ),

          // DRAGGABLE THUMB
          Align(
            alignment: Alignment(dragPosition, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: isCompleted
                  ? null
                  : (details) {
                      setState(() {
                        dragPosition += details.delta.dx / 100.w;
                        dragPosition = dragPosition.clamp(-1.0, 1.0);
                      });
                    },
              onHorizontalDragEnd: (details) {
                if (dragPosition > 0.7) {
                  setState(() {
                    dragPosition = 1.0;
                    isCompleted = true;
                  });
                  leaveController.updateLeaveStatus(widget.leave.id, "APPROVED", "");
                } else if (dragPosition < -0.7) {
                  setState(() {
                    dragPosition = -1.0;
                    isCompleted = true;
                  });
                  _showRejectReasonDialog();
                } else {
                  setState(() {
                    dragPosition = 0.0;
                  });
                }
              },
              child: Container(
                width: 80.w,
                height: 38.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Icon(
                  isCompleted ? (dragPosition > 0 ? Icons.check : Icons.close) : Icons.swap_horiz,
                  color: dragPosition > 0
                      ? Colors.green
                      : (dragPosition < 0 ? Colors.red : theme.colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectReasonDialog() {
    final TextEditingController reasonCtrl = TextEditingController();
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text("Reject Reason", style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: reasonCtrl,
              hintText: "Why are you rejecting?",
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                dragPosition = 0.0;
                isCompleted = false;
              });
              Get.back();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                CustomSnackBar.error("Reason is required");
                return;
              }
              leaveController.updateLeaveStatus(
                widget.leave.id,
                "REJECTED",
                reasonCtrl.text.trim(),
              );
              Get.back();
            },
            child: const Text("Reject"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
