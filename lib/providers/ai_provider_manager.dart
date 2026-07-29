import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

// AI Provider Configuration
class AIProviderConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final int contextWindow;
  final String formatType; // openai, anthropic, custom

  AIProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.contextWindow,
    this.formatType = 'openai',
  });

  AIProviderConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    int? contextWindow,
    String? formatType,
  }) {
    return AIProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      contextWindow: contextWindow ?? this.contextWindow,
      formatType: formatType ?? this.formatType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      // apiKey intentionally excluded from serialization to non-secure storage.
      'model': model,
      'contextWindow': contextWindow,
      'formatType': formatType,
    };
  }

  factory AIProviderConfig.fromMap(Map<String, dynamic> map) {
    return AIProviderConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      baseUrl: map['baseUrl'] ?? '',
      apiKey: '', // apiKey is loaded separately from secure storage
      model: map['model'] ?? '',
      contextWindow: map['contextWindow'] ?? 4096,
      formatType: map['formatType'] ?? 'openai',
    );
  }

  static AIProviderConfig defaultProvider() {
    return AIProviderConfig(
      id: 'openai_default',
      name: 'OpenAI (default)',
      baseUrl: 'https://api.openai.com',
      apiKey: '',
      model: 'gpt-3.5-turbo',
      contextWindow: 16385,
      formatType: 'openai',
    );
  }

  /// Validate that this provider has all required non-secret fields.
  bool get isValid => id.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
}

class AIProviderManager with ChangeNotifier {
  List<AIProviderConfig> _providers = [];
  AIProviderConfig? _selectedProvider;
  final ConfigService _configService = ConfigService();

  List<AIProviderConfig> get providers => _providers;
  AIProviderConfig? get selectedProvider => _selectedProvider;

  Future<void> loadProviders() async {
    try {
      _providers = await _configService.loadProviders();
      if (_providers.isEmpty) {
        _providers = [AIProviderConfig.defaultProvider()];
      }
      // After loading providers from SharedPreferences (without keys),
      // re-inject apiKey from secure storage for each.
      for (var i = 0; i < _providers.length; i++) {
        final p = _providers[i];
        final storedKey = await _configService.loadApiKey(p.id);
        if (storedKey != null && storedKey.isNotEmpty) {
          _providers[i] = p.copyWith(apiKey: storedKey);
        }
      }

      final savedId = await _configService.getSelectedProviderId();
      _selectedProvider = _providers.firstWhere(
        (p) => p.id == savedId,
        orElse: () => _providers.first,
      );
      notifyListeners();
    } catch (e) {
      _providers = [AIProviderConfig.defaultProvider()];
      _selectedProvider = _providers.first;
      notifyListeners();
    }
  }

  void selectProvider(AIProviderConfig provider) {
    if (_selectedProvider != provider) {
      _selectedProvider = provider;
      unawaited(_configService.saveSelectedProvider(provider.id));
      notifyListeners();
    }
  }

  void addProvider(AIProviderConfig newProvider) {
    _providers.add(newProvider);
    if (_selectedProvider == null) {
      _selectedProvider = newProvider;
      unawaited(_configService.saveSelectedProvider(newProvider.id));
    }
    unawaited(_configService.saveProviders(_providers));
    notifyListeners();
  }

  void updateProvider(AIProviderConfig updatedProvider) {
    final index = _providers.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _providers[index] = updatedProvider;
      if (_selectedProvider?.id == updatedProvider.id) {
        _selectedProvider = updatedProvider;
      }
      unawaited(_configService.saveProviders(_providers));
      // Also persist apiKey to secure storage if present.
      if (updatedProvider.apiKey.isNotEmpty) {
        unawaited(_configService.saveApiKey(updatedProvider.id, updatedProvider.apiKey));
      }
      notifyListeners();
    }
  }

  void removeProvider(String providerId) {
    _providers.removeWhere((p) => p.id == providerId);
    if (_selectedProvider?.id == providerId) {
      _selectedProvider = _providers.isNotEmpty ? _providers.first : null;
    }
    unawaited(_configService.saveSelectedProvider(_selectedProvider?.id));
    unawaited(_configService.saveProviders(_providers));
    // Also delete the secure key for this provider.
    unawaited(_configService.saveApiKey(providerId, ''));
    notifyListeners();
  }

  /// Save (encrypt) the API key to secure storage for the given provider.
  Future<void> saveApiKeyForSelected(String apiKey) async {
    final provider = _selectedProvider;
    if (provider == null) throw Exception('No provider selected');
    await _configService.saveApiKey(provider.id, apiKey);
    _providers[_providers.indexWhere((p) => p.id == provider.id)] =
        provider.copyWith(apiKey: apiKey);
    notifyListeners();
  }

  Future<String> generateHtmlFromPrompt(String prompt) async {
    final provider = _selectedProvider;
    if (provider == null) {
      throw Exception('No provider selected. Please configure a provider in settings.');
    }
    if (provider.apiKey.isEmpty) {
      throw Exception(
        'API key not set for "${provider.name}". Enter it in Provider Settings.',
      );
    }
    if (!provider.isValid) {
      throw Exception('Provider "${provider.name}" is not fully configured.');
    }

    try {
      switch (provider.formatType) {
        case 'openai':
          return await _callOpenAI(provider, prompt);
        case 'anthropic':
          return await _callAnthropic(provider, prompt);
        case 'custom':
          return await _callOpenAI(provider, prompt);
        default:
          return await _callOpenAI(provider, prompt);
      }
    } catch (e) {
      throw Exception('Failed to generate HTML: $e');
    }
  }

  Future<String> _callOpenAI(AIProviderConfig config, String prompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert in generating presentation HTML slides. '
                  'Return ONLY valid HTML fragment (no markdown, no explanation). '
                  'Use <h1> for title, <p> for paragraphs, <ul>/<li> for lists. '
                  'No external CSS/JS references.',
            },
            {'role': 'user', 'content': 'Generate single slide HTML/CSS presentation content for: $prompt'},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<String> _c
