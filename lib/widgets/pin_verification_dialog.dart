import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/app_constants.dart';

class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const PinVerificationDialog(),
    );
    return result ?? false;
  }

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  String? errorText;
  String? savedPin;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(4, (_) => TextEditingController());
    focusNodes = List.generate(4, (_) => FocusNode());
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    savedPin = prefs.getString(AppConstants.appLockPinKey);
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 30.h),
          Text("Enter App Lock PIN", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) {
              return SizedBox(
                width: 70.w,
                child: TextField(
                  autofocus: i == 0,
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: true,
                  cursorHeight: 30.sp,
                  cursorWidth: 2,
                  cursorColor: Colors.blueAccent,
                  style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 3) {
                      FocusScope.of(context).requestFocus(focusNodes[i + 1]);
                    }
                    if (val.isEmpty && i > 0) {
                      FocusScope.of(context).requestFocus(focusNodes[i - 1]);
                    }
                  },
                ),
              );
            }),
          ),
          if (errorText != null) ...[
            SizedBox(height: 8.h),
            Text(errorText!, style: const TextStyle(color: Colors.red)),
          ],
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(AppConstants.appLockPinKey);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                    Get.snackbar(
                      "Reset",
                      "PIN cleared, set a new one from profile",
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                  }
                },
                child: Text(
                  "Reset PIN?",
                  style: TextStyle(color: Colors.red, fontSize: 18.sp),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final enteredPin = controllers.map((c) => c.text).join();
                  if (enteredPin == savedPin) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      errorText = "Incorrect PIN";
                      for (var c in controllers) {
                        c.clear();
                      }
                      FocusScope.of(context).requestFocus(focusNodes[0]);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  backgroundColor: Colors.red,
                ),
                child: const Text("Unlock"),
              ),
            ],
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
