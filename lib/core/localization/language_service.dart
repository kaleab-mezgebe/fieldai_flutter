import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._init();
  static const String _langPrefKey = 'fieldai_selected_language';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.languageCode;

  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
    {'code': 'am', 'name': 'Amharic', 'nativeName': 'አማርኛ', 'flag': '🇪🇹'},
    {'code': 'ti', 'name': 'Tigrinya', 'nativeName': 'ትግርኛ', 'flag': '🇪🇹'},
    {'code': 'om', 'name': 'Afaan Oromoo', 'nativeName': 'Afaan Oromoo', 'flag': '🇪🇹'},
  ];

  LanguageService._init() {
    _loadLanguageFromPrefs();
  }

  Future<void> _loadLanguageFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_langPrefKey);
      if (savedCode != null && ['en', 'am', 'ti', 'om'].contains(savedCode)) {
        _currentLocale = Locale(savedCode);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    if (!['en', 'am', 'ti', 'om'].contains(code)) return;
    _currentLocale = Locale(code);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langPrefKey, code);
    } catch (_) {}
  }
}
