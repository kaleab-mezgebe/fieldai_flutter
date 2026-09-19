import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/theme/theme_service.dart';
import 'package:fieldai_flutter/core/localization/language_service.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/core/sync/sync_service.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/features/disease_analysis/presentation/screens/crop_analysis_screen.dart';
import 'package:fieldai_flutter/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:fieldai_flutter/features/observations/presentation/screens/observation_screen.dart';
import 'package:fieldai_flutter/features/history/presentation/screens/history_screen.dart';
import 'package:fieldai_flutter/features/analytics/presentation/screens/analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _analysisCount = 0;
  int _observationCount = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    SyncService.instance.refreshPendingCount();
  }

  Future<void> _loadDashboardData() async {
    final observations = await AppDatabase.instance.getAllObservations();
    final predictions = await AppDatabase.instance.getAllPredictions();

    List<Map<String, dynamic>> recent = [];

    for (var p in predictions) {
      recent.add({
        'title': '${p['crop']} — ${p['condition_name']}',
        'subtitle': 'Diagnosis • ${p['confidence']}% confidence',
        'date': p['created_at'] != null ? p['created_at'].toString().split('T').first : 'Recent',
        'isHealthy': (p['condition_name']?.toString() ?? '').toLowerCase().contains('healthy'),
        'isCritical': (p['severity']?.toString() ?? '').toLowerCase().contains('critical'),
      });
    }

    for (var o in observations) {
      recent.add({
        'title': '${o['crop']} — ${o['predicted_disease'] ?? 'Field Observation'}',
        'subtitle': o['notes'] != null && o['notes'].toString().isNotEmpty
            ? o['notes']
            : 'Field observation recorded',
        'date': o['created_at'] != null ? o['created_at'].toString().split('T').first : 'Recent',
        'isHealthy': (o['predicted_disease']?.toString() ?? '').toLowerCase().contains('healthy'),
        'isCritical': false,
      });
    }

    if (!mounted) return;
    setState(() {
      _observationCount = observations.length;
      _analysisCount = predictions.length;
      _recentActivities = recent.take(4).toList();
      _isLoadingData = false;
    });
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('select_language'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...LanguageService.instance.supportedLanguages.map((lang) {
                final isSelected = LanguageService.instance.languageCode == lang['code'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : context.cardBorder,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['nativeName']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppTheme.primaryGreen : context.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      lang['name']!,
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                        : null,
                    onTap: () {
                      LanguageService.instance.setLanguage(lang['code']!);
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOffline = SyncService.instance.isOfflineMode;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('system_controls'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Language selector in settings
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded, color: AppTheme.infoBlue),
                    ),
                    title: Text(
                      context.tr('language'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    subtitle: Text(
                      LanguageService.instance.supportedLanguages.firstWhere(
                        (l) => l['code'] == LanguageService.instance.languageCode,
                      )['nativeName']!,
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showLanguageSheet();
                    },
                  ),
                  const Divider(),

                  // Theme mode toggle
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                    title: Text(
                      context.tr('appearance_theme'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    subtitle: Text(
                      context.isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                    trailing: Switch.adaptive(
                      value: context.isDark,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        ThemeService.instance.toggleTheme();
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const Divider(),

                  // Offline mode toggle
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isOffline ? AppTheme.warningAmber : AppTheme.primaryGreen).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                        color: isOffline ? AppTheme.warningAmber : AppTheme.primaryGreen,
                      ),
                    ),
                    title: Text(
                      context.tr('offline_mode'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    subtitle: Text(
                      isOffline ? 'Offline Field Mode' : 'Connected Mode',
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                    trailing: Switch.adaptive(
                      value: isOffline,
                      activeThumbColor: AppTheme.warningAmber,
                      onChanged: (val) {
                        SyncService.instance.setOfflineMode(val);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const Divider(),

                  // Reset / Re-seed SQLite Data
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
                    ),
                    title: Text(
                      context.tr('reload_records'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    onTap: () async {
                      await AppDatabase.instance.clearAllData();
                      await SyncService.instance.refreshPendingCount();
                      await _loadDashboardData();
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample field records refreshed in SQLite'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AnimatedBuilder(
      animation: Listenable.merge([SyncService.instance, LanguageService.instance]),
      builder: (context, _) {
        final pendingSync = SyncService.instance.pendingCount;
        final isSyncing = SyncService.instance.isSyncing;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(context.tr('app_name')),
              ],
            ),
            actions: [
              // Language Selector Button
              IconButton(
                icon: const Icon(Icons.language_rounded, color: AppTheme.infoBlue),
                tooltip: 'Language / ቋንቋ / Afaan',
                onPressed: _showLanguageSheet,
              ),
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.warningAmber,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => ThemeService.instance.toggleTheme(),
              ),
              // Cloud Sync Button
              IconButton(
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppTheme.accentGreen, strokeWidth: 2),
                      )
                    : Icon(
                        Icons.sync_rounded,
                        color: pendingSync > 0 ? AppTheme.warningAmber : AppTheme.accentGreen,
                      ),
                tooltip: 'Sync Field Records',
                onPressed: isSyncing
                    ? null
                    : () async {
                        final success = await SyncService.instance.synchronize();
                        await _loadDashboardData();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(SyncService.instance.lastSyncMessage ?? 'Sync complete'),
                            backgroundColor: success ? AppTheme.successGreen : AppTheme.warningAmber,
                          ),
                        );
                      },
              ),
              // Analytics Shortcut
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analytics & Risk',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
              ),
              // Settings Modal
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'System Settings',
                onPressed: _showSettingsSheet,
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              await _loadDashboardData();
              await SyncService.instance.refreshPendingCount();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('good_day'),
                            style: TextStyle(fontSize: 14, color: context.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('field_worker'),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (pendingSync > 0 ? AppTheme.warningAmber : AppTheme.primaryGreen)
                              .withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pendingSync > 0 ? AppTheme.warningAmber : AppTheme.primaryGreen,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pendingSync > 0 ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                              size: 16,
                              color: pendingSync > 0 ? AppTheme.warningAmber : AppTheme.accentGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pendingSync > 0
                                  ? '$pendingSync ${context.tr('pending_sync')}'
                                  : context.tr('synced'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: pendingSync > 0 ? AppTheme.warningAmber : AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Today's Activity Stats Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('field_summary'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            if (_isLoadingData)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(context.tr('diagnoses'), '$_analysisCount', AppTheme.primaryGreen),
                            Container(width: 1, height: 36, color: context.cardBorder),
                            _buildStatColumn(context.tr('observations'), '$_observationCount', AppTheme.accentGreen),
                            Container(width: 1, height: 36, color: context.cardBorder),
                            _buildStatColumn(context.tr('pending_sync'), '$pendingSync', AppTheme.warningAmber),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Action Cards
                  Text(
                    context.tr('tools_diagnostics'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildActionButton(
                    context,
                    title: context.tr('analyze_crop'),
                    subtitle: context.tr('analyze_crop_sub'),
                    icon: Icons.camera_alt_rounded,
                    color: AppTheme.primaryGreen,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CropAnalysisScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildActionButton(
                    context,
                    title: context.tr('ask_ai'),
                    subtitle: context.tr('ask_ai_sub'),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppTheme.infoBlue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionButton(
                    context,
                    title: context.tr('record_obs'),
                    subtitle: context.tr('record_obs_sub'),
                    icon: Icons.edit_note_rounded,
                    color: AppTheme.accentPurple,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ObservationScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),

                  const SizedBox(height: 28),
                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('recent_activity'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                          _loadDashboardData();
                        },
                        child: Text(
                          context.tr('view_all'),
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_recentActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          context.tr('no_activity'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._recentActivities.map((act) {
                      Color dotColor = act['isHealthy'] == true
                          ? AppTheme.successGreen
                          : (act['isCritical'] == true ? AppTheme.dangerRed : AppTheme.warningAmber);

                      return _buildRecentCard(
                        context,
                        act['title'],
                        act['subtitle'],
                        act['date'],
                        dotColor,
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(
    BuildContext context,
    String title,
    String subtitle,
    String date,
    Color indicatorColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(date, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ],
      ),
    );
  }
}
