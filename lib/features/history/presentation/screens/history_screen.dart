import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final predictions = await AppDatabase.instance.getAllPredictions();
    final observations = await AppDatabase.instance.getAllObservations();

    List<Map<String, dynamic>> combined = [];
    for (var p in predictions) {
      combined.add({
        'title': '${p['crop']} — ${p['condition_name']}',
        'subtitle': 'Confidence: ${p['confidence']}% • ${p['status'] ?? 'Analyzed'}',
        'date': p['created_at'] != null ? p['created_at'].toString().split('T').first : 'Recent',
        'isObservation': false,
        'sync_status': p['sync_status'] ?? 'synced',
      });
    }

    for (var o in observations) {
      combined.add({
        'title': '${o['crop']} — ${o['predicted_disease'] ?? 'Field Record'}',
        'subtitle': 'Symptoms: ${o['symptoms'] ?? 'No symptoms noted'}',
        'date': o['created_at'] != null ? o['created_at'].toString().split('T').first : 'Recent',
        'isObservation': true,
        'sync_status': o['sync_status'] ?? 'pending',
      });
    }

    if (combined.isEmpty) {
      combined = [
        {
          'title': 'Tomato — Early Blight',
          'subtitle': 'Confidence: 87% • Needs attention',
          'date': '12 Sept',
          'isObservation': false,
          'sync_status': 'synced',
        },
        {
          'title': 'Tomato — Healthy',
          'subtitle': 'Confidence: 96% • Optimal condition',
          'date': '10 Sept',
          'isObservation': false,
          'sync_status': 'synced',
        },
        {
          'title': 'Tomato — Leaf Mold',
          'subtitle': 'Confidence: 82% • Needs treatment',
          'date': '08 Sept',
          'isObservation': false,
          'sync_status': 'synced',
        },
      ];
    }

    if (!mounted) return;
    setState(() {
      _records = combined;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('My Analyses & Observations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final item = _records[index];
                final isPending = item['sync_status'] == 'pending';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (item['isObservation'] == true
                                  ? const Color(0xFF8B5CF6)
                                  : AppTheme.primaryGreen)
                              .withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['isObservation'] == true
                              ? Icons.edit_note_rounded
                              : Icons.biotech_rounded,
                          color: item['isObservation'] == true
                              ? const Color(0xFF8B5CF6)
                              : AppTheme.accentGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['subtitle'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['date'],
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? AppTheme.warningAmber.withOpacity(0.15)
                                  : AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPending ? 'Pending' : 'Synced',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPending ? AppTheme.warningAmber : AppTheme.accentGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
