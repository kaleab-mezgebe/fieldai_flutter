import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
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
  int _analysisCount = 12;
  int _observationCount = 8;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    SyncService.instance.refreshPendingCount();
  }

  Future<void> _loadDashboardData() async {
    final observations = await AppDatabase.instance.getAllObservations();
    if (!mounted) return;
    setState(() {
      _observationCount = observations.isNotEmpty ? observations.length : 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SyncService.instance,
      builder: (context, _) {
        final pendingSync = SyncService.instance.pendingCount;
        final isSyncing = SyncService.instance.isSyncing;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            title: const Text('FieldAI'),
            actions: [
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
                onPressed: isSyncing
                    ? null
                    : () async {
                        final success = await SyncService.instance.synchronize();
                        await _loadDashboardData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(SyncService.instance.lastSyncMessage ?? 'Sync complete'),
                              backgroundColor: success ? AppTheme.successGreen : AppTheme.warningAmber,
                            ),
                          );
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analytics & Risk',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                      children: const [
                        Text(
                          'Good morning!',
                          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Field Worker #104',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pendingSync > 0
                            ? AppTheme.warningAmber.withOpacity(0.15)
                            : AppTheme.primaryGreen.withOpacity(0.15),
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
                            pendingSync > 0 ? '$pendingSync Pending Sync' : 'Synced',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pendingSync > 0 ? AppTheme.warningAmber : AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Activity Stats Grid
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Activity",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Analyses', '$_analysisCount', AppTheme.primaryGreen),
                          Container(width: 1, height: 36, color: AppTheme.cardBorder),
                          _buildStatColumn('Observations', '$_observationCount', AppTheme.accentGreen),
                          Container(width: 1, height: 36, color: AppTheme.cardBorder),
                          _buildStatColumn('Pending Sync', '$pendingSync', AppTheme.warningAmber),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Action Cards
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                ),
                const SizedBox(height: 14),

                _buildActionButton(
                  context,
                  title: 'Analyze Crop',
                  subtitle: 'Identify leaf diseases & receive AI diagnosis',
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CropAnalysisScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  title: 'Ask FieldAI',
                  subtitle: 'Evidence-based guidance from extension manuals (RAG)',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  title: 'Record Observation',
                  subtitle: 'Save field symptoms & GPS coordinates offline',
                  icon: Icons.edit_note_rounded,
                  color: const Color(0xFF8B5CF6),
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
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                      child: const Text('View all', style: TextStyle(color: AppTheme.accentGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildRecentCard('Tomato — Early Blight', 'Identified • 87% confidence', '12 Sept', AppTheme.warningAmber),
                _buildRecentCard('Tomato — Healthy', 'Optimal foliage • 96% confidence', '10 Sept', AppTheme.successGreen),
                _buildRecentCard('Tomato — Leaf Mold', 'Needs ventilation • 82% confidence', '08 Sept', AppTheme.warningAmber),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textLight)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(String title, String subtitle, String date, Color indicatorColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
