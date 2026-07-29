import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider_manager.dart';

class ConfigService {
  static const String _providersKey = 'ai_providers_config';
  static const String _selectedProviderKey = 'selected_ai_provider_id';
  static const String _slidesKey = 'presentation_slides_config';
  static const String _effectKey = 'presentation_slide_effect';

  // Secure storage only for secrets (API keys).
  // Non-secret preferences remain in SharedPreferences.
  static final _secureStorage = const FlutterSecureStorage();

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
        final loaded = list.map((m) => AIProviderConfig.fromMap(m as Map)).toList();
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
        print('Error loading providers: $e');
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
        print('Error loading slides: $e');
      }
    }
    return {'slides': slides, 'slide_effect': effectName};
  }
}
