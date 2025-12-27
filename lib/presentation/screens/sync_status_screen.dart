import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/connectivity_service.dart';
import '/data/services/sync_service.dart';

/// شاشة حالة المزامنة
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  final SyncService _syncService = Get.find<SyncService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة المزامنة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حالة الاتصال
            _buildConnectionStatusCard(),
            const SizedBox(height: 16),

            // حالة المزامنة
            _buildSyncStatusCard(),
            const SizedBox(height: 16),

            // البيانات المعلقة
            _buildPendingDataCard(),
            const SizedBox(height: 16),

            // آخر مزامنة
            _buildLastSyncCard(),
            const SizedBox(height: 24),

            // زر المزامنة
            _buildSyncButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Obx(() {
      final isConnected = _connectivityService.isConnected.value;
      final connectionType = _connectivityService.connectionTypeLabel;
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الاتصال',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected ? 'متصل' : 'غير متصل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isConnected ? AppColors.success : AppColors.error,
                      ),
                    ),
                    if (isConnected)
                      Text(
                        connectionType,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSyncStatusCard() {
    return Obx(() {
      final status = _syncService.syncStatus.value;
      final progress = _syncService.syncProgress.value;
      
      Color statusColor;
      IconData statusIcon;
      String statusText;
      
      switch (status) {
        case 'syncing':
          statusColor = AppColors.info;
          statusIcon = Icons.sync;
          statusText = 'جاري المزامنة...';
          break;
        case 'success':
          statusColor = AppColors.success;
          statusIcon = Icons.check_circle;
          statusText = 'تمت المزامنة بنجاح';
          break;
        case 'error':
          statusColor = AppColors.error;
          statusIcon = Icons.error;
          statusText = 'فشلت المزامنة';
          break;
        default:
          statusColor = AppColors.grey;
          statusIcon = Icons.cloud_queue;
          statusText = 'في انتظار المزامنة';
      }
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: status == 'syncing'
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حالة المزامنة',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (status == 'syncing') ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              if (status == 'error' && _syncService.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _syncService.errorMessage.value,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPendingDataCard() {
    return Obx(() {
      final pendingCount = _syncService.pendingCount.value;
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (pendingCount > 0 ? AppColors.warning : AppColors.success)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pendingCount > 0 ? Icons.pending : Icons.cloud_done,
                  color: pendingCount > 0 ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'البيانات المعلقة',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingCount > 0
                          ? '$pendingCount عنصر في انتظار المزامنة'
                          : 'جميع البيانات متزامنة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: pendingCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLastSyncCard() {
    return Obx(() {
      final lastSync = _syncService.lastSyncTime.value;
      final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
      
      String lastSyncText;
      if (lastSync.isEmpty) {
        lastSyncText = 'لم تتم المزامنة بعد';
      } else {
        try {
          final date = DateTime.parse(lastSync);
          lastSyncText = dateFormat.format(date);
        } catch (e) {
          lastSyncText = 'غير معروف';
        }
      }
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر مزامنة',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastSyncText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSyncButton() {
    return Obx(() {
      final isConnected = _connectivityService.isConnected.value;
      final isSyncing = _syncService.isSyncing.value;
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (isConnected && !isSyncing) ? _startSync : null,
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.sync),
          label: Text(isSyncing ? 'جاري المزامنة...' : 'مزامنة الآن'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    });
  }

  void _startSync() async {
    final success = await _syncService.syncAllData();
    
    Get.snackbar(
      success ? 'نجح' : 'خطأ',
      success ? 'تمت المزامنة بنجاح' : 'حدث خطأ أثناء المزامنة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? AppColors.success : AppColors.error,
      colorText: Colors.white,
    );
  }
}
