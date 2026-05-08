import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/saas/super_admin_controller.dart';
import 'package:zen_hr/core/theme.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class AttendanceMachineScreen extends StatelessWidget {
  const AttendanceMachineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<SuperAdminController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Biometric Hub"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showConnectMachineSheet(context, controller),
            icon: const Icon(Icons.add_to_queue_rounded, color: ThemeClass.zenPrimary),
          ),
        ],
      ),
      body: Obx(() {
        final machines = controller.machines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStats(context, machines.length),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "${machines.length} Active Machines",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            if (machines.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 80,
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                      const SizedBox(height: 20),
                      const Text("No machines connected yet", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => _showConnectMachineSheet(context, controller),
                        child: const Text("Link Your First Device"),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: machines.length,
                  itemBuilder: (context, index) {
                    final device = machines[index];
                    final isOnline = device['status'] == 'Online';
                    final company = device['companies'] as Map<String, dynamic>?;

                    return InkWell(
                      onTap: () => _showManageMachineSheet(context, controller, device),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ThemeClass.zenPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    company?['company_name'] ?? "Master",
                                    style: const TextStyle(
                                      color: ThemeClass.secondaryLightBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lan_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device['device_name'] ?? "Unknown Device",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "IP: ${device['ip_address']} • S/N: ${device['serial_number']}",
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStats(BuildContext context, int total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeClass.zenPrimary, ThemeClass.zenPrimary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: ThemeClass.zenPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [_statCol("Total Devices", "$total"), _statCol("Status", "ONLINE")],
      ),
    );
  }

  Widget _statCol(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  void _showConnectMachineSheet(BuildContext context, SuperAdminController controller, {Map<String, dynamic>? existingDevice}) {
    final theme = Theme.of(context);
    final isEdit = existingDevice != null;
    
    final nameCtrl = TextEditingController(text: existingDevice?['device_name'] ?? "");
    final ipCtrl = TextEditingController(text: existingDevice?['ip_address'] ?? "");
    final snCtrl = TextEditingController(text: existingDevice?['serial_number'] ?? "");
    
    int? selectedId = existingDevice?['company_id'];

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
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                isEdit ? "Update Device Details" : "Connect New Device",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                isEdit
                    ? "Modify settings for this biometric machine"
                    : "Link a biometric device to a specific client",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),

              DropdownButtonFormField<int>(
                value: selectedId,
                decoration: InputDecoration(
                  labelText: "Select Company",
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: (isEdit 
                    ? controller.companies.where((c) => c['id'] == selectedId)
                    : controller.companies)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as int,
                        child: Text(c['company_name'] ?? ""),
                      ),
                    )
                    .toList(),
                onChanged: isEdit ? null : (v) {
                  selectedId = v;
                },
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: nameCtrl,
                labelText: "Device Name",
                prefixIcon: Icons.devices,
                hintText: "Enter Device Name",
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: ipCtrl,
                labelText: "IP Address",
                prefixIcon: Icons.lan,
                keyboardType: TextInputType.number,
                hintText: "Enter Device IP Address",
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: snCtrl,
                labelText: "Serial Number",
                prefixIcon: Icons.qr_code,
                hintText: "Enter Device Serial Number",
              ),
              const SizedBox(height: 30),
              Obx(
                () => CustomButton(
                  text: controller.isLoading.value
                      ? (isEdit ? "Updating..." : "Linking...")
                      : (isEdit ? "Save Changes" : "Link Machine"),
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (selectedId == null || nameCtrl.text.isEmpty) {
                            CustomSnackBar.error("Fill all fields");
                            return;
                          }
                          
                          final deviceData = {
                            "name": nameCtrl.text,
                            "ip": ipCtrl.text,
                            "sn": snCtrl.text,
                            "companyId": selectedId,
                          };

                          if (isEdit) {
                            await controller.updateMachine(existingDevice['id'], deviceData);
                          } else {
                            await controller.addMachine(deviceData);
                          }
                          
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

  void _showManageMachineSheet(
    BuildContext context,
    SuperAdminController controller,
    Map<String, dynamic> device,
  ) {
    final theme = Theme.of(context);
    final company = device['companies'] as Map<String, dynamic>?;
    
    Get.bottomSheet(
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
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              device['device_name'] ?? "Machine Details",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Linked to ${company?['company_name'] ?? 'Unknown'}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              title: const Text("Edit Machine Details"),
              onTap: () {
                Get.back();
                _showConnectMachineSheet(context, controller, existingDevice: device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text("Delete Machine", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Get.back();
                await controller.deleteMachine(device['id']);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
