import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  double _riskScore = 0.68;
  String _riskLevel = "Elevated";
  Map<String, int> _diseaseDistribution = {
    'Early Blight': 12,
    'Late Blight': 5,
    'Septoria Spot': 8,
    'Leaf Mold': 4,
    'Healthy': 16,
  };
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final breakdown = await AppDatabase.instance.getDiseaseBreakdown();
      final obsCount = await AppDatabase.instance.getObservationCount();
      final predCount = await AppDatabase.instance.getPredictionCount();

      // Calculate dynamic risk score based on blight proportions
      int blights = (breakdown['Early Blight'] ?? 0) + (breakdown['Late Blight'] ?? 0);
      int total = breakdown.values.fold(0, (a, b) => a + b);

      double calculatedRisk = total > 0 ? (blights / total) : 0.65;
      String level = calculatedRisk > 0.6 ? 'High' : (calculatedRisk > 0.35 ? 'Moderate' : 'Low');

      try {
        final response = await ApiClient.instance.getAnalyticsSummary();
        if (response.statusCode == 200 && response.data['disease_distribution'] != null) {
          final serverData = Map<String, int>.from(response.data['disease_distribution']);
          breakdown.addAll(serverData);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _diseaseDistribution = breakdown;
        _riskScore = calculatedRisk.clamp(0.15, 0.95);
        _riskLevel = level;
        _totalRecords = obsCount + predCount;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportFieldData() async {
    final observations = await AppDatabase.instance.getAllObservations();
    final predictions = await AppDatabase.instance.getAllPredictions();

    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'platform': 'FieldAI Mobile Offline Engine',
      'observations_count': observations.length,
      'predictions_count': predictions.length,
      'observations': observations,
      'predictions': predictions,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Field Data Archive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archive includes ${observations.length} field observations and ${predictions.length} AI diagnoses from local SQLite storage.',
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                height: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.cardBorder),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Field data copied to clipboard'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Field Analytics & Risk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Field Records',
            onPressed: _exportFieldData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease Outbreak Risk Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.dangerRed.withValues(alpha: isDark ? 0.2 : 0.08),
                          context.surfaceCard,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
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
                              'Outbreak Spore Vulnerability',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _riskLevel.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(_riskScore * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Risk of spore proliferation in region',
                                style: TextStyle(color: context.textMuted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _riskScore,
                            backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dangerRed),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Driving Factors: High relative humidity (84%) combined with persistent 18-24°C microclimate favors Alternaria & Phytophthora spore dispersal.',
                          style: TextStyle(fontSize: 12, height: 1.4, color: context.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Regional Disease Distribution Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recorded Pathogen Prevalence',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '$_totalRecords Total Records',
                        style: TextStyle(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ..._diseaseDistribution.entries.map((e) {
                    final isHealthy = e.key == 'Healthy';
                    final color = isHealthy
                        ? AppTheme.successGreen
                        : (e.key.contains('Late') ? AppTheme.dangerRed : AppTheme.warningAmber);
                    final total = _diseaseDistribution.values.fold(0, (a, b) => a + b);
                    final pct = total > 0 ? (e.value / total) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                '${e.value} cases (${(pct * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  // Export CTA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.surfaceCard,
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                    onPressed: _exportFieldData,
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text('Export Field Observations & Diagnoses (JSON)'),
                  ),
                ],
              ),
            ),
    );
  }
}
