import 'package:get/get.dart';
import '/core/routes/app_routes.dart';
import '/presentation/screens/splash_screen.dart';
import '/presentation/screens/initial_choice_screen.dart';
import '/presentation/screens/local_dashboard_screen.dart';
import '/presentation/screens/login_screen.dart';
import '/presentation/screens/signup_complete_screen.dart';
import '/presentation/screens/dashboard_screen.dart';
import '/presentation/screens/account_form_screen.dart';
import '/presentation/screens/accounts_list_screen.dart';
import '/presentation/screens/shared_accounts_screen.dart';
import '/presentation/screens/create_shared_account_screen.dart';
import '/presentation/screens/search_users_screen.dart';
import '/presentation/screens/notifications_screen.dart';
import '/presentation/screens/sync_status_screen.dart';
import '/presentation/screens/reports_screen.dart';
import '/presentation/screens/settings_screen.dart';
import '/presentation/screens/edit_profile_screen.dart';

/// تعريف صفحات التطبيق للتنقل
class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.initial,
      page: () => const InitialChoiceScreen(),
    ),
    GetPage(
      name: AppRoutes.localDashboard,
      page: () => const LocalDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.signupComplete,
      page: () => const SignupCompleteScreen(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.accountForm,
      page: () => const AccountFormScreen(),
    ),
    GetPage(
      name: AppRoutes.accountsList,
      page: () => const AccountsListScreen(),
    ),
    GetPage(
      name: AppRoutes.sharedAccounts,
      page: () => const SharedAccountsScreen(),
    ),
    GetPage(
      name: AppRoutes.createSharedAccount,
      page: () => const CreateSharedAccountScreen(),
    ),
    GetPage(
      name: AppRoutes.searchUsers,
      page: () => const SearchUsersScreen(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),
    GetPage(
      name: AppRoutes.syncStatus,
      page: () => const SyncStatusScreen(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
    ),
  ];
}
