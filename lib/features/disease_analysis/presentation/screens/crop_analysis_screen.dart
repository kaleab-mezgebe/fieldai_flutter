import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/core/ai/edge_inference_service.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/features/disease_analysis/presentation/screens/ai_explanation_screen.dart';
import 'package:fieldai_flutter/features/observations/presentation/screens/observation_screen.dart';
import 'package:fieldai_flutter/features/treatment/presentation/screens/treatment_plan_screen.dart';

class CropAnalysisScreen extends StatefulWidget {
  const CropAnalysisScreen({super.key});

  @override
  State<CropAnalysisScreen> createState() => _CropAnalysisScreenState();
}

class _CropAnalysisScreenState extends State<CropAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _selectedSampleKey;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _predictionResult;

  final List<Map<String, dynamic>> _sampleLeaves = [
    {
      'key': 'early_blight',
      'label': 'Early Blight',
      'sub': 'Alternaria solani',
      'color': AppTheme.warningAmber,
      'crop': 'Tomato',
      'result': {
        'crop': 'Tomato',
        'condition_class': 'Tomato___Early_blight',
        'condition_name': 'Early Blight (Alternaria solani)',
        'confidence': 89.4,
        'severity': 'Moderate',
        'status': 'Action Recommended',
        'explanation': 'Concentric target-board ring lesions with yellow chlorotic halos on older lower foliage.',
        'pathogen_info': 'Caused by fungal pathogen Alternaria solani. Spores overwinter in crop residue and spread via wind and splashing water.',
        'conducive_factors': 'Warm temperatures (24-29°C) combined with frequent rain or overhead irrigation.',
        'recommended_actions': [
          'Prune and destroy infected lower foliage immediately.',
          'Cease overhead sprinkler watering; switch to drip ground lines.',
          'Apply Copper Hydroxide (2.5g/L) or Chlorothalonil protectant spray.',
          'Apply organic straw mulch around plant base to prevent soil spore splash.'
        ],
        'safety_disclaimer': 'Informational AI diagnosis supporting field management decisions.'
      }
    },
    {
      'key': 'late_blight',
      'label': 'Late Blight',
      'sub': 'Phytophthora infestans',
      'color': AppTheme.dangerRed,
      'crop': 'Tomato',
      'result': {
        'crop': 'Tomato',
        'condition_class': 'Tomato___Late_blight',
        'condition_name': 'Late Blight (Phytophthora infestans)',
        'confidence': 93.8,
        'severity': 'Critical / Emergency',
        'status': 'Critical Outbreak Risk',
        'explanation': 'Rapidly expanding water-soaked dark brown necrotic blotches with pale green margins and white sporulation under humid canopy.',
        'pathogen_info': 'Oomycete pathogen Phytophthora infestans. Capable of destroying entire crop fields within 7 to 10 days under favorable conditions.',
        'conducive_factors': 'Cool, humid weather (15-22°C) with relative humidity above 85% and prolonged leaf wetness.',
        'recommended_actions': [
          'Rogue, bag, and bury heavily infected plants away from field immediately.',
          'Ensure strict air circulation and avoid working in wet canopy.',
          'Apply systemic fungicide (Metalaxyl-M + Mancozeb or Dimethomorph).',
          'Notify neighboring farmers of high regional late blight spore pressure.'
        ],
        'safety_disclaimer': 'Informational AI diagnosis supporting field management decisions.'
      }
    },
    {
      'key': 'septoria',
      'label': 'Septoria Spot',
      'sub': 'Septoria lycopersici',
      'color': AppTheme.warningAmber,
      'crop': 'Tomato',
      'result': {
        'crop': 'Tomato',
        'condition_class': 'Tomato___Septoria_leaf_spot',
        'condition_name': 'Septoria Leaf Spot',
        'confidence': 86.5,
        'severity': 'Moderate',
        'status': 'Treatment Required',
        'explanation': 'Numerous small circular spots (1.5-3mm) with dark brown borders and grey-white sunken centers on foliage.',
        'pathogen_info': 'Fungus Septoria lycopersici attacking lower foliage first, causing premature leaf drop and fruit sunscald.',
        'conducive_factors': 'Warm wet periods (20-25°C) with high humidity and rain splashing.',
        'recommended_actions': [
          'Remove infected lower leaves promptly.',
          'Improve spacing to reduce humidity in microclimate.',
          'Apply preventive Copper oxychloride spray on unaffected foliage.',
          'Implement 2-year crop rotation without solanaceous species.'
        ],
        'safety_disclaimer': 'Informational AI diagnosis supporting field management decisions.'
      }
    },
    {
      'key': 'leaf_mold',
      'label': 'Leaf Mold',
      'sub': 'Passalora fulva',
      'color': AppTheme.infoBlue,
      'crop': 'Tomato',
      'result': {
        'crop': 'Tomato',
        'condition_class': 'Tomato___Leaf_Mold',
        'condition_name': 'Leaf Mold (Passalora fulva)',
        'confidence': 91.2,
        'severity': 'Mild to Moderate',
        'status': 'Ventilation Needed',
        'explanation': 'Pale green to yellowish spots on upper leaf surfaces matching olive-green velvety fungal patches on lower surfaces.',
        'pathogen_info': 'Common in high tunnels and greenhouses with inadequate air exchange and relative humidity exceeding 85%.',
        'conducive_factors': 'High humidity (>85%) and moderate temperatures (21-24°C).',
        'recommended_actions': [
          'Increase tunnel/greenhouse ventilation immediately.',
          'Prune dense canopy suckers to lower interior humidity below 80%.',
          'Apply bio-fungicide Bacillus subtilis or Copper soap solution.'
        ],
        'safety_disclaimer': 'Informational AI diagnosis supporting field management decisions.'
      }
    },
    {
      'key': 'healthy',
      'label': 'Healthy Foliage',
      'sub': 'Optimal Condition',
      'color': AppTheme.successGreen,
      'crop': 'Tomato',
      'result': {
        'crop': 'Tomato',
        'condition_class': 'Tomato___healthy',
        'condition_name': 'Healthy Tomato Foliage',
        'confidence': 97.5,
        'severity': 'None',
        'status': 'Optimal Health',
        'explanation': 'Uniform leaf pigmentation, intact cuticle, and healthy venation with zero observable fungal, bacterial, or viral lesion patterns.',
        'pathogen_info': 'Plant exhibits vigorous physiological health and balanced chlorophyll distribution.',
        'conducive_factors': 'Adequate sunlight, balanced soil moisture, and optimal soil pH (6.0-6.8).',
        'recommended_actions': [
          'Continue balanced potassium and calcium fertigation.',
          'Maintain regular scouting every 3-4 days during flowering.',
          'Keep weed-free border buffer around field rows.'
        ],
        'safety_disclaimer': 'Regular scouting maintains crop health and early detection.'
      }
    },
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _selectedSampleKey = null;
          _predictionResult = null;
        });
        _runInference();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access image: $e'), backgroundColor: AppTheme.dangerRed),
      );
    }
  }

  void _loadSampleLeaf(Map<String, dynamic> sample) {
    setState(() {
      _selectedSampleKey = sample['key'];
      _imageBytes = null;
      _predictionResult = null;
    });
    _runInference(sampleData: sample['result']);
  }

  Future<void> _runInference({Map<String, dynamic>? sampleData}) async {
    setState(() => _isAnalyzing = true);

    try {
      if (sampleData != null) {
        await Future.delayed(const Duration(milliseconds: 650));
        setState(() {
          _predictionResult = Map<String, dynamic>.from(sampleData);
        });
      } else if (_imageBytes != null && _imageBytes!.length > 500) {
        try {
          final response = await ApiClient.instance.uploadAndPredict(
            imageBytes: _imageBytes!,
            fileName: 'field_leaf_${DateTime.now().millisecondsSinceEpoch}.jpg',
            crop: 'Tomato',
          );
          if (response.statusCode == 200) {
            setState(() {
              _predictionResult = response.data;
            });
          }
        } catch (_) {
          // On-Device Edge AI inference
          final edgeResult = await EdgeInferenceService.instance.analyzeLeafImage(_imageBytes!);
          setState(() {
            _predictionResult = edgeResult.toMap();
          });
        }
      }

      if (_predictionResult != null) {
        await AppDatabase.instance.insertPrediction({
          'prediction_id': _predictionResult!['id'] ?? 'diag_${DateTime.now().millisecondsSinceEpoch}',
          'crop': _predictionResult!['crop'] ?? 'Tomato',
          'condition_class': _predictionResult!['condition_class'] ?? 'Tomato___Early_blight',
          'condition_name': _predictionResult!['condition_name'] ?? 'Early Blight',
          'confidence': (_predictionResult!['confidence'] as num?)?.toDouble() ?? 88.0,
          'severity': _predictionResult!['severity'] ?? 'Moderate',
          'status': _predictionResult!['status'] ?? 'Needs attention',
          'explanation': _predictionResult!['explanation'] ?? '',
          'recommended_actions': (_predictionResult!['recommended_actions'] is List)
              ? (_predictionResult!['recommended_actions'] as List).join(' | ')
              : _predictionResult!['recommended_actions']?.toString() ?? '',
          'image_path': 'assets/samples/${_selectedSampleKey ?? "camera"}.jpg',
          'created_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
        });
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(context.tr('analyze_crop')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : _selectedSampleKey != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  size: 48,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${context.tr('crop')}: ${_sampleLeaves.firstWhere((s) => s['key'] == _selectedSampleKey)['label']}',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('extracting_markers'),
                                style: TextStyle(color: context.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 48,
                                color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('analyze_crop_sub'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // Camera & Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(context.tr('camera')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.tr('gallery')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Sample Leaf Selector Chips
            Text(
              context.tr('test_samples'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sampleLeaves.map((s) {
                final isSelected = _selectedSampleKey == s['key'];
                final Color chipColor = s['color'] as Color;

                return ChoiceChip(
                  label: Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : context.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: context.surfaceCard,
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryGreen : chipColor.withValues(alpha: 0.4),
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: chipColor.withValues(alpha: 0.3),
                    radius: 6,
                  ),
                  onSelected: (selected) {
                    if (selected) _loadSampleLeaf(s);
                  },
                );
              }).toList(),
            ),

            if (_isAnalyzing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryGreen),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('running_ai'),
                        style: TextStyle(color: context.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('extracting_markers'),
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            if (_predictionResult != null && !_isAnalyzing) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 14,
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
                          context.tr('diagnosis_result'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_predictionResult!['severity'] == 'Critical' || _predictionResult!['severity'] == 'Critical / Emergency'
                                    ? AppTheme.dangerRed
                                    : (_predictionResult!['severity'] == 'None'
                                        ? AppTheme.successGreen
                                        : AppTheme.warningAmber))
                                .withValues(alpha: isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _predictionResult!['severity'] == 'Critical' || _predictionResult!['severity'] == 'Critical / Emergency'
                                  ? AppTheme.dangerRed
                                  : (_predictionResult!['severity'] == 'None'
                                      ? AppTheme.successGreen
                                      : AppTheme.warningAmber),
                            ),
                          ),
                          child: Text(
                            _predictionResult!['status'] ?? 'Action Recommended',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _predictionResult!['severity'] == 'Critical' || _predictionResult!['severity'] == 'Critical / Emergency'
                                  ? AppTheme.dangerRed
                                  : (_predictionResult!['severity'] == 'None'
                                      ? AppTheme.successGreen
                                      : AppTheme.warningAmber),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: context.cardBorder, height: 28),

                    _buildResultRow(context, context.tr('crop'), _predictionResult!['crop'] ?? 'Tomato'),
                    const SizedBox(height: 10),
                    _buildResultRow(
                      context,
                      context.tr('identified_condition'),
                      _predictionResult!['condition_name'] ?? 'Early Blight',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 10),
                    _buildResultRow(
                      context,
                      context.tr('ai_confidence'),
                      '${_predictionResult!['confidence']}%',
                    ),
                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((_predictionResult!['confidence'] as num?)?.toDouble() ?? 80.0) / 100.0,
                        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AiExplanationScreen(prediction: _predictionResult!),
                                ),
                              );
                            },
                            child: Text(context.tr('view_protocol')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ObservationScreen(
                                    prefilledCrop: _predictionResult!['crop'],
                                    prefilledDisease: _predictionResult!['condition_name'],
                                    prefilledConfidence: (_predictionResult!['confidence'] as num?)?.toDouble(),
                                  ),
                                ),
                              );
                            },
                            child: Text(context.tr('log_observation')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TreatmentPlanScreen(
                                crop: _predictionResult!['crop'] ?? 'Tomato',
                                diseaseName: _predictionResult!['condition_name'] ?? 'Early Blight',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medication_rounded, size: 18),
                        label: Text(context.tr('treatment_plan_btn')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: context.textMuted)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 14,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryGreen : context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
