import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/model/auth/login_request_model.dart';
import 'package:zen_hr/services/auth_api_service.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';

class LoginController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  final formKey = GlobalKey<FormState>();
  Rx<TextEditingController> email = TextEditingController().obs;
  Rx<TextEditingController> password = TextEditingController().obs;
  RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
    ));

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    animationController.forward();
    _autoFillDemoCredentials();
  }

  @override
  void onClose() {
    animationController.dispose();
    email.value.dispose();
    password.value.dispose();
    super.onClose();
  }

  void _autoFillDemoCredentials() {
    email.value.text = "admin@zenhr.com";
    password.value.text = "admin\$123";
  }

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    if (!GetUtils.isEmail(value)) {
      return "Enter a valid email address";
    }
    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  Future<void> login() async {
    try {
      loading.value = true;
      if (!formKey.currentState!.validate()) {
        loading.value = false;
        return;
      }
      // Check internet before hitting API
      if (!await AuthApiService.hasInternetConnection()) {
        loading.value = false;
        CustomSnackBar.info("No Internet-Please check your connection");
        return;
      }
      final request = LoginRequestModel(
        email: email.value.text.trim(),
        password: password.value.text.trim(),
      );
      final res = await AuthApiService.login(request);
      if (res.success == true && res.token != null) {
        final user = res.user;
        if (user == null) throw Exception("User data missing");
        final role = (user.role ?? user.roleId ?? "").toString().toLowerCase();
        final userId = user.id ?? user.id;
        if (role.isEmpty || userId == null) throw Exception("Invalid user data");
        
        // Persist session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, res.token ?? "");
        await prefs.setString(AppConstants.roleKey, role);
        await prefs.setInt(AppConstants.userIdKey, userId);
        print("token: ${res.token}");
        print("role: $role");
        print("userId: $userId");

        // Initialize UserController and load data
        final userController = Get.find<UserController>();
        await userController.loadUser();

        //  role-based navigation
        switch (role) {
          case AppConstants.roleSuperAdmin:
            Get.offNamed(Routes.superAdminDashboard);
            break;
          case AppConstants.roleCeo:
          case AppConstants.roleHr:
          case AppConstants.roleManager:
          case AppConstants.roleAdmin:
          case AppConstants.roleEmployee:
            Get.offNamed(Routes.dashboard);
            break;
          default:
            await prefs.clear();
            Get.offNamed(Routes.login);
            return;
        }
        CustomSnackBar.show(
          message: "Welcome ${user.name ?? 'User'}!",
          backgroundColor: ThemeClass.successColor,
          icon: Icons.verified_user,
        );
      } else {
        final errorMsg = res.message ?? "Unable to login. Please try again.";
        CustomSnackBar.error(errorMsg);
      }
    } catch (e) {
      print("Login error catch: $e");
      loading.value = false;
      CustomSnackBar.error("Unable to connect to server. Please try again later.");
    } finally {
      loading.value = false;
    }
  }
}
