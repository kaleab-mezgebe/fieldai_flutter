import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/main.dart';
import 'package:fieldai_flutter/core/theme/theme_service.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';

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
}
