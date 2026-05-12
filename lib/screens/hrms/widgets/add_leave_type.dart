import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class AddLeaveType extends StatelessWidget {
  const AddLeaveType({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final LeaveController controller = Get.put(LeaveController());

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: "Financial Year (e.g. 2025-26)",
                    controller: controller.financialYearController,
                    prefixIcon: Icons.calendar_month_rounded,
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () => controller.fetchLeaveTypes(),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          _buildForm(controller),
          const Divider(),
          Expanded(child: _buildLeaveList(controller)),
        ],
      ),
    );
  }

  Widget _buildForm(LeaveController controller) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Form(
        key: controller.addLeaveTypeFormKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    hintText: "Leave Name",
                    controller: controller.leaveNameController,
                    isRequired: true,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomTextField(
                    hintText: "Days",
                    controller: controller.leaveDaysController,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: controller.editingId.value != null ? "Update Leave Type" : "Add Leave Type",
                  isLoading: controller.isLoading.value,
                  onPressed: () => controller.saveLeaveType(),
                ),
              ),
            ),
            Obx(
              () => controller.editingId.value != null
                  ? TextButton(
                      onPressed: () => controller.resetForm(),
                      child: const Text("Cancel Edit", style: TextStyle(color: Colors.red)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveList(LeaveController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.leaveTypes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.leaveTypes.isEmpty) {
        return const Center(child: Text("No leave types added for this year"));
      }

      return ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: controller.leaveTypes.length,
        separatorBuilder: (context, index) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final type = controller.leaveTypes[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: ThemeClass.secondaryLightBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    type['leave_count'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeClass.secondaryLightBlue,
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Text(
                    type['leave_name'],
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.startEditing(type),
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                )
              ],
            ),
          );
        },
      );
    });
  }
}
