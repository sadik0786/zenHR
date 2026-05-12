import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/saas/super_admin_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_button.dart';

class CompanyDetailsScreen extends StatelessWidget {
  final int companyId;
  
  const CompanyDetailsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    // SuperAdminController is already put in SuperAdminDashboard, so find is safe here
    final SuperAdminController controller = Get.find<SuperAdminController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Company Details"), centerTitle: true),
      body: Obx(() {
        final company = controller.companies.firstWhere(
          (c) => c['id'] == companyId,
          orElse: () => {},
        );

        if (company.isEmpty) return const Center(child: Text("Company not found"));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildHeader(context, company),
              const SizedBox(height: 20),
              _buildStatsSection(context, company),
              const SizedBox(height: 20),
              _buildDetailCard(context, "Subscription Details", [
                _detailRow(
                  "Current Plan",
                  company['subscription_plans']?['plan_name'] ?? "Basic",
                  Icons.card_membership_rounded,
                ),
                _detailRow(
                  "Status",
                  company['status'] ?? "ACTIVE",
                  Icons.verified_user_rounded,
                  isStatus: true,
                ),
                _detailRow("Company ID", "#${company['id']}", Icons.fingerprint_rounded),
              ]),
              const SizedBox(height: 20),
              _buildDetailCard(context, "Admin Information", [
                _detailRow(
                  "Primary Contact",
                  company['admin_name'] ?? "N/A",
                  Icons.person_outline_rounded,
                ),
                _detailRow("Admin Email", company['admin_email'] ?? "N/A", Icons.email_outlined),
              ]),
              const SizedBox(height: 40),
              CustomButton(
                text: "Manage Subscription Plan",
                onPressed: () => _showPlanManagementSheet(context, controller, company),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> company) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: ThemeClass.zenPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 60,
              color: ThemeClass.secondaryLightBlue,
            ),
          ),
          Text(
            company['company_name'] ?? "Unknown",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> company) {
    return Row(
      children: [
        _statItem(
          context,
          "Employees",
          "${company['employee_count'] ?? 0}",
          Icons.people,
          Colors.blue,
        ),
        const SizedBox(width: 15),
        _statItem(
          context,
          "Projects",
          "${company['project_count'] ?? 0}",
          Icons.assignment,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statItem(BuildContext context, String label, String val, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val, IconData icon, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus ? (val.toUpperCase() == 'ACTIVE' ? Colors.green : Colors.red) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanManagementSheet(BuildContext context, SuperAdminController controller, Map<String, dynamic> company) {
    final theme = Theme.of(context);
    final initialId = int.tryParse(company['plan_id']?.toString() ?? '1') ?? 1;
    final RxInt selectedPlanId = RxInt(initialId);

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text("Manage Subscription Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Obx(() {
              final currentId = selectedPlanId.value;
              return Column(
                children: controller.plans.map((plan) {
                  return _planOption(
                    plan['id'],
                    plan['plan_name'] ?? "Unknown",
                    "${plan['max_employees']} Employees Limit",
                    currentId,
                    (v) => selectedPlanId.value = v,
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 30),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value ? "Updating..." : "Save Changes",
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        try {
                          await controller.updateCompany(
                            companyId: company['id'],
                            companyName: company['company_name'],
                            status: company['status'],
                            planId: selectedPlanId.value,
                          );
                        } finally {
                          if (Navigator.canPop(Get.context!)) Navigator.pop(Get.context!);
                        }
                      },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _planOption(int id, String title, String subtitle, int selectedId, Function(int) onTap) {
    final isSelected = selectedId == id;
    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? ThemeClass.secondaryLightBlue : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          color: isSelected ? ThemeClass.secondaryLightBlue.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? ThemeClass.secondaryLightBlue : null,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? ThemeClass.secondaryLightBlue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
