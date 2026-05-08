import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/services/auth_api_service.dart';
import 'package:zen_hr/widgets/pin_verification_dialog.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  late Animation<Color?> colorAnimation;

  @override
  void onInit() {
    super.onInit();
    _setupAnimations();
    _startAppFlow();
  }

  void _setupAnimations() {
    animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.elasticOut));

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeIn));

    // Note: Theme colors should be accessed via a context or fixed values if context is not available yet,
    // but here we can use the values from ThemeClass directly if imported, or pass them in.
    // For now, we will use default colors that match the original implementation.
    colorAnimation = ColorTween(
      begin: const Color(0xFF0F2027), // ThemeClass.primaryGreen (ZenHR Blue)
      end: const Color(0xFFffffff), // ThemeClass.textWhite
    ).animate(animationController);

    animationController.forward();
  }

  Future<void> _startAppFlow() async {
    // Delay to show splash animation
    await Future.delayed(const Duration(milliseconds: 1000));
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    if (token == null || token.isEmpty) {
      await _handleLogout(prefs);
      return;
    }

    // Check internet connection
    if (!await AuthApiService.hasInternetConnection()) {
      Get.snackbar(
        "No Internet",
        "Please check your connection",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Validate user token and get details
      final res = await AuthApiService.getCurrentUser();

      if (res["success"] != true || res["user"] == null) {
        await _handleLogout(prefs);
        return;
      }

      final user = res["user"];
      await prefs.setString(AppConstants.roleKey, user["RoleName"] ?? "");
      await prefs.setInt(AppConstants.userIdKey, user["ID"]);

      // Load user data into UserController
      final userController = Get.find<UserController>();
      await userController.loadUser();

      // Check PIN
      final hasPin = prefs.getString(AppConstants.appLockPinKey) != null;
      if (hasPin) {
        // We need context to show dialog
        if (Get.context != null) {
          final pinVerified = await PinVerificationDialog.show(Get.context!);
          if (!pinVerified) return; // Wrong PIN or closed
        }
      }

      _navigateBasedOnRole(user["RoleName"]);
    } catch (e) {
      Get.snackbar(
        "Server Error",
        "Unable to connect to server. Please try again later.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _navigateBasedOnRole(String? roleName) {
    final role = (roleName ?? "").toLowerCase();
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
        Get.offNamed(Routes.login);
    }
  }

  Future<void> _handleLogout(SharedPreferences prefs) async {
    await prefs.clear();
    Get.offNamed(Routes.login);
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
