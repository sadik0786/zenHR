import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeClass {
  // ZenHR Brand Colors
  static const Color zenPrimary = Color(0xFF0F2027); // Deep Midnight Blue
  static const Color zenSecondary = Color(0xFF2C5364); // Deep Teal/Blue
  static const Color zenAccent = Color(0xFF6dcff6); // Sky Blue (For icons/highlights)

  // Backup Aliases
  static const Color primaryGreen = zenPrimary;
  static const Color darkBlue = zenPrimary;
  static const Color tealGreen = zenSecondary;
  static const Color secondaryLightBlue = zenAccent;
  
  static const Color successColor = Color(0xFF74bb44);
  static const Color warningColor = Color(0xFFfaa749);
  static const Color errorColor = Color(0xFFE53935);

  // Backgrounds
  static const Color darkBgColor = Color(0xFF0F2027);
  static const Color lightBgColor = Color(0xFFF0F4F8);

  static const Color darkCardColor = Color(0xFF1B2C33); // Elevated background for cards
  static const Color lightCardColor = Color(0xFFFFFFFF);

  // Text colors
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E9E9E);

  // Common font
  static const String fontFamily = 'OpenSansRegular';

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: lightBgColor,
    brightness: Brightness.light,
    primaryColor: zenPrimary,
    cardColor: lightCardColor,
    colorScheme: const ColorScheme.light(
      primary: zenPrimary,
      onPrimary: Colors.white,
      secondary: zenSecondary,
      onSecondary: Colors.white,
      surface: lightCardColor,
      onSurface: textBlack,
      error: errorColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: zenPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: zenPrimary),
    textTheme: TextTheme(
      bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: textBlack),
      titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textBlack),
      titleMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textBlack),
      labelMedium: TextStyle(fontSize: 12.sp, color: textGrey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: zenPrimary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: zenSecondary.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: zenPrimary)),
      labelStyle: const TextStyle(color: zenPrimary),
    ),
    fontFamily: fontFamily,
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: darkBgColor,
    brightness: Brightness.dark,
    primaryColor: zenPrimary,
    cardColor: darkCardColor,
    colorScheme: const ColorScheme.dark(
      primary: zenAccent,
      onPrimary: zenPrimary,
      secondary: zenSecondary,
      onSecondary: Colors.white,
      surface: darkCardColor,
      onSurface: textWhite,
      error: errorColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: zenPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: zenAccent),
    textTheme: TextTheme(
      bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: textWhite),
      titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textWhite),
      titleMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textWhite),
      labelMedium: TextStyle(fontSize: 12.sp, color: Colors.white60),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: zenAccent,
        foregroundColor: zenPrimary,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: zenAccent)),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    fontFamily: fontFamily,
  );
}
