import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider_manager.dart';

class ConfigService {
  static const String _providersKey = 'ai_providers_config';
  static const String _selectedProviderKey = 'selected_ai_provider_id';
  static const String _slidesKey = 'presentation_slides_config';
  static const String _effectKey = 'presentation_slide_effect';
  static const String _autoAdvanceKey = 'presentation_auto_advance';
  static const String _autoAdvanceSecondsKey = 'presentation_auto_advance_seconds';

  // Secure storage only for secrets (API keys).
  // Non-secret preferences remain in SharedPreferences.
  static const _secureStorage = FlutterSecureStorage();

  // ---- Providers (non-secret config stored in SharedPreferences) ----

  Future<void> saveProviders(List<AIProviderConfig> providers) async {
    final prefs = await SharedPreferences.getInstance();
    // Strip apiKey before writing to SharedPreferences — keys go to secure storage.
    final sanitized = providers.map((p) => p.copyWith(apiKey: '')).toList();
    await prefs.setString(_providersKey, jsonEncode(sanitized.map((p) => p.toMap()).toList()));
  }

  Future<List<AIProviderConfig>> loadProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_providersKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final loaded = list.map((m) => AIProviderConfig.fromMap(Map<String, dynamic>.from(m as Map))).toList();
        // Re-inject apiKey from secure storage for each provider if available.
        for (final p in loaded) {
          final storedKey = await _secureStorage.read(key: _secureKeyFor(p.id));
          if (storedKey != null && storedKey.isNotEmpty) {
            final idx = loaded.indexOf(p);
            loaded[idx] = p.copyWith(apiKey: storedKey);
          }
        }
        return loaded;
      } catch (e) {
        debugPrint('Error loading providers: $e');
      }
    }
    return [AIProviderConfig.defaultProvider()];
  }

  // ---- API Key secure storage ----

  static String _secureKeyFor(String providerId) => 'api_key_$providerId';

  Future<void> saveApiKey(String providerId, String apiKey) async {
    if (apiKey.isEmpty) {
      await _secureStorage.delete(key: _secureKeyFor(providerId));
    } else {
      await _secureStorage.write(key: _secureKeyFor(providerId), value: apiKey);
    }
  }

  Future<String?> loadApiKey(String providerId) async {
    return await _secureStorage.read(key: _secureKeyFor(providerId));
  }

  // ---- Selected provider (non-secret) ----

  Future<void> saveSelectedProvider(String? providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, providerId ?? '');
  }

  Future<String?> getSelectedProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProviderKey);
  }

  // ---- Slides & theme (non-secret) ----

  Future<void> saveSlides(List<Map<String, dynamic>> slides, String effectName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slidesKey, jsonEncode(slides));
    await prefs.setString(_effectKey, effectName);
  }

  Future<Map<String, dynamic>> loadSlides() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_slidesKey);
    final effectName = prefs.getString(_effectKey) ?? 'none';
    List<Map<String, dynamic>> slides = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        slides = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        debugPrint('Error loading slides: $e');
      }
    }
    return {'slides': slides, 'slide_effect': effectName};
  }

  // ---- Auto advance ("Timing") ----

  Future<void> saveAutoAdvance(bool enabled, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoAdvanceKey, enabled);
    await prefs.setInt(_autoAdvanceSecondsKey, seconds.clamp(1, 60));
  }

  /// Returns [enabled] and per-slide [seconds] for automatic slide advance.
  Future<({bool enabled, int seconds})> loadAutoAdvance() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoAdvanceKey) ?? false;
    final seconds = (prefs.getInt(_autoAdvanceSecondsKey) ?? 5).clamp(1, 60);
    return (enabled: enabled, seconds: seconds);
  }

  // ---- System prompt ----

  static const String _systemPromptKey = 'ai_system_prompt';

  Future<void> saveSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_systemPromptKey, prompt);
  }

  Future<String?> loadSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_systemPromptKey);
  }
}
