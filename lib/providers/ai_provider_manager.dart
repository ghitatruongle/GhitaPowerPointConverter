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
  final double temperature;
  final int maxTokens;

  AIProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.contextWindow,
    this.formatType = 'openai',
    this.temperature = 0.7,
    this.maxTokens = 4096,
  });

  AIProviderConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    int? contextWindow,
    String? formatType,
    double? temperature,
    int? maxTokens,
  }) {
    return AIProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      contextWindow: contextWindow ?? this.contextWindow,
      formatType: formatType ?? this.formatType,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
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
      'temperature': temperature,
      'maxTokens': maxTokens,
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
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: map['maxTokens'] as int? ?? 4096,
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
      temperature: 0.7,
      maxTokens: 4096,
    );
  }

  /// Validate that this provider has all required non-secret fields.
  bool get isValid => id.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
}

class AIProviderManager with ChangeNotifier {
  List<AIProviderConfig> _providers = [];
  AIProviderConfig? _selectedProvider;
  final ConfigService _configService = ConfigService();

  // Custom system prompt for slide generation
  String _systemPrompt =
      'You are an expert in generating presentation HTML slides. '
      'Return ONLY valid HTML fragment (no markdown, no explanation). '
      'Use <h1> for title, <p> for paragraphs, <ul>/<li> for lists. '
      'No external CSS/JS references.';

  String get systemPrompt => _systemPrompt;

  List<AIProviderConfig> get providers => _providers;
  AIProviderConfig? get selectedProvider => _selectedProvider;

  Future<void> loadProviders() async {
    try {
      _providers = await _configService.loadProviders();
      if (_providers.isEmpty) {
        _providers = [AIProviderConfig.defaultProvider()];
      }
      // Re-inject apiKey from secure storage for each.
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

      // Load custom system prompt
      final savedPrompt = await _configService.loadSystemPrompt();
      if (savedPrompt != null && savedPrompt.isNotEmpty) {
        _systemPrompt = savedPrompt;
      }

      notifyListeners();
    } catch (e) {
      _providers = [AIProviderConfig.defaultProvider()];
      _selectedProvider = _providers.first;
      notifyListeners();
    }
  }

  void updateSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    unawaited(_configService.saveSystemPrompt(prompt));
    notifyListeners();
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

  // ---- Single slide generation ----

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

  // ---- Multi-slide generation ----

  /// Generate multiple slides from a single prompt.
  /// Returns a list of slide maps with 'title' and 'htmlContent' keys.
  Future<List<Map<String, String>>> generateMultipleSlides(String topic, {int slideCount = 3}) async {
    final provider = _selectedProvider;
    if (provider == null) {
      throw Exception('No provider selected.');
    }
    if (provider.apiKey.isEmpty) {
      throw Exception('API key not set for "${provider.name}".');
    }
    if (!provider.isValid) {
      throw Exception('Provider "${provider.name}" is not fully configured.');
    }

    final multiSlideSystemPrompt = '$_systemPrompt\n'
        'Return a JSON array of slide objects. Each object must have:\n'
        '  - "title": slide title (string)\n'
        '  - "html": HTML content for the slide body (string)\n'
        'Return ONLY valid JSON. No markdown, no extra text.\n'
        'Generate exactly $slideCount slides for the topic.';

    try {
      final result = switch (provider.formatType) {
        'openai' || 'custom' => await _callOpenAIMulti(provider, topic, multiSlideSystemPrompt),
        'anthropic' => await _callAnthropicMulti(provider, topic, multiSlideSystemPrompt),
        _ => await _callOpenAIMulti(provider, topic, multiSlideSystemPrompt),
      };
      return _parseSlideJson(result, slideCount);
    } catch (e) {
      throw Exception('Failed to generate slides: $e');
    }
  }

  List<Map<String, String>> _parseSlideJson(String raw, int expectedCount) {
    // Try to extract JSON array from the response
    final jsonStr = _extractJsonArray(raw);
    if (jsonStr == null) {
      // Fallback: treat entire response as a single slide
      return [
        {'title': 'Generated Slide', 'htmlContent': raw},
      ];
    }

    try {
      final List<dynamic> slides = jsonDecode(jsonStr);
      return slides.map((s) {
        final map = s as Map<String, dynamic>;
        return {
          'title': (map['title'] ?? 'Slide').toString(),
          'htmlContent': (map['html'] ?? map['htmlContent'] ?? map['content'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      // JSON parsing failed — return single slide fallback
      return [
        {'title': 'Generated Slide', 'htmlContent': raw},
      ];
    }
  }

  /// Extract a JSON array from text that may contain markdown fences or extra text.
  String? _extractJsonArray(String text) {
    // Try to find content between ```json and ``` markers
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)?.trim();
    }
    // Try to find content between [ and ]
    final bracketMatch = RegExp(r'(\[[\s\S]*?\])').firstMatch(text);
    if (bracketMatch != null) {
      return bracketMatch.group(1);
    }
    return null;
  }

  // ---- OpenAI calls ----

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
            {'role': 'system', 'content': _systemPrompt},
            {
              'role': 'user',
              'content':
                  'Generate single slide HTML presentation content for: $prompt',
            },
          ],
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
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

  Future<String> _callOpenAIMulti(
      AIProviderConfig config, String topic, String systemPrompt) async {
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
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': topic},
          ],
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
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

  // ---- Anthropic calls ----

  Future<String> _callAnthropic(AIProviderConfig config, String prompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model,
          'max_tokens': config.maxTokens,
          'system': _systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate presentation HTML slide content for: $prompt',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] ?? '';
      } else {
        throw Exception('Anthropic API Error ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<String> _callAnthropicMulti(
      AIProviderConfig config, String topic, String systemPrompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model,
          'max_tokens': config.maxTokens,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': topic},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] ?? '';
      } else {
        throw Exception('Anthropic API Error ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }
}
