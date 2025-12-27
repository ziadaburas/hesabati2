import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '/core/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE,
        username TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        profile_picture_url TEXT,
        user_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // جدول الحسابات
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT UNIQUE NOT NULL,
        user_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        account_category TEXT NOT NULL,
        balance REAL DEFAULT 0,
        currency TEXT DEFAULT 'SAR',
        other_party_id TEXT,
        other_party_name TEXT,
        account_status TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'offline',
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // جدول العمليات
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE NOT NULL,
        account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_type TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        transaction_date TEXT NOT NULL,
        recorded_by_user TEXT NOT NULL,
        approved_by_user TEXT,
        status TEXT NOT NULL,
        transaction_status TEXT DEFAULT 'offline',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
      )
    ''');

    // جدول التدقيق
    await db.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        record_details TEXT,
        timestamp TEXT NOT NULL,
        device_info TEXT
      )
    ''');

    // جدول طلبات فتح الحسابات
    await db.execute('''
      CREATE TABLE account_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT UNIQUE NOT NULL,
        from_user_id TEXT NOT NULL,
        to_user_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        request_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        responded_at TEXT,
        response_notes TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // جدول الإشعارات
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notification_id TEXT UNIQUE NOT NULL,
        user_id TEXT NOT NULL,
        notification_type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        related_account_id TEXT,
        related_request_id TEXT,
        is_read INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        read_at TEXT
      )
    ''');

    // جدول حالة المزامنة
    await db.execute('''
      CREATE TABLE sync_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_sync_attempt TEXT,
        sync_error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Indexes for Performance
    await db.execute('CREATE INDEX idx_accounts_user_id ON accounts(user_id)');
    await db.execute('CREATE INDEX idx_transactions_account_id ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
    await db.execute('CREATE INDEX idx_audit_log_user_id ON audit_log(user_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ============ CRUD Operations ============

  // Generic Insert
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Generic Query
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  // Generic Update
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Generic Delete
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Get All from Table
  Future<List<Map<String, dynamic>>> getAllFromTable(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Clear All Data (للاختبار فقط)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('accounts');
    await db.delete('transactions');
    await db.delete('audit_log');
    await db.delete('account_requests');
    await db.delete('notifications');
    await db.delete('sync_status');
  }
}
