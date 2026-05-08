import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class AddLeaveType extends StatelessWidget {
  const AddLeaveType({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final LeaveController leaveController = Get.find<LeaveController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20.h),
            Text(
              "Configure Leave Policies",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              "Define new leave categories for your organization.",
              style: theme.textTheme.labelMedium,
            ),
            SizedBox(height: 30.h),
            Form(
              key: leaveController.addLeaveTypeFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: leaveController.leaveNameController,
                    labelText: "Leave Name",
                    hintText: "e.g. Sick Leave, Annual Leave",
                    isRequired: true,
                    prefixIcon: Icons.category_outlined,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextField(
                    controller: leaveController.leaveCountController,
                    labelText: "Leave Count (Days)",
                    hintText: "Enter number of days",
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.event_available_outlined,
                  ),
                  SizedBox(height: 35.h),
                  Obx(
                    () => CustomButton(
                      icon: Icons.save_rounded,
                      text: leaveController.isLoading.value ? "Saving..." : "Register Leave Type",
                      onPressed: leaveController.isLoading.value
                          ? null
                          : leaveController.submitLeaveType,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            Divider(color: theme.dividerColor.withOpacity(0.1)),
            SizedBox(height: 30.h),
            Text(
              "Existing Leave Types",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Obx(() {
              if (leaveController.isLoading.value && leaveController.leaveTypes.isEmpty) {
                return const PageLoader();
              }
              if (leaveController.leaveTypes.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: const NoTasksWidget(message: "No leave policies defined yet."),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaveController.leaveTypes.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final leave = leaveController.leaveTypes[index];
                  return Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.leaveName ?? "",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Standard Policy",
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            "${leave.leaveCount ?? 0} Days",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}
