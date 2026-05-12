import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/user/employee_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/utils/common_fn.dart';

class EmployeeScreen extends StatelessWidget {
  const EmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeeController empController = Get.put(EmployeeController());
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("All Employees", style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => userController.checkAuthAndNavigate(),
          ),
        ],
      ),
      body: Obx(() {
        if (empController.isLoading.value) {
          return const PageLoader();
        }

        if (empController.employees.isEmpty) {
          return Center(child: NoTasksWidget(message: "No Employee found"));
        }

        return RefreshIndicator(
          onRefresh: empController.fetchEmployees,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: empController.employees.length,
            itemBuilder: (context, index) {
              final emp = empController.employees[index];
              final roleName = emp["role_master"]?["role_name"] ?? "employee";

              return Dismissible(
                key: Key(emp["id"].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: ThemeClass.errorColor,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      title: const Text("Confirm Delete", textAlign: TextAlign.center),
                      content: Text(
                        "Are you sure you want to delete ${emp["name"]}?🤔",
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text("Yes", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  empController.deleteEmployee(emp["id"].toString());
                },
                child: Card(
                  color: Theme.of(context).cardColor,
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.w),
                    leading: CircleAvatar(
                      radius: 20.r,
                      backgroundColor: ThemeClass.primaryGreen,
                      backgroundImage: emp["profile_pic"] != null
                          ? NetworkImage("${emp["profile_pic"]}")
                          : null,
                      child: emp["profile_pic"] == null
                          ? Text((emp["name"] ?? "U")[0].toUpperCase())
                          : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(emp["name"] ?? "", style: Theme.of(context).textTheme.titleLarge),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            CommonFn.toUpperCase(roleName),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp["email"] ?? "", style: Theme.of(context).textTheme.titleMedium),
                        if (emp["designation"] != null)
                          Text(
                            "${emp["designation"]} | ${emp["department"] ?? ''}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
