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
      'apiKey': apiKey,
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
      apiKey: map['apiKey'] ?? '',
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
      apiKey: '', // User needs to enter this
      model: 'gpt-3.5-turbo',
      contextWindow: 16385,
      formatType: 'openai',
    );
  }
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
      _configService.saveSelectedProvider(provider.id);
      notifyListeners();
    }
  }

  void addProvider(AIProviderConfig newProvider) {
    _providers.add(newProvider);
    if (_selectedProvider == null) {
      _selectedProvider = newProvider;
      _configService.saveSelectedProvider(newProvider.id);
    }
    _configService.saveProviders(_providers);
    notifyListeners();
  }

  void updateProvider(AIProviderConfig updatedProvider) {
    final index = _providers.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _providers[index] = updatedProvider;
      if (_selectedProvider?.id == updatedProvider.id) {
        _selectedProvider = updatedProvider;
      }
      _configService.saveProviders(_providers);
      notifyListeners();
    }
  }

  void removeProvider(String providerId) {
    _providers.removeWhere((p) => p.id == providerId);
    if (_selectedProvider?.id == providerId) {
      _selectedProvider = _providers.isNotEmpty ? _providers.first : null;
      _configService.saveSelectedProvider(_selectedProvider?.id);
    }
    _configService.saveProviders(_providers);
    notifyListeners();
  }

  Future<String> generateHtmlFromPrompt(String prompt) async {
    if (_selectedProvider == null || _selectedProvider!.apiKey.isEmpty) {
      throw Exception('API key not configured for selected provider. Please enter an API key in settings.');
    }

    try {
      switch (_selectedProvider!.formatType) {
        case 'openai':
          return await _callOpenAI(_selectedProvider!, prompt);
        case 'anthropic':
          return await _callAnthropic(_selectedProvider!, prompt);
        case 'custom':
          return await _callCustom(_selectedProvider!, prompt);
        default:
          return await _callOpenAI(_selectedProvider!, prompt);
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
            {'role': 'system', 'content': 'You are an expert in generating presentation HTML slides.'},
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
          'max_tokens': 4000,
          'messages': [
            {'role': 'user', 'content': 'Generate single slide HTML/CSS presentation content for: $prompt'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content']?[0]?['text'] ?? '';
      } else {
        throw Exception('Anthropic API Error ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  Future<String> _callCustom(AIProviderConfig config, String prompt) async {
    return _callOpenAI(config, prompt);
  }

  String toJson() {
    return jsonEncode(_providers.map((p) => p.toMap()).toList());
  }

  void fromJson(String jsonStr) {
    try {
      final List<dynamic> list = json.decode(jsonStr);
      _providers = list.map((m) => AIProviderConfig.fromMap(m)).toList();
      if (_providers.isNotEmpty && _selectedProvider == null) {
        _selectedProvider = _providers.first;
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid JSON format');
    }
  }
}

