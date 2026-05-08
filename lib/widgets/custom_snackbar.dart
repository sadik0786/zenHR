import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/core/theme.dart';

class CustomSnackBar {
  static void show({
    String? title,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    int durationInSeconds = 3,
  }) {
    final isDark = Get.isDarkMode;

    Get.snackbar(
      title ?? '',
      message,
      titleText: title == null || title.isEmpty
          ? const SizedBox.shrink()
          : Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor:
          backgroundColor?.withOpacity(0.9) ??
          (isDark
              ? ThemeClass.darkCardColor.withOpacity(0.9)
              : ThemeClass.lightCardColor.withOpacity(0.9)),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 15,
      duration: Duration(seconds: durationInSeconds),
      icon: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      shouldIconPulse: false,
      barBlur: 10,
      boxShadows: [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
      ],
      snackStyle: SnackStyle.FLOATING,
    );
  }

  /// ✅ Success Snackbar (Green)
  static void success(String message, {String? title = "Success"}) {
    final isDark = Get.isDarkMode;
    show(
      title: title,
      message: message,
      backgroundColor: isDark ? ThemeClass.successColor : ThemeClass.successColor,
      icon: Icons.check_circle_outline,
    );
  }

  /// ❌ Error Snackbar (Red)
  static void error(String message, {String? title = "Error"}) {
    final isDark = Get.isDarkMode;
    show(
      title: title,
      message: message,
      backgroundColor: isDark ? ThemeClass.errorColor : ThemeClass.errorColor,
      icon: Icons.error_outline,
    );
  }

  /// ⚠️ Warning Snackbar (Orange)
  static void warning(String message, {String? title = "Warning"}) {
    final isDark = Get.isDarkMode;
    show(
      title: title,
      message: message,
      backgroundColor: isDark ? ThemeClass.warningColor : ThemeClass.warningColor,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// ℹ️ Info Snackbar (Blue)
  static void info(String message, {String? title = "Info"}) {
    final isDark = Get.isDarkMode;
    show(
      title: title,
      message: message,
      backgroundColor: isDark ? ThemeClass.darkBlue : ThemeClass.darkBlue,
      icon: Icons.info_outline,
    );
  }
}

// CustomSnackBar.show(
//   title: "Notice",
//   message: "Server will restart at 2 AM",
//   backgroundColor: Colors.purple,
//   icon: Icons.notifications_active,
// );
// CustomSnackBar.success("Employee added successfully!");
// CustomSnackBar.error("Failed to load data. Try again.");
// CustomSnackBar.warning("Please fill all required fields");
// CustomSnackBar.info("New version available!");
