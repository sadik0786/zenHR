import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/screens/hrms/widgets/add_leave_type.dart';
import 'package:zen_hr/screens/hrms/widgets/apply_leave.dart';
import 'package:zen_hr/screens/hrms/widgets/approve_leave.dart';
import 'package:zen_hr/screens/hrms/widgets/leave_balance.dart';
import 'package:zen_hr/screens/hrms/widgets/leave_home.dart';

class HrmsDashboard extends StatefulWidget {
  const HrmsDashboard({super.key});

  @override
  State<HrmsDashboard> createState() => _HrmsDashboardState();
}

class _HrmsDashboardState extends State<HrmsDashboard> {
  final LeaveController leaveController = Get.put(LeaveController());
  final UserController userController = Get.find<UserController>();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final role = userController.role.value.toLowerCase();

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: ThemeClass.primaryGreen,
          elevation: 0,
          title: Text(switch (_selectedIndex) {
            0 => "Leave Home",
            1 => "Add Leave Type",
            2 => "Apply Leave",
            3 => "Approve Leave",
            4 => "Leave Balance",
            _ => "HR Management",
          }, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => userController.checkAuthAndNavigate(),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              const LeaveHome(), // index 0
              const AddLeaveType(), // index 1
              const ApplyLeave(), // index 2
              const ApproveLeave(), // index 3
              const LeaveBalance(), // index 4
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ThemeClass.primaryGreen, ThemeClass.tealGreen],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.manage_accounts, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      'Manage Leaves',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Leave Home'),
                selected: _selectedIndex == 0,
                onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              if (role == AppConstants.roleHr)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add Leave Type'),
                  selected: _selectedIndex == 1,
                  onTap: () {
                    _onItemTapped(1);
                    Navigator.pop(context);
                  },
                ),
              if (role != AppConstants.roleCeo)
                ListTile(
                  leading: const Icon(Icons.post_add),
                  title: const Text('Apply Leave'),
                  selected: _selectedIndex == 2,
                  onTap: () {
                    _onItemTapped(2);
                    Navigator.pop(context);
                  },
                ),
              if (role == AppConstants.roleCeo || role == AppConstants.roleHr || role == AppConstants.roleManager)
                ListTile(
                  leading: const Icon(Icons.rule),
                  title: const Text('Approve Emp. Leave'),
                  selected: _selectedIndex == 3,
                  onTap: () {
                    _onItemTapped(3);
                    Navigator.pop(context);
                  },
                ),
              if (role != AppConstants.roleCeo)
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Leave Balance'),
                  selected: _selectedIndex == 4,
                  onTap: () {
                    _onItemTapped(4);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      );
    });
  }
}
