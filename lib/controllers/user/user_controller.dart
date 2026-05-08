import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_hr/core/routes.dart';
import 'package:zen_hr/services/auth_api_service.dart';
import 'package:zen_hr/services/user_api_service.dart';
import 'package:zen_hr/widgets/custom_snackbar.dart';
import 'package:zen_hr/core/app_constants.dart';

class UserController extends GetxController {
  final isLoading = true.obs;

  // User Data
  final userID = 0.obs;
  final userName = ''.obs;
  final email = ''.obs;
  final mobile = ''.obs;
  final role = ''.obs;
  final avatarUrl = RxnString();
  final localAvatar = Rxn<File>();

  // App Lock
  final savedPin = RxnString();

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userRole = prefs.getString(AppConstants.roleKey)?.toLowerCase() ?? '';
    final uId = prefs.getInt(AppConstants.userIdKey);

    if (token == null || token.isEmpty || uId == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    switch (userRole) {
      case AppConstants.roleCeo:
      case AppConstants.roleHr:
      case AppConstants.roleManager:
      case AppConstants.roleAdmin:
      case AppConstants.roleEmployee:
        Get.offAllNamed(Routes.dashboard);
        break;
      default:
        Get.offAllNamed(Routes.login);
    }
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? userFromServer;
    try {
      // Fetch latest user from server using UserApiService
      userFromServer = await UserApiService.getUserProfile();

      if (userFromServer != null) {
        // Update local cache - handle flexible casing from backend
        final uId = userFromServer["id"] ?? userFromServer["ID"];
        final uName = userFromServer["name"] ?? userFromServer["Name"] ?? "";
        final uEmail = userFromServer["email"] ?? userFromServer["Email"] ?? "";
        final uMobile = userFromServer["mobile"] ?? userFromServer["Mobile"] ?? "";
        final uRole = userFromServer["roleName"] ?? userFromServer["RoleName"] ?? "";

        await prefs.setInt(AppConstants.userIdKey, uId);
        await prefs.setString(AppConstants.nameKey, uName);
        await prefs.setString(AppConstants.emailKey, uEmail);
        await prefs.setString(AppConstants.mobileKey, uMobile);
        await prefs.setString(AppConstants.roleKey, uRole);

        if (userFromServer["ProfileImage"] != null) {
          await prefs.setString("avatarUrl", userFromServer["ProfileImage"]);
        } else if (userFromServer["profileImage"] != null) {
          await prefs.setString("avatarUrl", userFromServer["profileImage"]);
        }
      }
    } catch (e) {
      CustomSnackBar.warning("Offline - Showing cached data");
    }

    // Set observables from cache (or updated cache)
    userID.value =
        (userFromServer?["id"] ?? userFromServer?["ID"]) ??
        prefs.getInt(AppConstants.userIdKey) ??
        0;
    userName.value =
        (userFromServer?["name"] ?? userFromServer?["Name"]) ??
        prefs.getString(AppConstants.nameKey) ??
        "";
    email.value =
        (userFromServer?["email"] ?? userFromServer?["Email"]) ??
        prefs.getString(AppConstants.emailKey) ??
        "";
    mobile.value =
        (userFromServer?["mobile"] ?? userFromServer?["Mobile"]) ??
        prefs.getString(AppConstants.mobileKey) ??
        "";
    role.value =
        (userFromServer?["roleName"] ?? userFromServer?["RoleName"]) ??
        prefs.getString(AppConstants.roleKey) ??
        "";

    final localPath = prefs.getString("localAvatarPath");
    if (localPath != null && localPath.isNotEmpty) {
      localAvatar.value = File(localPath);
      avatarUrl.value = null;
    } else {
      final avatarPath =
          userFromServer?["ProfileImage"] ??
          userFromServer?["profileImage"] ??
          prefs.getString("avatarUrl");
      if (avatarPath != null && avatarPath.isNotEmpty) {
        avatarUrl.value = avatarPath;
        localAvatar.value = null;
      }
    }

    isLoading.value = false;
  }

  Future<void> logOut() async {
    await AuthApiService.clearToken();
    clearUserData(); // Reset observables instead of deleting the controller
    Get.offAllNamed(Routes.login);
  }

  void clearUserData() {
    userID.value = 0;
    userName.value = '';
    email.value = '';
    mobile.value = '';
    role.value = '';
    avatarUrl.value = null;
    localAvatar.value = null;
    savedPin.value = null;
  }

  Future<void> uploadPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      localAvatar.value = file; // Show immediately

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("localAvatarPath", file.path);
      CustomSnackBar.success("Profile photo updated");

      // Upload to server
      final url = await UserApiService.uploadAvatar(file);
      if (url != null) {
        avatarUrl.value = url;
        await prefs.setString("avatarUrl", url);
      }
    } catch (e) {
      CustomSnackBar.error("Error updating photo: $e");
    }
  }

  Future<void> updateMobile(String newMobile) async {
    try {
      final success = await UserApiService.updateMobile(newMobile);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.mobileKey, newMobile);
        mobile.value = newMobile;
        CustomSnackBar.success("Mobile updated successfully");
      } else {
        CustomSnackBar.error("Failed to update mobile");
      }
    } catch (e) {
      CustomSnackBar.error("Error: $e");
    }
  }
}
