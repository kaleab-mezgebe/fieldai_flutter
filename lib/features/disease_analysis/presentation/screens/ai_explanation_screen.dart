import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';

class AiExplanationScreen extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const AiExplanationScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final explanation = prediction['explanation'] ?? 'The image exhibits visual symptom patterns characteristic of this pathogen.';
    final actions = List<String>.from(prediction['recommended_actions'] ?? [
      'Prune infected leaves to avoid spore spread.',
      'Maintain strict ground drip irrigation without wetting foliage.',
      'Apply protective contact fungicide before forecasted rain.'
    ]);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('AI Disease Explanation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: AppTheme.warningAmber, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction['condition_name'] ?? 'Early Blight',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prediction['crop'] ?? 'Tomato',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Why was this detected?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textLight),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text(
                explanation,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textLight),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningAmber.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline_rounded, color: AppTheme.warningAmber, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: This is an AI-assisted informational prediction, not a guaranteed clinical diagnosis. Please verify with local extension officers for severe infestations.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Recommended Field Actions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textLight),
            ),
            const SizedBox(height: 12),
            ...actions.map((act) => _buildActionBullet(act)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_outline_rounded, color: AppTheme.accentGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
