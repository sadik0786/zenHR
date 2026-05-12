import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/auth/register_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_dropdown_field.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController registerController = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeClass.darkBgColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text("Add Employee", style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                // --- COMPANY CONTEXT HEADER ---
                Obx(() {
                  final user = Get.find<UserController>().currentUser.value;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.business_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Onboarding for Company",
                                style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey),
                              ),
                              Text(
                                "ID: #${user?.companyId ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 10.h),
                Obx(
                  () => Card(
                    color: ThemeClass.darkCardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                registerController.userName.value.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                " (${registerController.currentUserRole.value.toUpperCase()})",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall!.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          const Text(
                            "Onboarding new staff member to the company",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Form(
                  key: registerController.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20.h),
                      Obx(
                        () => CustomDropdownField<dynamic>(
                          isLoading: registerController.roleLoading.value,
                          labelText: "Select Role",
                          isRequired: true,
                          hintText: "Select Role",
                          prefixIcon: Icons.work,
                          items: registerController.roles,
                          valueKey: "id",
                          labelKey: "role_name",
                          value: registerController.selectedRoleId.value,
                          isEnabled: true,
                          onChanged: (value) async {
                            registerController.selectedRoleId.value = value;
                            final selectedRole = registerController.roles.firstWhere(
                              (r) => r["id"] == value,
                              orElse: () => {},
                            );
                            final selectedRoleName = (selectedRole["role_name"] ?? "")
                                .toString()
                                .toLowerCase();
                            await registerController.loadAssignableUsers(selectedRoleName);
                          },
                        ),
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        labelText: "Employee Name",
                        isRequired: true,
                        hintText: "Enter name",
                        prefixIcon: Icons.person,
                        controller: registerController.name,
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        labelText: "Employee Code",
                        isRequired: true,
                        hintText: "Enter employee code",
                        prefixIcon: Icons.badge,
                        controller: registerController.employeeCode,
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        labelText: "Employee Email",
                        isRequired: true,
                        hintText: "Enter email",
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        controller: registerController.email,
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        labelText: "Employee Number",
                        isRequired: false,
                        hintText: "Enter number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.number,
                        controller: registerController.mobile,
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        labelText: "Employee Password",
                        isRequired: true,
                        hintText: "Enter password",
                        prefixIcon: Icons.lock,
                        isObscure: true,
                        controller: registerController.password,
                      ),
                      SizedBox(height: 30.h),
                      Obx(
                        () => CustomButton(
                          text: "Submit Onboarding",
                          onPressed: registerController.register,
                          isLoading: registerController.loading.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
