import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/splash_controller.dart';
import 'package:zen_hr/core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(SplashController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Animated Logo with Glassmorphism
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) => Transform.scale(
                  scale: controller.scaleAnimation.value,
                  child: Opacity(
                    opacity: controller.fadeAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Image.asset(
                          "assets/zenhr_logo.png",
                          height: 100.sp,
                          width: 100.sp,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40.h),

              // App Name
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) => Opacity(
                  opacity: controller.fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        "ZENHR",
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6.0,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8.h),
                        height: 4.h,
                        width: 40.w,
                        decoration: BoxDecoration(
                          color: ThemeClass.secondaryLightBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "SMART HR MANAGEMENT SOLUTION",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 4),
              
              // Bottom Section
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) => Opacity(
                  opacity: controller.fadeAnimation.value,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 50.h),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 25.w,
                          height: 25.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "POWERED BY ZENHR SYSTEMS",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
