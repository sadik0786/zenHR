import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this
import 'package:zen_hr/widgets/custom_snackbar.dart';

class SuperAdminController extends GetxController {
  final _supabase = Supabase.instance.client;
  
  RxList<Map<String, dynamic>> companies = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> machines = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> plans = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> roles = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    fetchMachines();
    fetchPlans();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    try {
      final List<dynamic> data = await _supabase.from('role_master').select().eq('is_active', true);
      roles.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching roles: $e");
    }
  }

  // --- COMPANY METHODS ---

  Future<void> fetchPlans() async {
    try {
      final List<dynamic> data = await _supabase.from('subscription_plans').select().order('id');
      plans.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching plans: $e");
    }
  }

  Future<void> fetchCompanies() async {
    try {
      isLoading.value = true;
      final List<dynamic> data = await _supabase
          .from('companies')
          .select('*, subscription_plans(plan_name)')
          .order('created_at', ascending: false);
      
      companies.assignAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      print("Error fetching companies: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCompany({
    required String companyName,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required int roleId,
    int planId = 1,
  }) async {
    try {
      isLoading.value = true;
      print("🚀 Starting Onboarding for: $adminEmail");

      // 1. Pre-Check: Does this email already exist in public.users?
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('email', adminEmail)
          .maybeSingle();
      
      if (existingUser != null) {
        throw "This email is already registered in ZenHR.";
      }

      // 2. Step 1: Create Company
      print("Step 1: Creating Company record...");
      final companyRes = await _supabase.from('companies').insert({
        'company_name': companyName,
        'admin_name': adminName,
        'admin_email': adminEmail,
        'admin_password': adminPassword,
        'plan_id': planId,
        'status': 'ACTIVE',
      }).select().single();
      
      final companyId = companyRes['id'];
      print("✅ Company created (ID: $companyId)");

      try {
        // 3. Step 2: Create Supabase Auth Account using MASTER KEY
        print("Step 2: Creating Auth credentials via Admin API...");
        final adminClient = SupabaseClient(
          dotenv.get('SUPABASE_URL'),
          dotenv.get('SUPABASE_SERVICE_ROLE_KEY'), // Use Master Key
        );

        final UserResponse adminRes = await adminClient.auth.admin.createUser(
          AdminUserAttributes(
            email: adminEmail.trim(),
            password: adminPassword.trim(),
            emailConfirm: true, // Automatically confirm email
          ),
        );

        if (adminRes.user == null) throw "Admin API failed to create User.";
        final String authId = adminRes.user!.id;
        print("✅ Auth Account Created via Admin API (UUID: $authId)");

        // 4. Step 3: Create User Profile
        print("Step 3: Creating Profile in public.users...");
        
        await _supabase.from('users').insert({
          'id': authId, 
          'name': adminName,
          'email': adminEmail,
          'company_id': companyId,
          'role_id': roleId, // Use the passed roleId
          'password': adminPassword,
          'is_active': true,
        });
        print("✅ User Profile Created.");

        CustomSnackBar.success("Company $companyName onboarded successfully!");
      } catch (e) {
        print("❌ FAILED AT STEP 2 or 3: $e");
        // CLEANUP: If it fails after company creation, delete the company
        await _supabase.from('companies').delete().eq('id', companyId);
        throw e.toString();
      }

      fetchCompanies();
    } catch (e) {
      print("❌ ONBOARDING ERROR: $e");
      CustomSnackBar.error(e.toString());
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

  Future<void> deleteCompany(int companyId) async {
    try {
      isLoading.value = true;
      await _supabase.from('companies').delete().eq('id', companyId);
      CustomSnackBar.success("Company deleted successfully!");
      fetchCompanies();
    } catch (e) {
      CustomSnackBar.error("Delete failed: $e");
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
