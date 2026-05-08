import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/controllers/user/employee_controller.dart';
import 'package:zen_hr/controllers/user/user_controller.dart';
import 'package:zen_hr/core/app_constants.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/utils/common_fn.dart';

class EmployeeScreen extends StatelessWidget {
  EmployeeScreen({super.key});

  final EmployeeController empController = Get.put(EmployeeController());
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("All Employees", style: Theme.of(context).textTheme.titleLarge),
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
              userController.checkAuthAndNavigate();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (empController.loading.value) {
          return PageLoader();
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

              return Dismissible(
                key: Key(emp["ID"].toString()),
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
                      actionsAlignment: MainAxisAlignment.center,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Are you sure you want to delete?🤔",
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "👉${emp["Name"]}",
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: ThemeClass.textWhite,
                              fontSize: 20.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            "No",
                            style: TextStyle(
                              color: ThemeClass.textBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            "Yes",
                            style: TextStyle(
                              color: ThemeClass.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  empController.deleteEmployee(emp["ID"]);
                },
                child: Card(
                  color: Theme.of(context).cardColor,
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.only(left: 10.w, top: 4.h, bottom: 4.h, right: 10.w),
                    leading: CircleAvatar(
                      radius: 20.r,
                      backgroundColor: ThemeClass.primaryGreen,
                      backgroundImage: emp["ProfileImage"] != null && emp["ProfileImage"].isNotEmpty
                          ? NetworkImage("${emp["ProfileImage"]}")
                          : null,
                      child: emp["ProfileImage"] == null || emp["ProfileImage"].isEmpty
                          ? Text(
                              (emp["Name"] ?? "").toString().substring(0, 1).toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge,
                            )
                          : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(emp["Name"] ?? "", style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          "Role: ${CommonFn.toUpperCase(emp["RoleName"] ?? "")}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${emp["Email"] ?? ""}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (emp["RoleName"] != AppConstants.roleCeo)
                          Text(
                            "Assigned to : ${emp["ReportingName"] ?? ""}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        if (emp["Mobile"] != null && emp["Mobile"] != "")
                          Text(
                            "Mobile: ${emp["Mobile"]}",
                            style: Theme.of(context).textTheme.titleMedium,
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
