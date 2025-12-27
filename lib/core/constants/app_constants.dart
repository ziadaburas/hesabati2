class AppConstants {
  // App Info
  static const String appName = 'Hesabati';
  static const String appNameAr = 'حسابتي';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'hesabati.db';
  static const int databaseVersion = 1;
  
  // SharedPreferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserType = 'user_type';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // User Types
  static const String userTypeLocal = 'local';
  static const String userTypeAuthenticated = 'authenticated';
  
  // Account Types
  static const String accountTypeLoan = 'loan';
  static const String accountTypeDebt = 'debt';
  static const String accountTypeSavings = 'savings';
  static const String accountTypeShared = 'shared';
  
  // Account Categories
  static const String accountCategoryLocal = 'local';
  static const String accountCategoryShared = 'shared';
  
  // Account Status
  static const String accountStatusActive = 'active';
  static const String accountStatusPending = 'pending';
  static const String accountStatusClosed = 'closed';
  
  // Transaction Types
  static const String transactionTypeIn = 'in';
  static const String transactionTypeOut = 'out';
  
  // Transaction Status
  static const String transactionStatusPending = 'pending';
  static const String transactionStatusCompleted = 'completed';
  static const String transactionStatusRejected = 'rejected';
  static const String transactionStatusOffline = 'offline';
  static const String transactionStatusSynced = 'synced';
  
  // Request Status
  static const String requestStatusPending = 'pending';
  static const String requestStatusAccepted = 'accepted';
  static const String requestStatusRejected = 'rejected';
  
  // Notification Types
  static const String notificationTypeAccountRequest = 'account_request';
  static const String notificationTypeTransactionUpdate = 'transaction_update';
  static const String notificationTypeSyncStatus = 'sync_status';
  
  // Sync Status
  static const String syncStatusPending = 'pending';
  static const String syncStatusSynced = 'synced';
  static const String syncStatusFailed = 'failed';
  static const String syncStatusOffline = 'offline';
  
  // Audit Actions
  static const String auditActionCreate = 'create';
  static const String auditActionUpdate = 'update';
  static const String auditActionDelete = 'delete';
  
  // Currency
  static const String defaultCurrency = 'SAR';
  static const String currencySymbol = 'ر.س';
  
  // Date Formats
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  static const String dateFormatDatabase = 'yyyy-MM-dd HH:mm:ss';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;
  
  // Sync Settings
  static const int maxSyncRetries = 3;
  static const int syncRetryDelaySeconds = 5;
  
  // Language Codes
  static const String languageArabic = 'ar';
  static const String languageEnglish = 'en';
  
  // Firebase Collections
  static const String collectionUsers = 'users';
  static const String collectionAccounts = 'accounts';
  static const String collectionTransactions = 'transactions';
  static const String collectionRequests = 'account_requests';
  static const String collectionNotifications = 'notifications';
}
