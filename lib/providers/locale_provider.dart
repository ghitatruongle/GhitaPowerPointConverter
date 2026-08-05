import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocaleProvider quản lý ngôn ngữ (English/Vietnamese)
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLoaded = false;

  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;
  bool get isVietnamese => _locale.languageCode == 'vi';

  LocaleProvider() {
    _loadLocale();
  }

  /// Set locale
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _saveLocale();
  }

  /// Toggle giữa English và Vietnamese
  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'vi') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('vi'));
    }
  }

  /// Load locale từ SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_locale');
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
      }
    } catch (_) {
      // Fallback to English
      _locale = const Locale('en');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Save locale vào SharedPreferences
  Future<void> _saveLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', _locale.languageCode);
    } catch (_) {
      // Ignore save errors
    }
  }
}