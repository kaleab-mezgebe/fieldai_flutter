import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/features/disease_analysis/presentation/screens/ai_explanation_screen.dart';

class FieldGuideScreen extends StatefulWidget {
  const FieldGuideScreen({super.key});

  @override
  State<FieldGuideScreen> createState() => _FieldGuideScreenState();
}

class _FieldGuideScreenState extends State<FieldGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCropCategory = 'All';
  String _searchQuery = '';

  final List<String> _cropCategories = ['All', 'Solanaceae', 'Cereals', 'Legumes', 'Cash Crops'];

  final List<Map<String, dynamic>> _guideEntries = [
    {
      'crop': 'Tomato',
      'category': 'Solanaceae',
      'disease_name': 'Early Blight (Alternaria solani)',
      'condition_class': 'Tomato___Early_blight',
      'pathogen_type': 'Fungal (Alternaria solani)',
      'severity': 'Moderate',
      'confidence': 94.0,
      'status': 'Action Recommended',
      'symptoms': 'Concentric target-board ring lesions on older foliage with yellow chlorotic margins.',
      'climate_conducive': 'Warm humid weather (24-29°C) with prolonged leaf wetness and overhead rain splashing.',
      'ipm_actions': [
        'Prune lower 30cm of canopy to prevent soil splash.',
        'Switch to ground drip irrigation; avoid overhead sprinklers.',
        'Apply Copper Hydroxide (2.5g/L) or Chlorothalonil 75 WP at first lesion appearance.',
        'Apply clean straw mulch around root base.'
      ],
      'organic_options': 'Trichoderma harzianum soil inoculation, 0.5% neem oil foliar spray.',
      'fertilizer_tips': 'Maintain balanced Potassium (K) to bolster plant cell wall thickness.'
    },
    {
      'crop': 'Tomato',
      'category': 'Solanaceae',
      'disease_name': 'Late Blight (Phytophthora infestans)',
      'condition_class': 'Tomato___Late_blight',
      'pathogen_type': 'Oomycete (Phytophthora infestans)',
      'severity': 'Critical',
      'confidence': 96.5,
      'status': 'Critical Outbreak Risk',
      'symptoms': 'Rapidly expanding water-soaked dark brown necrotic blotches with white mildew underneath.',
      'climate_conducive': 'Cool, humid weather (15-22°C) with relative humidity above 85% and prolonged dew.',
      'ipm_actions': [
        'Rogue, bag, and bury infected plants immediately.',
        'Apply systemic Metalaxyl-M + Mancozeb or Dimethomorph.',
        'Notify neighboring farms of regional airborne sporangia pressure.',
        'Implement strict 3-year crop rotation without Solanaceae.'
      ],
      'organic_options': 'Copper octanoate bio-fungicide, Bacillus subtilis preventive sprays.',
      'fertilizer_tips': 'Avoid excessive nitrogen fertilization which produces soft, susceptible foliage.'
    },
    {
      'crop': 'Tomato',
      'category': 'Solanaceae',
      'disease_name': 'Septoria Leaf Spot (Septoria lycopersici)',
      'condition_class': 'Tomato___Septoria_leaf_spot',
      'pathogen_type': 'Fungal (Septoria lycopersici)',
      'severity': 'Moderate',
      'confidence': 91.0,
      'status': 'Treatment Required',
      'symptoms': 'Small circular lesions (1.5-3mm) with dark borders and grey sunken centers with pycnidia.',
      'climate_conducive': 'Warm wet periods (20-25°C) with high humidity and dense unpruned canopy.',
      'ipm_actions': [
        'Strip infected lower leaves promptly.',
        'Improve plant spacing to 60cm for maximum airflow.',
        'Apply Copper Oxychloride or Mancozeb on lower canopy.',
        'Disinfect pruning tools with 70% alcohol.'
      ],
      'organic_options': 'Compost tea foliar spray, Potassium bicarbonate (3g/L).',
      'fertilizer_tips': 'Ensure adequate micronutrient calcium & zinc supply.'
    },
    {
      'crop': 'Potato',
      'category': 'Solanaceae',
      'disease_name': 'Bacterial Wilt (Ralstonia solanacearum)',
      'condition_class': 'Potato___Bacterial_wilt',
      'pathogen_type': 'Bacterial (Ralstonia solanacearum)',
      'severity': 'Critical',
      'confidence': 92.0,
      'status': 'Quarantine Protocol',
      'symptoms': 'Rapid daytime wilting of canopy while foliage remains green; vascular brown ring in tubers.',
      'climate_conducive': 'Warm soil temperatures (25-35°C) with poorly drained waterlogged soils.',
      'ipm_actions': [
        'Plant only certified disease-free seed tubers.',
        'Do not irrigate with runoff water from infected fields.',
        'Rotate with non-host crops (Maize, Sorghum, Pasture grasses) for 4 years.',
        'Solarize soil under clear polyethylene during dry season.'
      ],
      'organic_options': 'Bio-fumigation with Brassica (mustard) green manure.',
      'fertilizer_tips': 'Apply lime to soils with low pH to optimize nutrient uptake.'
    },
    {
      'crop': 'Pepper',
      'category': 'Solanaceae',
      'disease_name': 'Bacterial Spot (Xanthomonas campestris)',
      'condition_class': 'Pepper___Bacterial_spot',
      'pathogen_type': 'Bacterial (Xanthomonas campestris)',
      'severity': 'Moderate',
      'confidence': 88.5,
      'status': 'Action Recommended',
      'symptoms': 'Small water-soaked blister spots turning brown with cracked centers on leaves and fruits.',
      'climate_conducive': 'High temperatures (24-30°C) with wind-driven heavy rain.',
      'ipm_actions': [
        'Use hot-water treated seeds (50°C for 25 mins).',
        'Apply Copper Hydroxide mixed with Mancozeb for synergistic bacterial suppression.',
        'Eliminate volunteer solanaceous weeds around field borders.'
      ],
      'organic_options': 'Copper soap spray, Bacteriophage biocontrol formulations.',
      'fertilizer_tips': 'Avoid sprinkler irrigation during active vegetative growth.'
    },
    {
      'crop': 'Maize',
      'category': 'Cereals',
      'disease_name': 'Maize Lethal Necrosis (MLND)',
      'condition_class': 'Maize___MLND',
      'pathogen_type': 'Viral (MCMV + Potyvirus Complex)',
      'severity': 'Critical',
      'confidence': 95.0,
      'status': 'Critical Outbreak Risk',
      'symptoms': 'Chlorotic mottling, severe leaf bleaching, dying leaf margins from tassel downwards.',
      'climate_conducive': 'Continuous maize cropping cycles with high vector pressure (thrips & chrysomelid beetles).',
      'ipm_actions': [
        'Impose a strict closed season (maize-free period) between cropping seasons.',
        'Control insect vectors (thrips/aphids) with systemic insecticides early.',
        'Plant tolerant certified hybrid seed varieties.',
        'Uproot and burn diseased plants immediately.'
      ],
      'organic_options': 'Sticky traps for thrips monitoring, neem seed extract sprays.',
      'fertilizer_tips': 'Top-dress with Urea (46% N) at knee-height stage to sustain vigorous growth.'
    },
    {
      'crop': 'Wheat',
      'category': 'Cereals',
      'disease_name': 'Stem Rust / Ug99 (Puccinia graminis)',
      'condition_class': 'Wheat___Stem_rust',
      'pathogen_type': 'Fungal (Puccinia graminis)',
      'severity': 'Critical',
      'confidence': 94.2,
      'status': 'Urgent Alert',
      'symptoms': 'Reddish-brown elongated pustules rupturing stem epidermis; plant lodging under wind.',
      'climate_conducive': 'Warm sunny days (20-30°C) with moist dewy nights.',
      'ipm_actions': [
        'Plant resistant wheat cultivars (e.g. Kingbird, Ogolcho).',
        'Apply Triazole or Strobilurin fungicides (Tebuconazole / Propiconazole) at first pustule flag.',
        'Eradicate alternative barberry hosts in surrounding landscape.'
      ],
      'organic_options': 'Early planting to escape late-season spore showers.',
      'fertilizer_tips': 'Avoid excessive nitrogen; ensure balanced phosphorus and potassium.'
    },
    {
      'crop': 'Coffee',
      'category': 'Cash Crops',
      'disease_name': 'Coffee Leaf Rust (Hemileia vastatrix)',
      'condition_class': 'Coffee___Leaf_rust',
      'pathogen_type': 'Fungal (Hemileia vastatrix)',
      'severity': 'High',
      'confidence': 93.0,
      'status': 'Treatment Required',
      'symptoms': 'Orange-yellow powdery spore spots on leaf undersides causing extensive defoliation.',
      'climate_conducive': 'Warm temperatures (21-25°C) with rain showers and shaded microclimates.',
      'ipm_actions': [
        'Prune shade trees to allow 40-50% filtered sunlight penetration.',
        'Apply preventative Copper oxychloride (50 WP) prior to onset of main rains.',
        'Plant rust-resistant Arabica selections (e.g. Ruiru 11, Batian, Catimor).'
      ],
      'organic_options': 'Beauveria bassiana and Verticillium hemileiae hyperparasite applications.',
      'fertilizer_tips': 'Apply composted coffee pulp and potassium to support heavy berry load.'
    },
  ];

  List<Map<String, dynamic>> get _filteredEntries {
    return _guideEntries.where((entry) {
      final matchesCategory = _selectedCropCategory == 'All' || entry['category'] == _selectedCropCategory;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          entry['disease_name'].toString().toLowerCase().contains(q) ||
          entry['crop'].toString().toLowerCase().contains(q) ||
          entry['symptoms'].toString().toLowerCase().contains(q) ||
          entry['pathogen_type'].toString().toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openEntryDetail(Map<String, dynamic> entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiExplanationScreen(
          prediction: {
            'crop': entry['crop'],
            'condition_name': entry['disease_name'],
            'condition_class': entry['condition_class'],
            'confidence': entry['confidence'],
            'severity': entry['severity'],
            'status': entry['status'],
            'explanation': entry['symptoms'],
            'pathogen_info': entry['pathogen_type'],
            'conducive_factors': entry['climate_conducive'],
            'recommended_actions': entry['ipm_actions'],
            'safety_disclaimer': 'Field guide manual grounded in FAO & CABI Plantwise extension standards.',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(context.tr('field_guide_title')),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: context.surfaceCard,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: context.tr('search_guide_hint'),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _cropCategories.map((cat) {
                      final isSelected = _selectedCropCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat,
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
                            if (val) setState(() => _selectedCropCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.primaryGreen),

          // Entries List
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      context.tr('no_guide_results'),
                      style: TextStyle(color: context.textMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      final isCritical = item['severity'] == 'Critical';
                      final color = isCritical
                          ? AppTheme.dangerRed
                          : (item['severity'] == 'High' ? AppTheme.warningAmber : AppTheme.primaryGreen);

                      return InkWell(
                        onTap: () => _openEntryDetail(item),
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
                                      '${item['crop']} • ${item['category']}',
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
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['severity'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['disease_name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['pathogen_type'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.infoBlue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['symptoms'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, height: 1.4, color: context.textMuted),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    context.tr('view_ipm_protocol'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryGreen),
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
}
