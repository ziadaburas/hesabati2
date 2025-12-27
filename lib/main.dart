import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import '/firebase_options.dart';
import '/core/themes/app_theme.dart';
import '/core/constants/app_constants.dart';
import '/core/localization/localization_service.dart';
import '/data/services/database_service.dart';
import '/data/services/connectivity_service.dart';
import '/data/services/sync_service.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Database
  await DatabaseService.instance.database;
  
  // Initialize Controllers
  _initializeControllers();
  
  runApp(const HesabatiApp());
}

/// تهيئة جميع Controllers
void _initializeControllers() {
  // Auth Controller
  Get.put(AuthController(), permanent: true);
  
  // Settings Controller
  Get.put(SettingsController(), permanent: true);
  
  // Local Account Controller
  Get.put(LocalAccountController(), permanent: true);
  
  // Connectivity Service
  Get.put(ConnectivityService(), permanent: true);
  
  // Sync Service
  Get.put(SyncService(), permanent: true);
}

class HesabatiApp extends StatelessWidget {
  const HesabatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    
    return Obx(() {
      final isArabic = settingsController.language.value == AppConstants.languageArabic;
      
      return GetMaterialApp(
        title: 'app_name'.tr,
        debugShowCheckedModeBanner: false,
        
        // Themes
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _getThemeMode(settingsController.themeMode.value),
        
        // Localization
        translations: LocalizationService(),
        locale: isArabic 
            ? const Locale('ar', 'EG') 
            : const Locale('en', 'US'),
        fallbackLocale: const Locale('ar', 'EG'),
        
        // RTL Support based on language
        builder: (context, child) {
          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          );
        },
        
        // Initial Screen
        home: const SplashScreen(),
      );
    });
  }
  
  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
