import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/core/constants/app_constants.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/theme/theme_service.dart';
import 'package:fieldai_flutter/core/localization/language_service.dart';
import 'package:fieldai_flutter/core/localization/app_strings.dart';
import 'package:fieldai_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fieldai_flutter/features/auth/presentation/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'worker@fieldai.org');
  final _passwordController = TextEditingController(text: 'fieldpass2026');
  bool _isLoading = false;
  String? _errorMessage;

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('select_language'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...LanguageService.instance.supportedLanguages.map((lang) {
                final isSelected = LanguageService.instance.languageCode == lang['code'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : context.cardBorder,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['nativeName']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppTheme.primaryGreen : context.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      lang['name']!,
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                        : null,
                    onTap: () {
                      LanguageService.instance.setLanguage(lang['code']!);
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyAuthToken, response.data['access_token']);
        await prefs.setString(AppConstants.keyUserData, response.data['full_name'] ?? 'Field Worker');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      // Offline fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, 'offline-token-demo');
      await prefs.setString(AppConstants.keyUserData, 'Field Worker #104');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operating in Offline Field Mode. Local SQLite active.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // Language Selector Button
              IconButton(
                icon: const Icon(Icons.language_rounded, color: AppTheme.infoBlue),
                tooltip: 'Language / ቋንቋ / Afaan',
                onPressed: _showLanguageSheet,
              ),
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.warningAmber,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => ThemeService.instance.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppTheme.primaryGreen,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('welcome_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('welcome_sub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: context.textMuted),
                    ),
                    const SizedBox(height: 36),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.dangerRed),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.dangerRed)),
                      ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(context.tr('sign_in')),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: context.textMuted)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            context.tr('create_account'),
                            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _handleLogin();
                      },
                      child: Text(
                        context.tr('guest_mode'),
                        style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
