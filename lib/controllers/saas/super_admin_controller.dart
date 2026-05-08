import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';

class SuperAdminController extends GetxController {
  final _supabase = Supabase.instance.client;
  
  RxList<Map<String, dynamic>> companies = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> machines = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    fetchMachines();
  }

  // --- COMPANY METHODS ---

  Future<void> fetchCompanies() async {
    try {
      isLoading.value = true;
      final List<dynamic> data = await _supabase
          .from('companies')
          .select()
          .order('created_at', ascending: false);
      
      companies.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      CustomSnackBar.error("Error fetching companies: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCompany({
    required String companyName,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    int planId = 1,
  }) async {
    try {
      isLoading.value = true;
      await _supabase.from('companies').insert({
        'company_name': companyName,
        'admin_name': adminName,
        'admin_email': adminEmail,
        'plan_id': planId,
        'status': 'ACTIVE',
      });
      
      CustomSnackBar.success("Company $companyName created successfully!");
      fetchCompanies();
    } catch (e) {
      CustomSnackBar.error("Failed to create company: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCompany({
    required int companyId,
    required String companyName,
    required String status,
    required int planId,
  }) async {
    try {
      isLoading.value = true;
      await _supabase.from('companies').update({
        'company_name': companyName,
        'status': status,
        'plan_id': planId,
      }).eq('id', companyId);
      
      CustomSnackBar.success("Company updated successfully!");
      fetchCompanies();
    } catch (e) {
      CustomSnackBar.error("Update failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- MACHINE METHODS ---

  Future<void> fetchMachines() async {
    try {
      final List<dynamic> data = await _supabase
          .from('biometric_machines')
          .select('*, companies(company_name)')
          .order('last_sync', ascending: false);
      
      machines.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching machines: $e");
    }
  }

  Future<void> addMachine(Map<String, dynamic> device) async {
    try {
      isLoading.value = true;
      await _supabase.from('biometric_machines').insert({
        'device_name': device['name'],
        'ip_address': device['ip'],
        'serial_number': device['sn'],
        'company_id': device['companyId'],
        'status': 'Online',
      });
      
      CustomSnackBar.success("Machine ${device['name']} linked!");
      fetchMachines();
    } catch (e) {
      CustomSnackBar.error("Failed to link machine: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMachine(int id, Map<String, dynamic> updatedData) async {
    try {
      isLoading.value = true;
      await _supabase.from('biometric_machines').update({
        'device_name': updatedData['name'],
        'ip_address': updatedData['ip'],
        'serial_number': updatedData['sn'],
      }).eq('id', id);
      
      CustomSnackBar.success("Machine updated!");
      fetchMachines();
    } catch (e) {
      CustomSnackBar.error("Update failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      isLoading.value = true;
      await _supabase.from('biometric_machines').delete().eq('id', id);
      CustomSnackBar.success("Machine removed!");
      fetchMachines();
    } catch (e) {
      CustomSnackBar.error("Delete failed: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
