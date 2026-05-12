import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/common/no_data.dart';
import 'package:zen_hr/common/page_loader.dart';
import 'package:zen_hr/screens/saas/attendance_machine_screen.dart';
import 'package:zen_hr/screens/saas/company_details_screen.dart';
import 'package:zen_hr/controllers/saas/super_admin_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';
import 'package:zen_hr/widgets/custom_button.dart';

class SuperAdminDashboard extends StatelessWidget {
  SuperAdminDashboard({super.key});

  final SuperAdminController controller = Get.put(SuperAdminController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("ZenHR Control Center"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ThemeClass.primaryGreen, ThemeClass.tealGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.fetchCompanies()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Get.offAllNamed('/login')),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: PageLoader());
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchCompanies(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCards(context),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Manage Companies",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : ThemeClass.zenPrimary,
                            ),
                          ),
                          _buildAddButton(context),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (controller.companies.isEmpty) ...[
                        const SizedBox(height: 40),
                        NoTasksWidget(
                          message: "No Companies Yet",
                          desc: "Start by onboarding a new client",
                        ),
                      ] else ...[
                        _buildCompanyList(context),
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return IconButton.filled(
      onPressed: () => _showAddCompanySheet(context),
      icon: const Icon(Icons.add_business_rounded),
      style: IconButton.styleFrom(
        backgroundColor: ThemeClass.zenPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                context,
                "Total Companies",
                "${controller.companies.length}",
                ThemeClass.zenAccent,
                Icons.business_center,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _statCard(
                context,
                "Active Clients",
                "${controller.companies.where((c) => (c['status'] ?? '').toString().toUpperCase() == 'ACTIVE').length}",
                Colors.greenAccent,
                Icons.verified_user_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Obx(() => _statCard(
          context,
          "Biometric Hub",
          "${controller.machines.length} Devices Connected",
          Colors.orangeAccent,
          Icons.fingerprint_rounded,
          onTap: () => Get.to(() => const AttendanceMachineScreen()),
        )),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String val,
    Color iconColor,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 15),
            Text(
              val,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : ThemeClass.zenPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showAddCompanySheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final compNameCtrl = TextEditingController();
    final planId = RxInt(1);
    final selectedRoleId = Rxn<int>(); // Add this
    final theme = Theme.of(context);

    // Default select CEO if available
    final ceoRole = controller.roles.firstWhereOrNull(
      (r) => r['role_name'].toString().toUpperCase() == 'CEO',
    );
    if (ceoRole != null) selectedRoleId.value = ceoRole['id'];

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Onboard New Company",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 30),
              CustomTextField(
                controller: compNameCtrl,
                labelText: "Company Name",
                hintText: "Enter company name",
                prefixIcon: Icons.business_rounded,
                isRequired: true,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: nameCtrl,
                labelText: "CEO Name",
                hintText: "Enter CEO full name",
                prefixIcon: Icons.person_outline_rounded,
                isRequired: true,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: emailCtrl,
                labelText: "CEO Email",
                hintText: "ceo@company.com",
                prefixIcon: Icons.email_outlined,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assign Role", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedRoleId.value,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      items: controller.roles
                          .where((r) {
                            // Ab ye database se decide hoga!
                            // Agar aapko future mein koi aur role dikhana hai,
                            // toh bas DB mein 'is_onboarding_role' ko TRUE kar dena.
                            return r['is_onboarding_role'] == true;
                          })
                          .map((r) {
                            return DropdownMenuItem<int>(
                              value: r['id'],
                              child: Text(r['role_name'].toString()),
                            );
                          })
                          .toList(),
                      onChanged: (val) => selectedRoleId.value = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: passCtrl,
                labelText: "Temporary Password",
                hintText: "••••••••",
                prefixIcon: Icons.lock_outline_rounded,
                isObscure: true,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Subscription Plan", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: 1, // Default to Basic
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.star_rounded, color: Colors.orange),
                      ),
                      items: controller.plans.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text("${p['plan_name']} (${p['max_employees']} Emp)"),
                        );
                      }).toList(),
                      onChanged: (val) => planId.value = val ?? 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Obx(
                () => CustomButton(
                  text: controller.isLoading.value ? "Processing..." : "Create Company",
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (compNameCtrl.text.isEmpty ||
                              emailCtrl.text.isEmpty ||
                              selectedRoleId.value == null) {
                            CustomSnackBar.error("Please fill all fields and select a role");
                            return;
                          }
                          await controller.addCompany(
                            companyName: compNameCtrl.text,
                            adminName: nameCtrl.text,
                            adminEmail: emailCtrl.text,
                            adminPassword: passCtrl.text,
                            planId: planId.value,
                            roleId: selectedRoleId.value!,
                          );
                          if (Navigator.canPop(Get.context!)) Navigator.pop(Get.context!);
                        },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCompanySheet(BuildContext context, Map<String, dynamic> comp) {
    final compNameCtrl = TextEditingController(text: comp['company_name']);
    final status = RxString(comp['status']?.toString() ?? 'ACTIVE');
    final selectedPlanId = RxInt(int.tryParse(comp['plan_id']?.toString() ?? '1') ?? 1);
    final theme = Theme.of(context);

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Edit Company Settings",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 30),
              CustomTextField(
                controller: compNameCtrl,
                labelText: "Company Name",
                prefixIcon: Icons.business_rounded,
                hintText: "Enter Company Name",
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Subscription Plan", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedPlanId.value,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.star_rounded, color: Colors.orange),
                      ),
                      items: controller.plans.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text("${p['plan_name']} (${p['max_employees']} Emp)"),
                        );
                      }).toList(),
                      onChanged: (val) => selectedPlanId.value = val ?? 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Account Status", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statusChoiceChip("ACTIVE", status),
                        const SizedBox(width: 10),
                        _statusChoiceChip("INACTIVE", status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Obx(
                () => CustomButton(
                  text: controller.isLoading.value ? "Updating..." : "Save Changes",
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          await controller.updateCompany(
                            companyId: comp['id'],
                            companyName: compNameCtrl.text,
                            status: status.value,
                            planId: selectedPlanId.value,
                          );
                          if (Navigator.canPop(Get.context!)) Navigator.pop(Get.context!);
                        },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChoiceChip(String label, RxString groupValue) {
    final isSelected = groupValue.value == label;
    final color = label == "ACTIVE" ? Colors.green : Colors.red;

    return Expanded(
      child: InkWell(
        onTap: () => groupValue.value = label,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.companies.length,
      itemBuilder: (context, index) {
        final comp = controller.companies[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.08)),
          ),
          child: ListTile(
            onTap: () => Get.to(() => CompanyDetailsScreen(companyId: comp['id'])),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeClass.zenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.business_rounded, color: ThemeClass.zenAccent),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    comp['company_name'] ?? "Unknown",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _statusIndicatorChip(comp['status'] ?? 'ACTIVE'),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoBadge(context, "Plan #${comp['plan_id'] ?? 1}"),
                    const SizedBox(width: 8),
                    _infoBadge(context, "ID: ${comp['id']}"),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white60 : Colors.black54),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 12), Text("Full Details")],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [Icon(Icons.edit, size: 18), SizedBox(width: 12), Text("Settings")],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text("Delete", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditCompanySheet(context, comp);
                } else if (val == 'details') {
                  Get.to(() => CompanyDetailsScreen(companyId: comp['id']));
                } else if (val == 'delete') {
                  _showDeleteConfirmation(context, comp);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _statusIndicatorChip(String status) {
    final bool isActive = status.toUpperCase() == "ACTIVE";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isActive ? Colors.green : Colors.red).withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> comp) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Company?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete ${comp['company_name']}? This will remove all associated data including employees and records.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCompany(comp['id']);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ThemeClass.zenAccent,
        ),
      ),
    );
  }
}
