import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/initial_choice_screen.dart';
import '/presentation/screens/local_dashboard_screen.dart';
import '/presentation/screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final authController = Get.find<AuthController>();
    await authController.restoreSession();
    
    if (authController.isLoggedIn.value) {
      if (authController.isAuthenticatedMode) {
        Get.off(() => const DashboardScreen());
      } else {
        Get.off(() => const LocalDashboardScreen());
      }
    } else {
      Get.off(() => const InitialChoiceScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            // App Name (Arabic)
            Text(
              'app_name'.tr,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // App Subtitle
            Text(
              'app_subtitle'.tr,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            
            // Loading Text
            Text(
              'loading'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
