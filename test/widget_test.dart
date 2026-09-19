import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/main.dart';

void main() {
  testWidgets('FieldAI app launches and renders SplashScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FieldAIApp());
    expect(find.text('FIELD AI'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to FieldAI'), findsOneWidget);
  });
}
