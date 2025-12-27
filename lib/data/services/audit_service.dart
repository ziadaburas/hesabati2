import '/data/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// خدمة التدقيق وتسجيل العمليات
class AuditService {
  static final AuditService instance = AuditService._init();
  final DatabaseService _databaseService = DatabaseService.instance;

  AuditService._init();

  /// تسجيل عملية
  Future<void> logAction({
    required String action,
    required String tableName,
    required int recordId,
    required String userId,
    String? recordDetails,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      await _databaseService.insert('audit_log', {
        'user_id': userId,
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'record_details': recordDetails,
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': deviceInfo,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Log action error: $e');
      }
    }
  }

  /// تسجيل عملية تحديث
  Future<void> logUpdate({
    required String userId,
    required String tableName,
    required int recordId,
    required String oldData,
    required String newData,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      await _databaseService.insert('audit_log', {
        'user_id': userId,
        'action': 'update',
        'table_name': tableName,
        'record_id': recordId,
        'record_details': 'Old: $oldData, New: $newData',
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': deviceInfo,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Log update error: $e');
      }
    }
  }

  /// الحصول على سجل التدقيق لمستخدم
  Future<List<Map<String, dynamic>>> getAuditLog(String userId) async {
    try {
      return await _databaseService.query(
        'audit_log',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get audit log error: $e');
      }
      return [];
    }
  }

  /// الحصول على سجل التدقيق حسب الجدول
  Future<List<Map<String, dynamic>>> getAuditLogByTable(String tableName) async {
    try {
      return await _databaseService.query(
        'audit_log',
        where: 'table_name = ?',
        whereArgs: [tableName],
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get audit log by table error: $e');
      }
      return [];
    }
  }

  /// مسح السجلات القديمة
  Future<void> clearOldLogs(int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await _databaseService.delete(
        'audit_log',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Clear old logs error: $e');
      }
    }
  }

  /// الحصول على معلومات الجهاز
  Future<String> _getDeviceInfo() async {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// الحصول على عدد السجلات
  Future<int> getLogCount(String userId) async {
    try {
      final results = await _databaseService.query(
        'audit_log',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return results.length;
    } catch (e) {
      return 0;
    }
  }
}
