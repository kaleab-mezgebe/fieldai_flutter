import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/features/treatment/presentation/screens/treatment_plan_screen.dart';

class TreatmentListScreen extends StatefulWidget {
  const TreatmentListScreen({super.key});

  @override
  State<TreatmentListScreen> createState() => _TreatmentListScreenState();
}

class _TreatmentListScreenState extends State<TreatmentListScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await AppDatabase.instance.getAllTreatmentPlans();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  Future<void> _deletePlan(String planId) async {
    await AppDatabase.instance.deleteTreatmentPlan(planId);
    _loadPlans();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('plan_deleted')),
        backgroundColor: AppTheme.dangerRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(context.tr('treatment_plans_header')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Treatment Plan',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TreatmentPlanScreen(
                    crop: 'Tomato',
                    diseaseName: 'Early Blight (Alternaria solani)',
                  ),
                ),
              );
              _loadPlans();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _plans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.medical_services_outlined, size: 36, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('no_treatment_plans'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('no_treatment_plans_sub'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: context.textMuted),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TreatmentPlanScreen(
                                  crop: 'Tomato',
                                  diseaseName: 'Early Blight (Alternaria solani)',
                                ),
                              ),
                            );
                            _loadPlans();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.tr('create_treatment_plan')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final item = _plans[index];
                    final completedList = (item['completed_phases']?.toString() ?? '')
                        .split(',')
                        .where((s) => s.isNotEmpty)
                        .toList();
                    final isCritical = (item['severity']?.toString() ?? '').toLowerCase().contains('critical');
                    final date = item['created_at'] != null ? item['created_at'].toString().split('T').first : 'Recent';

                    return Dismissible(
                      key: Key(item['plan_id'] ?? '$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => _deletePlan(item['plan_id']),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TreatmentPlanScreen(
                                crop: item['crop'] ?? 'Tomato',
                                diseaseName: item['disease_name'] ?? 'Early Blight',
                                existingPlanId: item['plan_id'],
                              ),
                            ),
                          );
                          _loadPlans();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item['crop']} • ${item['field_name'] ?? "Plot"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isCritical ? AppTheme.dangerRed : AppTheme.warningAmber)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['severity'] ?? 'Moderate',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCritical ? AppTheme.dangerRed : AppTheme.warningAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['disease_name'] ?? 'Pathogen Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['dosage_summary'] ?? 'Drip irrigation & protectant schedule',
                                style: TextStyle(fontSize: 12, color: context.textMuted),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${completedList.length} milestones complete • $date',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryGreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
