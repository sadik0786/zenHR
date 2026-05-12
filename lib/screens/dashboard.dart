import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/widgets/custom_appbar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
  }

  List<_DashboardItem> _getMenuItems(UserController userController) {
    final String role = (userController.currentUser.value?.role ?? "").toLowerCase();

    List<_DashboardItem> items = [];

    // Common Menu
    items.add(
      _DashboardItem(
        title: 'My Profile',
        icon: Icons.person_pin_rounded,
        gradient: [Colors.purple.shade400, Colors.purple.shade700],
        onTap: () => Get.toNamed(Routes.profileScreen),
      ),
    );

    // CEO & HR Menu
    if (role == 'ceo' || role == 'hr') {
      items.add(
        _DashboardItem(
          title: 'Add Employees',
          icon: Icons.people_alt_rounded,
          gradient: [Colors.blue.shade400, Colors.blue.shade700],
          onTap: () => Get.toNamed(Routes.registerScreen),
        ),
      );
      items.add(
        _DashboardItem(
          title: 'Employee List',
          icon: Icons.people_outline_rounded,
          gradient: [Colors.green.shade400, Colors.green.shade700],
          onTap: () => Get.toNamed(Routes.employeeScreen),
        ),
      );
      items.add(
        _DashboardItem(
          title: 'Attendance Logs',
          icon: Icons.fact_check_rounded,
          gradient: [Colors.orange.shade400, Colors.orange.shade700],
          onTap: () => Get.toNamed(Routes.adminAttendance),
        ),
      );
    }

    // Employee Menus
    items.add(
      _DashboardItem(
        title: 'My Attendance',
        icon: Icons.access_time_filled_rounded,
        gradient: [Colors.pink.shade400, Colors.pink.shade700],
        onTap: () => Get.toNamed(Routes.attendanceScreen),
      ),
    );
    items.add(
      _DashboardItem(
        title: 'Leaves',
        icon: Icons.event_available_rounded,
        gradient: [Colors.indigo.shade400, Colors.indigo.shade700],
        onTap: () => Get.toNamed(Routes.hrmsDashboard),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    return Obx(() {
      final items = _getMenuItems(userController);

      return Scaffold(
        appBar: CommonAppBar(
          title: "Dashboard",
          userName: userController.currentUser.value?.name ?? "User",
          onLogout: userController.handleLogout,
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20.h,
                crossAxisSpacing: 40.w,
                children: items.map((item) => _GlassCard(item: item)).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _GlassCard extends StatefulWidget {
  final _DashboardItem item;

  const _GlassCard({required this.item});

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.item.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: widget.item.gradient.last.withOpacity(0.4),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.item.icon, size: 45.sp, color: Colors.white),
                SizedBox(height: 10.h),
                Text(
                  widget.item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
