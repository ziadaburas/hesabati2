import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// خدمة الاتصال بالإنترنت
class ConnectivityService extends GetxService {
  static ConnectivityService get instance => Get.find<ConnectivityService>();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Properties
  final isConnected = false.obs;
  final connectionType = 'none'.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  /// تهيئة الخدمة
  Future<void> _init() async {
    await checkInternetConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// التحقق من الاتصال بالإنترنت
  Future<bool> checkInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return isConnected.value;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Check internet connection error: $e');
      }
      isConnected.value = false;
      connectionType.value = 'none';
      return false;
    }
  }

  /// معالجة تغيير الاتصال
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectionStatus(results);
  }

  /// تحديث حالة الاتصال
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      connectionType.value = 'none';
    } else {
      isConnected.value = true;
      
      if (results.contains(ConnectivityResult.wifi)) {
        connectionType.value = 'wifi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        connectionType.value = 'mobile';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        connectionType.value = 'ethernet';
      } else {
        connectionType.value = 'other';
      }
    }

    if (kDebugMode) {
      debugPrint('Connectivity changed: ${isConnected.value ? 'Connected' : 'Disconnected'} (${connectionType.value})');
    }
  }

  /// Stream لمتابعة تغييرات الاتصال
  Stream<bool> onConnectivityChanged() {
    return isConnected.stream;
  }

  /// الحصول على تسمية نوع الاتصال
  String get connectionTypeLabel {
    switch (connectionType.value) {
      case 'wifi':
        return 'واي فاي';
      case 'mobile':
        return 'بيانات الجوال';
      case 'ethernet':
        return 'إيثرنت';
      case 'none':
        return 'غير متصل';
      default:
        return connectionType.value;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
