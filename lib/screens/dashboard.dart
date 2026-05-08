import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/widgets/custom_appbar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
  }



  List<_DashboardItem> _getMenuItems() {
    final String role = userController.role.value.toLowerCase();

    List<_DashboardItem> items = [
      _DashboardItem(
        title: 'My Profile',
        icon: Icons.account_circle,
        gradient: [Colors.purpleAccent.shade200, Colors.purpleAccent.shade100],
        onTap: () => Get.toNamed(Routes.profileScreen),
      ),
    ];

    if (role == AppConstants.roleCeo || role == AppConstants.roleHr) {
      items.add(
        _DashboardItem(
          title: 'Employees',
          icon: Icons.people,
          gradient: [Colors.greenAccent.shade400, Colors.greenAccent.shade200],
          onTap: () => Get.toNamed(Routes.employeeScreen),
        ),
      );
      items.add(
        _DashboardItem(
          title: 'Add Employee',
          icon: Icons.person_add,
          gradient: [Colors.lightBlueAccent.shade400, Colors.lightBlueAccent.shade200],
          onTap: () => Get.toNamed(Routes.registerScreen),
        ),
      );
    }

    items.add(
        _DashboardItem(
          title: 'Manage Leave',
          icon: Icons.manage_history,
          gradient: [Colors.orangeAccent.shade400, Colors.orangeAccent.shade200],
          onTap: () => Get.toNamed(Routes.hrmsDashboard),
        ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _getMenuItems();

      return Scaffold(
        appBar: CommonAppBar(
          title: "ZenHR",
          userName: userController.userName.value,
          onLogout: userController.logOut,
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20.h,
                crossAxisSpacing: 30.w,
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
                color: widget.item.gradient.last.withValues(alpha: 0.4),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.item.icon, size: 50.sp, color: Colors.white),
                SizedBox(height: 14.h),
                Text(
                  widget.item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
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
