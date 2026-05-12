import 'package:get/get.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/controllers/theme_controller.dart';
import 'package:zen_hr/controllers/hrms/leave_controller.dart';
import 'package:zen_hr/controllers/saas/super_admin_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.lazyPut(() => LeaveController());
    Get.lazyPut(() => SuperAdminController());
  }
}
