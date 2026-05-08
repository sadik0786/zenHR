import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/utils/common_fn.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put the controller
    final UserController controller = Get.put(UserController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeClass.primaryGreen,
        elevation: 0,
        title: Text("My Profile", style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              controller.checkAuthAndNavigate();
            },
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? PageLoader()
            : Column(
                children: [
                  SizedBox(height: 30.h),
                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: controller.uploadPhoto,
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: ThemeClass.primaryGreen,
                        backgroundImage: controller.localAvatar.value != null
                            ? FileImage(controller.localAvatar.value!)
                            : (controller.avatarUrl.value != null
                                  ? NetworkImage(controller.avatarUrl.value!)
                                  : null),
                        child:
                            (controller.localAvatar.value == null &&
                                controller.avatarUrl.value == null)
                            ? Text(
                                CommonFn.getInitials(controller.userName.value),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall!.copyWith(fontSize: 40.sp),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Info card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Theme.of(context).cardColor,
                      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black12,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoItem(context, "Name", controller.userName.value),
                            _buildInfoItem(context, "Email", controller.email.value),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    context,
                                    "Mobile",
                                    controller.mobile.value,
                                    isMobile: true,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 25.sp,
                                    color: ThemeClass.warningColor,
                                  ),
                                  onPressed: () =>
                                      _showUpdateMobileBottomSheet(context, controller),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // log out card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Theme.of(context).cardColor,
                      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black12,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomButton(
                              icon: Icons.lock,
                              text: controller.savedPin.value == null
                                  ? "Set App Lock PIN"
                                  : "Change App Lock PIN",
                              onPressed: () => _showSetPinBottomSheet(context, controller),
                            ),
                            SizedBox(height: 20.h),
                            CustomButton(
                              backgroundColor: ThemeClass.errorColor,
                              icon: Icons.logout,
                              text: "Logout",
                              onPressed: controller.logOut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
      ),
    );
  }

  void _showUpdateMobileBottomSheet(BuildContext context, UserController controller) {
    final TextEditingController textController = TextEditingController(
      text: controller.mobile.value,
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 16.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Text("Update Number", style: Theme.of(ctx).textTheme.bodySmall),
              SizedBox(height: 20.h),
              CustomTextField(
                labelText: "Add Your Number",
                isRequired: false,
                hintText: "Enter number",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.number,
                controller: textController,
                maxLength: 10,
                fillColor: Theme.of(ctx).cardColor,
              ),
              SizedBox(height: 20.h),
              CustomButton(
                txtColor: ThemeClass.textBlack,
                backgroundColor: ThemeClass.textWhite,
                text: "Update",
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newMobile = textController.text.trim();
                    Navigator.pop(ctx);
                    controller.updateMobile(newMobile);
                  }
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String? value, {
    bool isMobile = false,
  }) {
    final displayValue = (value != null && value.isNotEmpty)
        ? (isMobile ? "+91 $value" : value)
        : "-";

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 4.h),
          Text(
            displayValue,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showSetPinBottomSheet(BuildContext context, UserController controller) {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 24.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.savedPin.value == null ? "Set App Lock PIN" : "Change App Lock PIN",
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                labelText: "Set PIN",
                hintText: "Enter 4-digit number",
                controller: pinController,
                keyboardType: TextInputType.number,
                isObscure: true,
                maxLength: 4,
                fillColor: Theme.of(ctx).cardColor,
                validator: (value) {
                  if (value == null || value.isEmpty) return "PIN required";
                  if (value.length != 4) return "PIN must be 4 digits";
                  return null;
                },
              ),
              CustomTextField(
                labelText: "Confirm Set PIN",
                hintText: "Enter 4-digit number",
                controller: confirmController,
                keyboardType: TextInputType.number,
                isObscure: true,
                maxLength: 4,
                fillColor: Theme.of(ctx).cardColor,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Confirm your PIN";
                  if (value != pinController.text) return "PINs do not match";
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              CustomButton(
                txtColor: ThemeClass.textBlack,
                backgroundColor: ThemeClass.textWhite,
                text: controller.savedPin.value == null ? "Save PIN" : "Update PIN",
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await controller.savePin(pinController.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    CustomSnackBar.success(
                      "PIN ${controller.savedPin.value == null ? "set" : "updated"} successfully!",
                    );
                  }
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
