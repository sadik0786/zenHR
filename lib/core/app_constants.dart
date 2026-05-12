import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/core/theme.dart';

class AppConstants {
  static const int transitionDuration = 320;
  static const Transition transition = Transition.rightToLeft;

  static List<BoxShadow> boxShadow = [
    const BoxShadow(color: Color.fromARGB(25, 0, 0, 0), blurRadius: 3, offset: Offset(2, 2)),
  ];
  static InputBorder enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: ThemeClass.lightBgColor),
  );
  static InputBorder focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: ThemeClass.lightBgColor),
  );
  static InputBorder errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: ThemeClass.errorColor),
  );

  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ThemeClass.primaryGreen, ThemeClass.tealGreen],
  );

  // Storage Keys
  static const String tokenKey = "token";
  static const String userIdKey = "userId";
  static const String roleKey = "role";
  static const String nameKey = "name";
  static const String emailKey = "email";
  static const String mobileKey = "mobile";
  static const String roleIdKey = "roleId";
  static const String appLockPinKey = "appLockPin";

  // Roles
  static const String roleOwner = "owner";
  static const String roleSuperAdmin = "superAdmin";
  static const String roleCeo = "ceo";
  static const String roleHr = "hr";
  static const String roleManager = "manager";
  static const String roleAdmin = "admin";
  static const String roleEmployee = "employee";
  static const String roleAccountant = "accountant";

  // App Owner Email
  static const String ownerEmail = "alisadik99@gmail.com";

  // Helper to check if role is owner
  static bool isSuperUser(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == roleOwner; // Only 'owner' goes to SaaS Control Center
  }

  // Helper to check if the current user is the main App Owner
  static bool isAppOwner(String? email) {
    if (email == null) return false;
    return email.toLowerCase() == ownerEmail.toLowerCase();
  }
}
