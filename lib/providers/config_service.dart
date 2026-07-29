import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider_manager.dart';

class ConfigService {
  static const String _providersKey = 'ai_providers_config';
  static const String _selectedProviderKey = 'selected_ai_provider_id';
  static const String _slidesKey = 'presentation_slides_config';
  static const String _themeKey = 'presentation_theme_config';

  Future<void> saveProviders(List<AIProviderConfig> providers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(providers.map((p) => p.toMap()).toList());
    await prefs.setString(_providersKey, jsonStr);
  }

  Future<List<AIProviderConfig>> loadProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_providersKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((m) => AIProviderConfig.fromMap(m)).toList();
      } catch (e) {
        print('Error loading providers: $e');
      }
    }
    return [AIProviderConfig.defaultProvider()];
  }

  Future<void> saveSelectedProvider(String? providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, providerId ?? '');
  }

  Future<String?> getSelectedProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProviderKey);
  }

  Future<void> saveSlides(List<Map<String, dynamic>> slides, String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slidesKey, jsonEncode(slides));
    await prefs.setString(_themeKey, theme);
  }

  Future<Map<String, dynamic>> loadSlides() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_slidesKey);
    final theme = prefs.getString(_themeKey) ?? 'default';
    List<Map<String, dynamic>> slides = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        slides = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error loading slides: $e');
      }
    }
    return {'slides': slides, 'theme': theme};
  }
}

