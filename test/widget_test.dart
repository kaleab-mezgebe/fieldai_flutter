import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/main.dart';
import 'package:fieldai_flutter/core/theme/theme_service.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/localization/language_service.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/core/treatment/treatment_plan_service.dart';
import 'package:fieldai_flutter/core/ai/edge_inference_service.dart';
import 'package:fieldai_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fieldai_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:fieldai_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:fieldai_flutter/features/field_guide/presentation/screens/field_guide_screen.dart';
import 'package:fieldai_flutter/features/sync_manager/presentation/screens/sync_manager_screen.dart';
import 'package:fieldai_flutter/features/treatment/presentation/screens/treatment_plan_screen.dart';
import 'package:fieldai_flutter/features/treatment/presentation/screens/treatment_list_screen.dart';
import 'package:fieldai_flutter/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:fieldai_flutter/features/observations/presentation/screens/observation_screen.dart';
import 'package:fieldai_flutter/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:fieldai_flutter/features/disease_analysis/presentation/screens/ai_explanation_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Core Services Unit Tests', () {
    test('TreatmentPlanService computes accurate chemical & organic field dosages', () {
      // 10,000 m2 (1 Hectare) test
      final dosage1Ha = TreatmentPlanService.instance.calculateDosage(areaM2: 10000.0);
      expect(dosage1Ha['area_ha'], 1.0);
      expect(dosage1Ha['water_liters'], '400.0');
      expect(dosage1Ha['chemical_grams'], '1000'); // 2.5g/L * 400L
      expect(dosage1Ha['organic_ml'], '2000');      // 5mL/L * 400L
      expect(dosage1Ha['knapsack_16l_tanks'], 25);  // 400 / 16 = 25 tanks

      // Default treatment phases
      final earlyBlightPlan = TreatmentPlanService.instance.getTreatmentTemplate('Tomato', 'Early Blight (Alternaria solani)');
      expect(earlyBlightPlan.phases.length, 4);
      expect(earlyBlightPlan.phases.first.phaseId, 'phase_1');
      expect(earlyBlightPlan.phases.first.title.contains('Sanitation'), isTrue);
    });

    test('EdgeInferenceService provides diagnosis for foliar symptoms', () async {
      final fakeBytes = Uint8List.fromList(List<int>.generate(2000, (i) => (i % 255)));
      final diagnosis = await EdgeInferenceService.instance.analyzeLeafImage(
        fakeBytes,
        forcedSampleKey: 'early_blight',
      );
      expect(diagnosis.conditionName.contains('Early Blight'), isTrue);
      expect(diagnosis.confidence >= 80.0, isTrue);
      expect(diagnosis.recommendedActions.isNotEmpty, isTrue);
    });

    test('LanguageService switches across English, Amharic, Tigrinya, and Afaan Oromoo', () async {
      // English
      await LanguageService.instance.setLanguage('en');
      expect(LanguageService.instance.languageCode, 'en');
      expect(AppStrings.get('app_name'), 'FieldAI');
      expect(AppStrings.get('analyze_crop'), 'Analyze Crop Leaf');

      // Amharic (አማርኛ)
      await LanguageService.instance.setLanguage('am');
      expect(LanguageService.instance.languageCode, 'am');
      expect(AppStrings.get('app_name'), 'ፊልድ ኤአይ (FieldAI)');
      expect(AppStrings.get('analyze_crop'), 'የሰብል ቅጠልን መርምር');
      expect(AppStrings.get('synced'), 'ተመሳስሏል');

      // Tigrinya (ትግርኛ)
      await LanguageService.instance.setLanguage('ti');
      expect(LanguageService.instance.languageCode, 'ti');
      expect(AppStrings.get('app_name'), 'ፊልድ ኤአይ (FieldAI)');
      expect(AppStrings.get('analyze_crop'), 'ናይ ሰብሊ ቆጽሊ መርምር');
      expect(AppStrings.get('synced'), 'ተመሳሲሉ');

      // Afaan Oromoo (Oromiffa)
      await LanguageService.instance.setLanguage('om');
      expect(LanguageService.instance.languageCode, 'om');
      expect(AppStrings.get('app_name'), 'FieldAI');
      expect(AppStrings.get('analyze_crop'), 'Baala Biqilaa Qoradhu');
      expect(AppStrings.get('synced'), 'Walsimsiifameera');

      // Reset back to English
      await LanguageService.instance.setLanguage('en');
      expect(LanguageService.instance.languageCode, 'en');
    });

    test('ThemeService toggles between Dark and Light mode', () async {
      expect(ThemeService.instance.themeMode, ThemeMode.dark);
      await ThemeService.instance.toggleTheme();
      expect(ThemeService.instance.themeMode, ThemeMode.light);
      await ThemeService.instance.toggleTheme();
      expect(ThemeService.instance.themeMode, ThemeMode.dark);
    });
  });

  group('Presentation & Screen Widget Tests', () {
    testWidgets('FieldAI app launches and renders SplashScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const FieldAIApp());
      expect(find.text('FIELD AI'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Welcome to FieldAI'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders in Light and Dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const DashboardScreen(),
        ),
      );

      expect(find.text('FieldAI'), findsOneWidget);
      expect(find.text('Field Worker #104'), findsOneWidget);
      expect(find.text('Field Operations Summary'), findsOneWidget);
      expect(find.text('Analyze Crop Leaf'), findsOneWidget);
      expect(find.text('Ask FieldAI (Agronomic RAG)'), findsOneWidget);
      expect(find.text('Record Field Observation'), findsOneWidget);
    });

    testWidgets('LoginScreen renders properly with sign-in and guest buttons', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );

      expect(find.text('Welcome to FieldAI'), findsOneWidget);
      expect(find.text('Sign In / Work Offline'), findsOneWidget);
      expect(find.text('Continue as Guest (Field Offline)'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders properly with localized form elements', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RegisterScreen(),
        ),
      );

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Join FieldAI Platform'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Organization / Cooperative'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
    });

    testWidgets('FieldGuideScreen renders crop categories and search bar', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const FieldGuideScreen(),
        ),
      );

      expect(find.text('Agronomy Field Guide & Encyclopedia'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Solanaceae'), findsOneWidget);
      expect(find.text('Cereals'), findsOneWidget);
      expect(find.text('Early Blight (Alternaria solani)'), findsOneWidget);
      expect(find.text('Late Blight (Phytophthora infestans)'), findsOneWidget);
    });

    testWidgets('SyncManagerScreen renders server diagnostics and batch sync UI', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SyncManagerScreen(),
        ),
      );

      expect(find.text('Cloud Sync & Queue Manager'), findsOneWidget);
      expect(find.text('Server Connectivity Diagnostics'), findsOneWidget);
      expect(find.text('Ping Cloud Server'), findsOneWidget);
      expect(find.text('Pending Synchronization Queue'), findsOneWidget);
    });

    testWidgets('TreatmentPlanScreen renders multi-phase schedule and dosage calculator', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TreatmentPlanScreen(
            crop: 'Tomato',
            diseaseName: 'Early Blight (Alternaria solani)',
          ),
        ),
      );

      expect(find.text('Treatment & Recovery Schedule'), findsOneWidget);
      expect(find.text('Field Size & Dosage Calculator'), findsOneWidget);
      expect(find.text('Multi-Phase Treatment Schedule'), findsOneWidget);
      expect(find.text('Save Treatment Plan to SQLite'), findsOneWidget);
    });

    testWidgets('TreatmentListScreen renders empty state and action button', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TreatmentListScreen(),
        ),
      );

      expect(find.text('Treatment & Recovery Plans'), findsOneWidget);
    });

    testWidgets('AnalyticsScreen renders regional spore vulnerability and metrics', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Field Analytics & Risk'), findsOneWidget);
      expect(find.text('Outbreak Spore Vulnerability'), findsOneWidget);
      expect(find.text('Export Field Observations & Diagnoses (JSON)'), findsOneWidget);
    });

    testWidgets('ObservationScreen renders GPS field logging form', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ObservationScreen(),
        ),
      );

      expect(find.text('Record Field Observation'), findsOneWidget);
      expect(find.text('GPS Field Coordinates'), findsOneWidget);
      expect(find.text('Save Observation to SQLite'), findsOneWidget);
    });

    testWidgets('AiAssistantScreen renders chat interface and prompt suggestions', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiAssistantScreen(),
        ),
      );

      expect(find.text('Ask FieldAI (Agronomic RAG)'), findsOneWidget);
      expect(find.text('How to manage early blight in tomatoes?'), findsOneWidget);
    });

    testWidgets('AiExplanationScreen renders explainability metrics and lesion spectrum', (WidgetTester tester) async {
      await LanguageService.instance.setLanguage('en');
      final diagnosis = {
        'crop': 'Tomato',
        'condition_name': 'Early Blight (Alternaria solani)',
        'confidence': 92.4,
        'severity': 'Moderate',
        'explanation': 'Concentric target-board rings with yellow halos on lower leaves.',
        'pathogen_info': 'Alternaria solani fungal spores overwintering in soil.',
        'conducive_factors': 'Warm humid climate with overhead irrigation.',
        'recommended_actions': [
          'Prune lower foliage',
          'Apply Copper Hydroxide spray'
        ]
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AiExplanationScreen(prediction: diagnosis),
        ),
      );

      expect(find.text('Agronomic AI Protocol'), findsWidgets);
      expect(find.text('Early Blight (Alternaria solani)'), findsOneWidget);
      expect(find.text('Conducive Weather Microclimate'), findsOneWidget);
      expect(find.text('Start Actionable Treatment Plan'), findsOneWidget);
    });
  });
}
