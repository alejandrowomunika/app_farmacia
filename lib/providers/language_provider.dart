import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'es';
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  bool get isSpanish => _currentLanguage == 'es';

  // Lista de idiomas disponibles
  static const Map<String, LanguageInfo> availableLanguages = {
    'es': LanguageInfo('Español', '🇪🇸', 'es'),
    'en': LanguageInfo('English', '🇬🇧', 'en'),
    'fr': LanguageInfo('Français', '🇫🇷', 'fr'),
    'de': LanguageInfo('Deutsch', '🇩🇪', 'de'),
    'pt': LanguageInfo('Português', '🇵🇹', 'pt'),
  };

  LanguageInfo get currentLanguageInfo =>
      availableLanguages[_currentLanguage] ?? availableLanguages['es']!;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'es';
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);

      // Limpiar cache de traducciones para forzar nuevas traducciones
      TranslationCache.clear();

      notifyListeners();
    }
  }
}

class LanguageInfo {
  final String name;
  final String flag;
  final String code;

  const LanguageInfo(this.name, this.flag, this.code);
}

// Cache global de traducciones
class TranslationCache {
  static final Map<String, String> _cache = {};

  static String? get(String key) => _cache[key];

  static void set(String key, String value) => _cache[key] = value;

  static bool contains(String key) => _cache.containsKey(key);

  static void clear() => _cache.clear();
}
