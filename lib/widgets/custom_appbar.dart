import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zen_hr/core/theme.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? userName;
  final VoidCallback onLogout;

  const CommonAppBar({
    super.key,
    required this.title,
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeClass.primaryGreen,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset("assets/zenhr_logo.png", height: 30.h),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        Text(
          "Hi, ${userName ?? ""}  ",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
