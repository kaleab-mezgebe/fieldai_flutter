import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FieldAIApp());
}

class FieldAIApp extends StatelessWidget {
  const FieldAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
