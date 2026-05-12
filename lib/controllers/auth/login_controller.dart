import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/routes.dart';

class LoginController extends GetxController with GetSingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  late AnimationController animationController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    animationController.forward();
    _autoFillDemoCredentials();
  }

  void _autoFillDemoCredentials() {
    email.text = "alisadik99@gmail.com";
    password.text = "@ZenHr@admin@";
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    if (!GetUtils.isEmail(value)) return "Enter a valid email address";
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      loading.value = true;

      // 1. Secure Login with Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (res.user != null) {
        // 2. Fetch User Profile with Self-Healing Logic
        var userData = await _supabase
            .from('users')
            .select('*, role_master(role_name)')
            .eq('id', res.user!.id)
            .maybeSingle();

        if (userData == null) {
          // If UUID lookup fails, try Email lookup (for legacy integer-id accounts)
          userData = await _supabase
              .from('users')
              .select('*, role_master(role_name)')
              .eq('email', email.text.trim())
              .maybeSingle();

          if (userData != null) {
            // Found by email, update the legacy integer ID to the new Auth UUID
            await _supabase
                .from('users')
                .update({'id': res.user!.id})
                .eq('email', email.text.trim());
            print("Migrated legacy user profile to UUID: ${res.user!.id}");
          }
        }

        String role = 'employee';
        String userName = res.user!.email?.split('@')[0] ?? "User";

        // Check for hardcoded App Owner by Email
        if (AppConstants.isAppOwner(res.user?.email)) {
          role = AppConstants.roleOwner;
          print("App Owner detected: $role");
        }

        // 3. Self-Healing: If profile is missing but it's the App Owner, create it
        if (userData == null && AppConstants.isAppOwner(res.user?.email)) {
          final roleRes = await _supabase
              .from('role_master')
              .select('id')
              .eq('role_name', 'owner')
              .single();

          await _supabase.from('users').insert({
            'id': res.user!.id,
            'name': 'Ali Sadik',
            'email': res.user!.email!,
            'role_id': roleRes['id'],
            'is_active': true,
            'password': password.text.trim(),
          });

          // Re-fetch to get the role_master join
          userData = await _supabase
              .from('users')
              .select('*, role_master(role_name)')
              .eq('id', res.user!.id)
              .single();
        }

        if (userData != null) {
          // If profile exists, use DB role unless it's the App Owner (who is always 'owner')
          if (!AppConstants.isAppOwner(res.user?.email)) {
            role = (userData['role_master']?['role_name'] ?? 'employee').toString();
          }
          userName = userData['name'] ?? userName;
        }

        print("Logged in user role: $role");

        // 4. Persist session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, res.session?.accessToken ?? "");
        await prefs.setString(AppConstants.roleKey, role);
        await prefs.setString(AppConstants.userIdKey, res.user!.id);
        await prefs.setString(AppConstants.emailKey, res.user?.email ?? "");

        CustomSnackBar.show(
          message: "Welcome $userName!",
          backgroundColor: ThemeClass.successColor,
          icon: Icons.verified_user,
        );

        // 5. Refresh UserController to load profile data
        final UserController userController = Get.find<UserController>();
        await userController.loadUser();

        // 6. Role-based navigation
        if (role == AppConstants.roleOwner) {
          Get.offAllNamed(Routes.superAdminDashboard);
        } else {
          Get.offAllNamed(Routes.dashboard);
        }
      }
    } on AuthException catch (e) {
      CustomSnackBar.error(e.message);
    } catch (e) {
      print("Login error: $e");
      CustomSnackBar.error("An unexpected error occurred");
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
