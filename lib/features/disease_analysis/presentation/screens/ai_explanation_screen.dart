import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';

class AiExplanationScreen extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const AiExplanationScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final conditionName = prediction['condition_name'] ?? 'Early Blight (Alternaria solani)';
    final crop = prediction['crop'] ?? 'Tomato';
    final explanation = prediction['explanation'] ?? 'Foliar lesion morphology matches fungal sporulation characteristics.';
    final pathogenInfo = prediction['pathogen_info'] ?? 'Pathogen spreads rapidly via air-borne spores under favorable temperature and moisture.';
    final conduciveFactors = prediction['conducive_factors'] ?? 'High relative humidity (>80%) and temperatures between 20°C and 28°C.';

    List<String> actions = [];
    if (prediction['recommended_actions'] is List) {
      actions = List<String>.from(prediction['recommended_actions']);
    } else if (prediction['recommended_actions'] is String) {
      actions = (prediction['recommended_actions'] as String).split('|').map((s) => s.trim()).toList();
    }
    if (actions.isEmpty) {
      actions = [
        'Prune lower infected foliage and remove from field perimeter.',
        'Cease overhead sprinkler watering; prioritize soil drip lines.',
        'Apply copper hydroxide or organic neem oil extract.'
      ];
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(context.tr('agronomic_protocol')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Overview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: AppTheme.primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conditionName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$crop • ${context.tr('agronomic_protocol')}',
                          style: TextStyle(fontSize: 13, color: context.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Diagnostic Rationale Section
            Text(
              context.tr('diagnostic_rationale'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
            const SizedBox(height: 10),
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
                  Text(
                    explanation,
                    style: TextStyle(fontSize: 14, height: 1.5, color: context.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: context.cardBorder),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pathogenInfo,
                          style: TextStyle(fontSize: 12, height: 1.4, color: context.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conducive Climate Conditions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.thermostat_rounded, color: AppTheme.warningAmber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('conducive_climate'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.warningAmber),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conduciveFactors,
                          style: TextStyle(fontSize: 12, height: 1.4, color: context.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recommended Field Actions
            Text(
              context.tr('ipm_interventions'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
            const SizedBox(height: 12),

            ...actions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final act = entry.value;
              return _buildActionStep(context, idx, act);
            }),

            const SizedBox(height: 20),
            // Disclaimer footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: context.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('ai_disclaimer'),
                      style: TextStyle(fontSize: 11, color: context.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStep(BuildContext context, int stepNum, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNum',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: context.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
