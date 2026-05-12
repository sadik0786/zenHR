import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/widgets/pin_verification_dialog.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  late Animation<Color?> colorAnimation;

  final _supabase = Supabase.instance.client;

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

    colorAnimation = ColorTween(
      begin: const Color(0xFF0F2027),
      end: const Color(0xFFffffff),
    ).animate(animationController);

    animationController.forward();
  }

  Future<void> _startAppFlow() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      // Load user data into UserController
      final userController = Get.find<UserController>();
      await userController.loadUser();

      final prefs = await SharedPreferences.getInstance();
      final hasPin = prefs.getString(AppConstants.appLockPinKey) != null;
      
      if (hasPin) {
        if (Get.context != null) {
          final pinVerified = await PinVerificationDialog.show(Get.context!);
          if (!pinVerified) return; 
        }
      }

      final role = (userController.currentUser.value?.role ?? "").toLowerCase();
      
      if (role == AppConstants.roleOwner) {
        Get.offAllNamed(Routes.superAdminDashboard);
      } else {
        Get.offAllNamed(Routes.dashboard);
      }
    } catch (e) {
      print("Splash Auth Error: $e");
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
