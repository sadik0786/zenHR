import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zen_hr/controllers/auth/login_controller.dart';
import 'package:zen_hr/widgets/custom_button.dart';
import 'package:zen_hr/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController loginController = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(
        () => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  // Logo & Welcome Section (Staggered Fade)
                  FadeTransition(
                    opacity: loginController.fadeAnimation,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset("assets/zenhr_logo.png", height: 120),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "ZenHR",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Your Complete HR Ecosystem",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Login Form Card (Static for better focus)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: loginController.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Login to your account",
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),
                          CustomTextField(
                            isEnabled: true,
                            controller: loginController.email.value,
                            labelText: "Email Address",
                            hintText: "admin@zenhr.com",
                            prefixIcon: Icons.email_outlined,
                            validator: loginController.validateEmail,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            isEnabled: true,
                            controller: loginController.password.value,
                            labelText: "Password",
                            hintText: "••••••••",
                            isObscure: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: loginController.validatePassword,
                          ),
                          const SizedBox(height: 40),
                          CustomButton(
                            text: loginController.loading.value ? "Authenticating..." : "Login",
                            onPressed: loginController.loading.value
                                ? null
                                : () => loginController.login(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            if (loginController.loading.value)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
