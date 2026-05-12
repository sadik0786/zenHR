import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/theme.dart';

class LeaveBalance extends StatelessWidget {
  const LeaveBalance({super.key});

  @override
  Widget build(BuildContext context) {
    final LeaveController controller = Get.find<LeaveController>();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Obx(() {
        if (controller.isLoading.value && controller.leaveTypes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 15.h,
            crossAxisSpacing: 15.w,
            childAspectRatio: 1,
          ),
          itemCount: controller.leaveTypes.length,
          itemBuilder: (context, index) {
            final type = controller.leaveTypes[index];
            final name = type["leave_name"] ?? "Leave";
            final total = (type["leave_count"] ?? 0).toDouble();
            final used = controller.calculateUsedLeaves(name);
            final balance = total - used;

            return _balanceCard(context, name, total, used, balance);
          },
        );
      }),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    String name,
    double total,
    double used,
    double balance,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ThemeClass.darkCardColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          SizedBox(height: 10.h),
          Text(
            balance.toStringAsFixed(1),
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Text("Available", style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: $total", style: const TextStyle(fontSize: 9, color: Colors.grey)),
              Text("Used: $used", style: const TextStyle(fontSize: 9, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }
}
