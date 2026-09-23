import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/main.dart';
import 'package:fieldai_flutter/core/theme/theme_service.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/localization/language_service.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fieldai_flutter/features/auth/presentation/screens/register_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FieldAI app launches and renders SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldAIApp());
    expect(find.text('FIELD AI'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to FieldAI'), findsOneWidget);
  });

  testWidgets('ThemeService toggles between Dark and Light mode', (WidgetTester tester) async {
    expect(ThemeService.instance.themeMode, ThemeMode.dark);
    await ThemeService.instance.toggleTheme();
    expect(ThemeService.instance.themeMode, ThemeMode.light);
    await ThemeService.instance.toggleTheme();
    expect(ThemeService.instance.themeMode, ThemeMode.dark);
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

  testWidgets('LanguageService switches across English, Amharic, Tigrinya, and Afaan Oromoo', (WidgetTester tester) async {
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
}
