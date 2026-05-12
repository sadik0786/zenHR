import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/screens/auth/login_screen.dart';
import 'package:zen_hr/screens/hrms/attendance_screen.dart';
import 'package:zen_hr/screens/hrms/attendance_report_screen.dart';
import 'package:zen_hr/screens/hrms/admin_attendance_screen.dart';
import 'package:zen_hr/screens/hrms/hrms_dashboard.dart';
import 'package:zen_hr/screens/hrms/widgets/add_leave_type.dart';
import 'package:zen_hr/screens/hrms/widgets/apply_leave.dart';
import 'package:zen_hr/screens/hrms/widgets/approve_leave.dart';
import 'package:zen_hr/screens/hrms/widgets/leave_balance.dart';
import 'package:zen_hr/screens/hrms/widgets/leave_home.dart';
import 'package:zen_hr/screens/profile/profile_screen.dart';
import 'package:zen_hr/screens/splash_screen.dart';
// after login
import 'package:zen_hr/screens/dashboard.dart';
import 'package:zen_hr/screens/auth/register_screen.dart';
import 'package:zen_hr/screens/user/employee_screen.dart';
import 'package:zen_hr/screens/saas/super_admin_dashboard.dart';

class Routes {
  static const String initialRoute = "/splash";
  static const String registerScreen = "/registerScreen";
  static const String login = "/login";
  // after login
  static const String dashboard = "/dashboard";
  static const String superAdminDashboard = "/superAdminDashboard";
  static const String profileScreen = "/profileScreen";
  static const String employeeScreen = "/employeeScreen";
  //hrms
  static const String hrmsDashboard = "/hrmsDashboard";
  static const String leaveHome = "/leaveHome";
  static const String addLeaveType = "/addLeaveType";
  static const String applyLeave = "/applyLeave";
  static const String approveLeave = "/approveLeave";
  static const String leaveBalance = "/leaveBalance";
  static const String attendanceScreen = "/attendanceScreen";
  static const String attendanceReport = "/attendanceReport";
  static const String adminAttendance = "/adminAttendance";
}

const Duration transitionDuration = Duration(milliseconds: AppConstants.transitionDuration);

GetPage _getPage(String name, Widget page) => GetPage(
  name: name,
  page: () => page,
  transition: AppConstants.transition,
  fullscreenDialog: true,
  transitionDuration: transitionDuration,
);

List<GetPage> appPages() => [
  _getPage(Routes.initialRoute, SplashScreen()),
  _getPage(Routes.registerScreen, RegisterScreen()),
  _getPage(Routes.login, LoginScreen()),
  // after login
  _getPage(Routes.dashboard, Dashboard()),
  _getPage(Routes.superAdminDashboard, SuperAdminDashboard()),
  _getPage(Routes.profileScreen, ProfileScreen()),
  _getPage(Routes.employeeScreen, EmployeeScreen()),
  //hrms
  _getPage(Routes.hrmsDashboard, HrmsDashboard()),
  _getPage(Routes.leaveHome, LeaveHome()),
  _getPage(Routes.addLeaveType, AddLeaveType()),
  _getPage(Routes.applyLeave, ApplyLeave()),
  _getPage(Routes.approveLeave, ApproveLeave()),
  _getPage(Routes.leaveBalance, LeaveBalance()),
  _getPage(Routes.attendanceScreen, AttendanceScreen()),
  _getPage(Routes.attendanceReport, AttendanceReportScreen()),
  _getPage(Routes.adminAttendance, const AdminAttendanceScreen()),
];
