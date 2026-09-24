import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/sync/sync_service.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';

class SyncManagerScreen extends StatefulWidget {
  const SyncManagerScreen({super.key});

  @override
  State<SyncManagerScreen> createState() => _SyncManagerScreenState();
}

class _SyncManagerScreenState extends State<SyncManagerScreen> {
  List<Map<String, dynamic>> _pendingList = [];
  bool _isLoading = true;
  String? _pingResult;
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRecords();
  }

  Future<void> _loadPendingRecords() async {
    final pending = await AppDatabase.instance.getPendingObservations();
    if (!mounted) return;
    setState(() {
      _pendingList = pending;
      _isLoading = false;
    });
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final response = await ApiClient.instance.getAnalyticsSummary();
      stopwatch.stop();
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _pingResult = 'Server Online • ${stopwatch.elapsedMilliseconds}ms latency';
        });
      }
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _pingResult = 'Server Unreachable (Offline Field Engine Active)';
      });
    } finally {
      if (mounted) setState(() => _isPinging = false);
    }
  }

  Future<void> _triggerSync() async {
    final success = await SyncService.instance.synchronize();
    await _loadPendingRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(SyncService.instance.lastSyncMessage ?? (success ? 'Sync completed' : 'Sync completed')),
        backgroundColor: success ? AppTheme.primaryGreen : AppTheme.warningAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SyncService.instance,
      builder: (context, _) {
        final isOffline = SyncService.instance.isOfflineMode;
        final isSyncing = SyncService.instance.isSyncing;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            title: Text(context.tr('sync_manager_title')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOffline ? AppTheme.warningAmber : AppTheme.primaryGreen,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isOffline ? AppTheme.warningAmber : AppTheme.primaryGreen)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                              color: isOffline ? AppTheme.warningAmber : AppTheme.primaryGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOffline
                                      ? context.tr('offline_mode_active')
                                      : context.tr('cloud_sync_ready'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_pendingList.length} ${context.tr('records_pending_upload')}',
                                  style: TextStyle(fontSize: 13, color: context.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isOffline,
                            activeThumbColor: AppTheme.warningAmber,
                            onChanged: (val) {
                              SyncService.instance.setOfflineMode(val);
                            },
                          ),
                        ],
                      ),
                      if (SyncService.instance.lastSyncMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Text(
                            SyncService.instance.lastSyncMessage!,
                            style: TextStyle(fontSize: 12, color: context.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ping Server Diagnostic Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('server_diagnostics'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: _isPinging ? null : _testServerConnection,
                            icon: _isPinging
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                                  )
                                : const Icon(Icons.network_check_rounded, size: 16, color: AppTheme.primaryGreen),
                            label: Text(
                              context.tr('ping_server'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                      if (_pingResult != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _pingResult!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _pingResult!.contains('Online')
                                ? AppTheme.primaryGreen
                                : AppTheme.warningAmber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Batch Sync Action Button
                ElevatedButton.icon(
                  onPressed: (isSyncing || _pendingList.isEmpty) ? null : _triggerSync,
                  icon: isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    isSyncing ? context.tr('synchronizing_queue') : context.tr('sync_now_btn'),
                  ),
                ),
                const SizedBox(height: 28),

                // Pending Queue
                Text(
                  context.tr('pending_records_queue'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                else if (_pendingList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.task_alt_rounded, size: 36, color: AppTheme.primaryGreen),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('no_pending_sync'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('all_synced_desc'),
                          style: TextStyle(fontSize: 12, color: context.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  ..._pendingList.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pending_actions_rounded, color: AppTheme.warningAmber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['crop']} — ${item['predicted_disease'] ?? "Observation"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${item['client_id'] ?? item['id']}',
                                  style: TextStyle(fontSize: 11, color: context.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.tr('pending_sync'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
