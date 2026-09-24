import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/core/treatment/treatment_plan_service.dart';

class TreatmentPlanScreen extends StatefulWidget {
  final String crop;
  final String diseaseName;
  final String? existingPlanId;

  const TreatmentPlanScreen({
    super.key,
    required this.crop,
    required this.diseaseName,
    this.existingPlanId,
  });

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  late TreatmentTemplate _template;
  double _fieldSizeM2 = 500.0;
  final TextEditingController _fieldNameController = TextEditingController(text: 'Plot #1 - Main Field');
  final Set<String> _completedPhases = {};
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _template = TreatmentPlanService.instance.getTreatmentTemplate(widget.crop, widget.diseaseName);
  }

  void _togglePhase(String phaseId) {
    setState(() {
      if (_completedPhases.contains(phaseId)) {
        _completedPhases.remove(phaseId);
      } else {
        _completedPhases.add(phaseId);
      }
    });
  }

  Future<void> _saveTreatmentPlan() async {
    setState(() => _isSaving = true);
    final planId = widget.existingPlanId ?? 'plan_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 6)}';
    final dosage = TreatmentPlanService.instance.calculateDosage(areaM2: _fieldSizeM2);

    final planData = {
      'plan_id': planId,
      'crop': _template.crop,
      'disease_name': _template.diseaseName,
      'severity': _template.severity,
      'field_name': _fieldNameController.text.trim(),
      'field_size_m2': _fieldSizeM2,
      'start_date': DateTime.now().toIso8601String(),
      'completed_phases': _completedPhases.join(','),
      'dosage_summary': '${dosage['water_liters']}L water • ${dosage['chemical_grams']}g fungicide (${dosage['knapsack_16l_tanks']} tanks)',
      'notes': _template.summary,
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };

    await AppDatabase.instance.insertTreatmentPlan(planData);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('plan_saved_sqlite')),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _shareTreatmentPlan() {
    final dosage = TreatmentPlanService.instance.calculateDosage(areaM2: _fieldSizeM2);

    final buffer = StringBuffer();
    buffer.writeln('🌾 FieldAI Treatment & Recovery Plan');
    buffer.writeln('Crop: ${_template.crop}');
    buffer.writeln('Diagnosed Disease: ${_template.diseaseName}');
    buffer.writeln('Severity: ${_template.severity}');
    buffer.writeln('Field Area: ${_fieldSizeM2.toInt()} m²');
    buffer.writeln('Required Water: ${dosage['water_liters']} L');
    buffer.writeln('Required Active Protectant: ${dosage['chemical_grams']} g (${dosage['knapsack_16l_tanks']} knapsack tanks)');
    buffer.writeln('----------------------------------------');
    for (var phase in _template.phases) {
      buffer.writeln('\n[${phase.timeline}] ${phase.title}');
      buffer.writeln('Remedy: ${phase.activeRemedy}');
      for (var step in phase.steps) {
        buffer.writeln('• $step');
      }
      buffer.writeln('Safety: ${phase.safetyPrecautions}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('plan_copied_clipboard')),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final dosage = TreatmentPlanService.instance.calculateDosage(areaM2: _fieldSizeM2);
    final isCritical = _template.severity.contains('Critical');

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(context.tr('treatment_plan_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Treatment Plan',
            onPressed: _shareTreatmentPlan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overview Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isCritical ? AppTheme.dangerRed : AppTheme.primaryGreen).withValues(alpha: isDark ? 0.2 : 0.08),
                    context.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isCritical ? AppTheme.dangerRed : AppTheme.primaryGreen).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _template.crop,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCritical ? AppTheme.dangerRed : AppTheme.warningAmber).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _template.severity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCritical ? AppTheme.dangerRed : AppTheme.warningAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _template.diseaseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _template.summary,
                    style: TextStyle(fontSize: 13, height: 1.4, color: context.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Field Area & Dosage Calculator
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('dosage_calc_title'),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                      ),
                      Text(
                        '${_fieldSizeM2.toInt()} m² (${(dosage['area_ha'] as double).toStringAsFixed(2)} ha)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _fieldSizeM2,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    activeColor: AppTheme.primaryGreen,
                    inactiveColor: context.cardBorder,
                    label: '${_fieldSizeM2.toInt()} m²',
                    onChanged: (val) => setState(() => _fieldSizeM2 = val),
                  ),
                  const SizedBox(height: 8),

                  // Calculated metrics grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildDosageStat(
                          icon: Icons.water_drop_outlined,
                          label: context.tr('water_volume'),
                          value: '${dosage['water_liters']} L',
                          color: AppTheme.infoBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDosageStat(
                          icon: Icons.science_outlined,
                          label: context.tr('protectant_powder'),
                          value: '${dosage['chemical_grams']} g',
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDosageStat(
                          icon: Icons.backpack_outlined,
                          label: context.tr('knapsack_tanks'),
                          value: '${dosage['knapsack_16l_tanks']} × 16L',
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step-by-step Phase Timeline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('treatment_schedule_phases'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${_completedPhases.length}/${_template.phases.length} ${context.tr('completed')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _completedPhases.length == _template.phases.length
                        ? AppTheme.successGreen
                        : context.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ..._template.phases.map((phase) {
              final isDone = _completedPhases.contains(phase.phaseId);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone ? AppTheme.primaryGreen : context.cardBorder,
                    width: isDone ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isDone,
                            activeColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => _togglePhase(phase.phaseId),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        phase.timeline,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      phase.category,
                                      style: TextStyle(fontSize: 11, color: context.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  phase.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.medication_liquid_rounded, size: 14, color: AppTheme.primaryGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Remedy: ${phase.activeRemedy}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...phase.steps.map((step) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                      Expanded(
                                        child: Text(
                                          step,
                                          style: TextStyle(fontSize: 12, height: 1.35, color: context.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 4),
                            Text(
                              '⚠️ Safety: ${phase.safetyPrecautions}',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: context.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Save Plan Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTreatmentPlan,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(_isSaved ? Icons.check_circle_rounded : Icons.save_rounded),
              label: Text(
                _isSaved ? context.tr('plan_updated_btn') : context.tr('save_plan_btn'),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
              onPressed: _shareTreatmentPlan,
              icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryGreen, size: 18),
              label: Text(
                context.tr('copy_plan_summary'),
                style: const TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: context.textMuted),
          ),
        ],
      ),
    );
  }
}
