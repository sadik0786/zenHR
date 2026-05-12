import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/core/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? role;
  final int? companyId;
  final String? avatarUrl;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.companyId,
    this.avatarUrl,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role_master']?['role_name'],
      companyId: map['company_id'],
      avatarUrl: map['profile_pic'],
      phone: map['phone'],
    );
  }
}

class UserController extends GetxController {
  final _supabase = Supabase.instance.client;
  final isLoading = true.obs;

  // Reactive User Data
  final currentUser = Rxn<UserModel>();
  final savedPin = RxnString();
  final Rxn<File> localAvatar = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadSavedPin();
  }

  Future<void> loadSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    savedPin.value = prefs.getString(AppConstants.appLockPinKey);
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.appLockPinKey, pin);
    savedPin.value = pin;
  }

  Future<void> checkAuthAndNavigate() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString(AppConstants.roleKey) ?? '';

    if (userRole == AppConstants.roleOwner) {
      Get.offAllNamed(Routes.superAdminDashboard);
    } else {
      Get.offAllNamed(Routes.dashboard);
    }
  }

  Future<void> loadUser() async {
    try {
      isLoading.value = true;
      final authUser = _supabase.auth.currentUser;
      
      if (authUser == null) {
        isLoading.value = false;
        return;
      }

      // Fetch from public.users table with role join
      final data = await _supabase
          .from('users')
          .select('*, role_master(role_name)')
          .eq('id', authUser.id)
          .maybeSingle();

      if (data == null && AppConstants.isAppOwner(authUser.email)) {
        // SELF-HEALING for App Owner
        final roleRes = await _supabase.from('role_master').select('id').eq('role_name', 'owner').single();
        await _supabase.from('users').insert({
          'id': authUser.id,
          'name': 'Ali Sadik',
          'email': authUser.email!,
          'role_id': roleRes['id'],
          'is_active': true,
        });
        // Re-fetch
        return loadUser(); 
      }

      if (data != null) {
        currentUser.value = UserModel.fromMap(data);
        
        // Ensure App Owner role is 'owner' regardless of DB role (safety check)
        String role = currentUser.value?.role ?? '';
        if (AppConstants.isAppOwner(authUser.email)) {
          role = AppConstants.roleOwner;
        }

        // Cache basic info for offline/checks
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, authUser.id);
        await prefs.setString(AppConstants.roleKey, role);
        await prefs.setString(AppConstants.nameKey, currentUser.value?.name ?? '');
        await prefs.setString(AppConstants.emailKey, authUser.email ?? '');
      }
    } catch (e) {
      print("Error loading user profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleLogout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentUser.value = null;
    localAvatar.value = null;
    Get.offAllNamed(Routes.login);
  }

  Future<void> updateMobile(String newMobile) async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('users').update({'phone': newMobile}).eq('id', userId);
      await loadUser(); // Refresh UI
      CustomSnackBar.success("Mobile number updated");
    } catch (e) {
      CustomSnackBar.error("Failed to update mobile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (picked == null) return;

      final file = File(picked.path);
      localAvatar.value = file; // Show local preview instantly

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final path = 'avatars/$userId.png';
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from('avatars')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      
      // Get Public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      
      // Update users table
      await _supabase.from('users').update({'profile_pic': publicUrl}).eq('id', userId);
      
      loadUser(); // Refresh UI
      CustomSnackBar.success("Profile photo updated");
    } catch (e) {
      CustomSnackBar.error("Error updating photo: $e");
    }
  }
}
