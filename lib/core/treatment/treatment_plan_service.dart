class TreatmentPhase {
  final String phaseId;
  final String title;
  final String timeline; // e.g. "Day 1–2"
  final String category; // Emergency Sanitation, Bio/Organic, Chemical, Cultural
  final List<String> steps;
  final String activeRemedy;
  final String safetyPrecautions;

  const TreatmentPhase({
    required this.phaseId,
    required this.title,
    required this.timeline,
    required this.category,
    required this.steps,
    required this.activeRemedy,
    required this.safetyPrecautions,
  });
}

class TreatmentTemplate {
  final String crop;
  final String diseaseName;
  final String severity;
  final String summary;
  final List<TreatmentPhase> phases;
  final double recommendedWaterLitersPerHa;
  final double chemicalGramsPerLiter;
  final double organicMlPerLiter;
  final int preHarvestIntervalDays;

  const TreatmentTemplate({
    required this.crop,
    required this.diseaseName,
    required this.severity,
    required this.summary,
    required this.phases,
    this.recommendedWaterLitersPerHa = 400.0,
    this.chemicalGramsPerLiter = 2.5,
    this.organicMlPerLiter = 5.0,
    this.preHarvestIntervalDays = 7,
  });
}

class TreatmentPlanService {
  static final TreatmentPlanService instance = TreatmentPlanService._init();

  TreatmentPlanService._init();

  TreatmentTemplate getTreatmentTemplate(String crop, String disease) {
    final lower = disease.toLowerCase();

    if (lower.contains('late blight') || lower.contains('phytophthora')) {
      return TreatmentTemplate(
        crop: crop.isNotEmpty ? crop : 'Tomato',
        diseaseName: 'Late Blight (Phytophthora infestans)',
        severity: 'Critical / Emergency',
        summary: 'Aggressive oomycete requiring immediate foliage containment, systemic fungicide rescue, and microclimate aeration.',
        recommendedWaterLitersPerHa: 450.0,
        chemicalGramsPerLiter: 2.5,
        organicMlPerLiter: 5.0,
        preHarvestIntervalDays: 7,
        phases: [
          const TreatmentPhase(
            phaseId: 'phase_1',
            title: 'Phase 1: Emergency Field Sanitation & Pruning',
            timeline: 'Day 1 (Immediate)',
            category: 'Sanitation',
            steps: [
              'Scout field and immediately flag heavily blighted plants (>40% canopy damaged).',
              'Carefully rogue (uproot) severely infected plants into sealed bags; bury or burn away from field borders.',
              'Disinfect pruning shears with 70% alcohol or 10% bleach between each plant row.',
              'Cease all overhead sprinkler irrigation immediately to avoid spreading zoosporangia.'
            ],
            activeRemedy: 'Physical eradication + 70% Ethanol tool sterilizer',
            safetyPrecautions: 'Do not touch wet uninfected foliage after handling blighted tissues.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_2',
            title: 'Phase 2: Systemic & Protective Fungicide Application',
            timeline: 'Days 2–4',
            category: 'Chemical Rescue',
            steps: [
              'Apply systemic fungicide (Metalaxyl-M 4% + Mancozeb 64% WP) to penetrate active mycelium.',
              'Ensure thorough underside leaf coverage using a fine hollow-cone nozzle (3.0 bar pressure).',
              'Re-apply contact protectant (Copper Hydroxide 77 WP @ 2.5g/L) after 5 days if wet conditions persist.',
            ],
            activeRemedy: 'Metalaxyl-M + Mancozeb (2.5g/L) or Dimethomorph (1.5g/L)',
            safetyPrecautions: 'Wear PPE (N95 mask, rubber gloves, protective goggles). Observe 7-day PHI.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_3',
            title: 'Phase 3: Bio-Fungicide & Immunity Fortification',
            timeline: 'Days 7–10',
            category: 'Organic / Biological',
            steps: [
              'Foliar spray of Bacillus subtilis (2g/L) or Copper soap bio-fungicide during early morning hours.',
              'Apply Calcium Nitrate + Potassium foliar spray to thicken cell walls against hyphal penetration.',
            ],
            activeRemedy: 'Bacillus subtilis QST 713 bio-protectant',
            safetyPrecautions: 'Do not tank-mix bio-fungicides with concentrated synthetic copper.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_4',
            title: 'Phase 4: Long-Term Cultural Control & Mulching',
            timeline: 'Days 11–14+',
            category: 'Cultural Prevention',
            steps: [
              'Spread a 5cm layer of clean dry straw or rice husk mulch across rows to prevent rain spore splashing.',
              'Prune bottom 30cm of tomato suckers to maintain relative humidity below 80% inside canopy.',
              'Schedule a 3-year crop rotation with non-Solanaceous species (Maize, Haricot Bean, Sorghum).'
            ],
            activeRemedy: 'Organic straw mulch + Drip fertigation',
            safetyPrecautions: 'Avoid working in field during dense morning dew periods.',
          ),
        ],
      );
    } else if (lower.contains('septoria')) {
      return TreatmentTemplate(
        crop: crop.isNotEmpty ? crop : 'Tomato',
        diseaseName: 'Septoria Leaf Spot (Septoria lycopersici)',
        severity: 'Moderate',
        summary: 'Lower foliar pathogen requiring bottom leaf stripping, preventive copper spray, and spacing adjustments.',
        phases: [
          const TreatmentPhase(
            phaseId: 'phase_1',
            title: 'Phase 1: Bottom Leaf Stripping & Sanitation',
            timeline: 'Day 1',
            category: 'Sanitation',
            steps: [
              'Remove and discard all symptomatic lower leaves showing circular spots with dark borders.',
              'Clear fallen crop debris from soil bed around the root collar.',
            ],
            activeRemedy: 'Mechanical defoliation of lower 25cm foliage',
            safetyPrecautions: 'Prune only when leaf canopy is completely dry.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_2',
            title: 'Phase 2: Contact Protectant Spray',
            timeline: 'Days 3–5',
            category: 'Fungicide Protection',
            steps: [
              'Apply Copper Oxychloride 50 WP (2.5g/L) or Chlorothalonil 75 WP on upper and lower leaves.',
              'Maintain 7-day spray interval during persistent rainy periods.',
            ],
            activeRemedy: 'Copper Oxychloride (2.5g/L) or Chlorothalonil',
            safetyPrecautions: 'Wear gloves and mask during spray preparation.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_3',
            title: 'Phase 3: Canopy Aeration & Soil Barrier',
            timeline: 'Days 7–14',
            category: 'Cultural Management',
            steps: [
              'Stake or trellis plants vertically to keep leaves away from damp ground.',
              'Mulch with dry organic straw to stop soil rain splash.',
            ],
            activeRemedy: 'Vertical trellising + Organic ground mulch',
            safetyPrecautions: 'Maintain 60cm row spacing for optimal airflow.',
          ),
        ],
      );
    } else if (lower.contains('leaf mold') || lower.contains('passalora')) {
      return TreatmentTemplate(
        crop: crop.isNotEmpty ? crop : 'Tomato',
        diseaseName: 'Leaf Mold (Passalora fulva)',
        severity: 'Mild to Moderate',
        summary: 'High humidity canopy pathogen controlled by drastic ventilation increases and organic bio-fungicides.',
        phases: [
          const TreatmentPhase(
            phaseId: 'phase_1',
            title: 'Phase 1: Microclimate & Humidity Reduction',
            timeline: 'Day 1–2',
            category: 'Microclimate',
            steps: [
              'Open high tunnel / greenhouse side vents to drop humidity below 80%.',
              'Prune dense interior non-fruiting suckers to maximize cross-breeze airflow.',
            ],
            activeRemedy: 'Canopy thinning + Tunnel ventilation',
            safetyPrecautions: 'Avoid late afternoon sprinkler watering.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_2',
            title: 'Phase 2: Bio-Fungicide & Potassium Bicarbonate',
            timeline: 'Days 3–7',
            category: 'Biological Treatment',
            steps: [
              'Spray Potassium Bicarbonate (3g/L) + 2ml liquid soap on lower leaf velvet mold spots.',
              'Apply Bacillus subtilis foliar spray to colonize leaf surface against spore germination.',
            ],
            activeRemedy: 'Potassium Bicarbonate (3g/L) or Bacillus subtilis',
            safetyPrecautions: 'Zero harvest withholding period (0-day PHI).',
          ),
        ],
      );
    } else {
      // Default Early Blight & General Protocol
      return TreatmentTemplate(
        crop: crop.isNotEmpty ? crop : 'Tomato',
        diseaseName: 'Early Blight (Alternaria solani)',
        severity: 'Moderate',
        summary: 'Target-board leaf spot protocol focusing on lower canopy defoliation, copper protection, and drip irrigation conversion.',
        phases: [
          const TreatmentPhase(
            phaseId: 'phase_1',
            title: 'Phase 1: Foliar Defoliation & Plant Sanitation',
            timeline: 'Day 1–2',
            category: 'Cultural Sanitation',
            steps: [
              'Prune all lower leaves showing target-board concentric brown lesions.',
              'Place pruned leaves directly in a bag and destroy outside field.',
              'Sterilize pruners in 70% alcohol or boiling water after finishing row.',
            ],
            activeRemedy: 'Sanitary pruning + Clean bagging',
            safetyPrecautions: 'Prune only during mid-day when leaves are dry.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_2',
            title: 'Phase 2: Protective Copper & Bio-Foliar Spray',
            timeline: 'Days 3–5',
            category: 'Integrated Spray',
            steps: [
              'Apply Copper Hydroxide (2.5g/L) or Chlorothalonil 75 WP at first lesion sign.',
              'For organic fields: Apply cold-pressed Neem Oil (5ml/L) + Potassium soap late in the evening.',
              'Spray uniformly to leaf run-off point, targeting both upper and lower foliage surfaces.',
            ],
            activeRemedy: 'Copper Hydroxide 77 WP (2.5g/L) or 0.5% Neem Emulsion',
            safetyPrecautions: 'Wear eye protection. Do not spray during peak bee foraging hours.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_3',
            title: 'Phase 3: Irrigation & Soil Spore Barrier',
            timeline: 'Days 6–8',
            category: 'Water Management',
            steps: [
              'Cease overhead sprinkler watering; transition to low-pressure ground drip irrigation lines.',
              'Apply 4–6 cm clean dry straw mulch around plant root zone to prevent rain spore splashing.',
            ],
            activeRemedy: 'Straw mulch barrier + Ground drip conversion',
            safetyPrecautions: 'Keep mulch 2cm away from direct stem contact.',
          ),
          const TreatmentPhase(
            phaseId: 'phase_4',
            title: 'Phase 4: Crop Nutrition & Long-Term Rotation',
            timeline: 'Days 9–14+',
            category: 'Nutrition & Rotation',
            steps: [
              'Boost foliar Potassium (K) and Zinc (Zn) to thicken leaf epidermal tissue.',
              'Avoid excess Nitrogen which causes overly lush, disease-vulnerable vegetative growth.',
              'Plan post-harvest crop rotation with Legumes (Beans, Cowpeas) or Poaceae (Maize).',
            ],
            activeRemedy: 'Potassium Sulphate foliar feed + Legume rotation',
            safetyPrecautions: 'Scout field twice weekly to detect recurring spore infection.',
          ),
        ],
      );
    }
  }

  /// Calculates chemical and water requirements based on field size in square meters
  Map<String, dynamic> calculateDosage({
    required double areaM2,
    double waterLitersPerHa = 400.0,
    double chemicalGramsPerL = 2.5,
    double organicMlPerL = 5.0,
  }) {
    double areaHa = areaM2 / 10000.0;
    double totalWaterLiters = (areaHa * waterLitersPerHa).clamp(5.0, 5000.0);
    double totalChemicalGrams = totalWaterLiters * chemicalGramsPerL;
    double totalOrganicMl = totalWaterLiters * organicMlPerL;
    int knapsackTanks16L = (totalWaterLiters / 16.0).ceil();

    return {
      'area_m2': areaM2,
      'area_ha': areaHa,
      'water_liters': totalWaterLiters.toStringAsFixed(1),
      'chemical_grams': totalChemicalGrams.toStringAsFixed(0),
      'organic_ml': totalOrganicMl.toStringAsFixed(0),
      'knapsack_16l_tanks': knapsackTanks16L,
      'chemical_per_16l_tank': (16.0 * chemicalGramsPerL).toStringAsFixed(1),
      'organic_per_16l_tank': (16.0 * organicMlPerL).toStringAsFixed(1),
    };
  }
}
