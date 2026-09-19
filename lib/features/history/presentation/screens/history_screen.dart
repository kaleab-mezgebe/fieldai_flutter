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
  String _filter = 'all'; // all, diagnoses, observations

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
        'id': p['prediction_id'] ?? '${p['id']}',
        'title': '${p['crop']} — ${p['condition_name']}',
        'subtitle': 'Confidence: ${p['confidence']}% • ${p['status'] ?? 'Diagnosed'}',
        'details': p['explanation'] ?? '',
        'actions': p['recommended_actions'] ?? '',
        'date': p['created_at'] != null ? p['created_at'].toString().split('T').first : 'Recent',
        'isObservation': false,
        'sync_status': p['sync_status'] ?? 'synced',
        'crop': p['crop'],
      });
    }

    for (var o in observations) {
      combined.add({
        'id': o['client_id'] ?? '${o['id']}',
        'title': '${o['crop']} — ${o['predicted_disease'] ?? 'Field Observation'}',
        'subtitle': 'Symptoms: ${o['symptoms'] ?? 'No symptoms noted'}',
        'details': 'Weather: ${o['weather_condition'] ?? 'N/A'}\nNotes: ${o['notes'] ?? 'None'}',
        'actions': 'GPS: ${o['latitude'] ?? ''}, ${o['longitude'] ?? ''}',
        'date': o['created_at'] != null ? o['created_at'].toString().split('T').first : 'Recent',
        'isObservation': true,
        'sync_status': o['sync_status'] ?? 'pending',
        'crop': o['crop'],
      });
    }

    if (!mounted) return;
    setState(() {
      _records = combined;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_filter == 'diagnoses') {
      return _records.where((r) => r['isObservation'] == false).toList();
    } else if (_filter == 'observations') {
      return _records.where((r) => r['isObservation'] == true).toList();
    }
    return _records;
  }

  void _showItemDetails(Map<String, dynamic> item) {
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
                  Expanded(
                    child: Text(
                      item['title'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item['sync_status'] == 'pending'
                          ? AppTheme.warningAmber.withValues(alpha: 0.15)
                          : AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['sync_status'] == 'pending' ? 'Pending' : 'Synced',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item['sync_status'] == 'pending' ? AppTheme.warningAmber : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Recorded Date: ${item['date']}',
                style: TextStyle(fontSize: 12, color: context.textMuted),
              ),
              const SizedBox(height: 12),
              Divider(color: context.cardBorder),
              const SizedBox(height: 8),
              Text(
                'Details & Field Observations:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                item['details'] != null && item['details'].toString().isNotEmpty
                    ? item['details']
                    : item['subtitle'],
                style: TextStyle(fontSize: 13, height: 1.4, color: context.textMuted),
              ),
              if (item['actions'] != null && item['actions'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item['isObservation'] == true ? 'Location:' : 'Interventions:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item['actions'],
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.primaryGreen),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close Details'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('My Diagnoses & Observations'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: context.surfaceCard,
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${_records.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('diagnoses', 'Diagnoses (${_records.where((r) => !r['isObservation']).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('observations', 'Observations (${_records.where((r) => r['isObservation']).length})'),
              ],
            ),
          ),
          const Divider(color: AppTheme.primaryGreen, height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No records found in this category.',
                          style: TextStyle(color: context.textMuted, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isPending = item['sync_status'] == 'pending';

                          return InkWell(
                            onTap: () => _showItemDetails(item),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.surfaceCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (item['isObservation'] == true
                                              ? AppTheme.accentPurple
                                              : AppTheme.primaryGreen)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item['isObservation'] == true
                                          ? Icons.edit_note_rounded
                                          : Icons.biotech_rounded,
                                      color: item['isObservation'] == true
                                          ? AppTheme.accentPurple
                                          : AppTheme.primaryGreen,
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
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item['subtitle'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: context.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item['date'],
                                        style: TextStyle(fontSize: 11, color: context.textMuted),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPending
                                              ? AppTheme.warningAmber.withValues(alpha: 0.15)
                                              : AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPending ? 'Pending' : 'Synced',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isPending ? AppTheme.warningAmber : AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : context.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: context.bgColor,
      side: BorderSide(color: isSelected ? AppTheme.primaryGreen : context.cardBorder),
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
    );
  }
}
