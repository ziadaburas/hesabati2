import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/firebase_options.dart';
import '/core/themes/app_theme.dart';
import '/core/constants/app_constants.dart';
import '/core/localization/localization_service.dart';
import '/data/services/database_service.dart';
import '/data/services/connectivity_service.dart';
import '/data/services/sync_service.dart';
import '/data/services/notification_service.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Handling background message: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Database
  await DatabaseService.instance.database;
  
  // Initialize Controllers
  _initializeControllers();
  
  // Initialize Notification Service
  await _initializeNotificationService();
  
  runApp(const HesabatiApp());
}

/// Initialize Notification Service
Future<void> _initializeNotificationService() async {
  try {
    // Register NotificationService
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    
    // Register NotificationController
    Get.put(NotificationController(), permanent: true);
    
    if (kDebugMode) {
      debugPrint('Notification Service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing notification service: $e');
    }
  }
}

/// تهيئة جميع Controllers
void _initializeControllers() {
  // Auth Controller
  Get.put(AuthController(), permanent: true);
  
  // Settings Controller
  Get.put(SettingsController(), permanent: true);
  
  // Local Account Controller
  Get.put(LocalAccountController(), permanent: true);
  
  // Transaction Controller - مهم لإدارة العمليات
  Get.put(TransactionController(), permanent: true);
  
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
        localizationsDelegates:const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // اللغات المدعومة في التطبيق
        supportedLocales:const [
          Locale('ar', 'EG'), // اللغة العربية - مصر
          Locale('en', 'US'), // الإنجليزية - أمريكا
        ],
        // اللغة الحالية الواجهة
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
