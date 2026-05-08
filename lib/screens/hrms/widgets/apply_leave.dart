import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_date_field.dart';
import 'package:zen_hr/widgets/custom_dropdown_field.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class ApplyLeave extends StatelessWidget {
  const ApplyLeave({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LeaveController leaveController = Get.find<LeaveController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final selected = leaveController.selectedLeaveType;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selected != null) ...[
                    _leaveCard(
                      context,
                      leaveName: selected.leaveName ?? "Selected Leave",
                      total: selected.leaveCount?.toDouble() ?? 0,
                      used: leaveController.calculateUsedLeaves(selected.leaveName),
                      pendingDays: leaveController.calculatePendingLeaves(selected.leaveName),
                      selectedDays: leaveController.calculateLeaveDays(),
                    ),
                    SizedBox(height: 30.h),
                  ],
                  Text(
                    "Request Time Off",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: leaveController.applyLeaveFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomDropdownField<int>(
                          labelText: "Leave Category",
                          isRequired: true,
                          hintText: "Select leave type",
                          prefixIcon: Icons.category_rounded,
                          items: leaveController.leaveTypes.map((p) {
                            return {"id": p.id ?? 0, "name": p.leaveName ?? ""};
                          }).toList(),
                          valueKey: "id",
                          labelKey: "name",
                          value: leaveController.selectedLeaveTypeId.value,
                          isEnabled: true,
                          onChanged: leaveController.onLeaveTypeChanged,
                        ),
                        SizedBox(height: 15.h),
                        CustomDateField(
                          labelText: "Start Date",
                          isRequired: true,
                          selectedDate: leaveController.fromDate.value,
                          hintText: "Select from date",
                          prefixIcon: Icons.calendar_today_rounded,
                          onTap: () => leaveController.pickDate(context, true),
                        ),
                        SizedBox(height: 15.h),
                        CustomDateField(
                          labelText: "End Date",
                          isRequired: true,
                          selectedDate: leaveController.toDate.value,
                          hintText: "Select to date",
                          prefixIcon: Icons.calendar_today_rounded,
                          onTap: () => leaveController.pickDate(context, false),
                        ),
                        SizedBox(height: 15.h),
                        CustomDropdownField<int>(
                          labelText: "Session Preference",
                          isRequired: true,
                          hintText: "Select session",
                          prefixIcon: Icons.access_time_rounded,
                          items: leaveController.leaveSessions,
                          valueKey: "id",
                          labelKey: "name",
                          value: leaveController.selectedSessionId.value,
                          isEnabled: true,
                          onChanged: (val) {
                            if (val != null) {
                              leaveController.selectedSessionId.value = val;
                            }
                          },
                        ),
                        SizedBox(height: 15.h),
                        CustomTextField(
                          labelText: "Reason for Absence",
                          hintText: "Enter your reason here...",
                          controller: leaveController.reasonController,
                          prefixIcon: Icons.edit_note_rounded,
                          maxLines: 2,
                        ),
                        SizedBox(height: 35.h),
                        CustomButton(
                          icon: Icons.send_rounded,
                          text: leaveController.isLoading.value ? "Processing..." : "Submit Leave Request",
                          onPressed: leaveController.isLoading.value
                              ? null
                              : leaveController.submitLeaveRequest,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _leaveCard(
    BuildContext context, {
    required String leaveName,
    required double total,
    required double used,
    required double pendingDays,
    required double selectedDays,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final balance = total - used;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leaveName,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDark ? ThemeClass.zenAccent : ThemeClass.zenPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (pendingDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeClass.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Pending: $pendingDays",
                    style: TextStyle(
                      color: ThemeClass.warningColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _balanceItem(context, "Total", total.toStringAsFixed(0)),
              _balanceItem(context, "Used", used.toStringAsFixed(1)),
              _balanceItem(context, "Balance", balance.toStringAsFixed(1), isHighlight: true),
            ],
          ),
          if (selectedDays > 0) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor.withOpacity(0.1)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Requested Duration", style: theme.textTheme.labelMedium),
                Text(
                  "$selectedDays Days",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: ThemeClass.zenAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceItem(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: isHighlight ? Colors.greenAccent : null,
          ),
        ),
      ],
    );
  }
}
