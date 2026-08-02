import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/enhanced_ai_provider_config.dart';
import '../services/api_key_rotation_service.dart';
import '../services/local_ai_detector_service.dart';
import 'ai_provider_manager.dart';
import 'config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced AI Provider Manager with support for multiple keys and advanced features
class EnhancedAIProviderManager with ChangeNotifier {
  List<EnhancedAIProviderConfig> _providers = [];
  EnhancedAIProviderConfig? _selectedProvider;
  final ConfigService _configService = ConfigService();
  final APIKeyRotationService _rotationService = APIKeyRotationService();
  final LocalAIDetectorService _localDetector = LocalAIDetectorService();

  // Custom system prompt for slide generation
  String _systemPrompt =
      'You are an expert in generating presentation HTML slides. '
      'Return ONLY valid HTML fragment (no markdown, no explanation). '
      'Use <h1> for title, <p> for paragraphs, <ul>/<li> for lists. '
      'No external CSS/JS references.';

  String get systemPrompt => _systemPrompt;

  List<EnhancedAIProviderConfig> get providers => _providers;
  EnhancedAIProviderConfig? get selectedProvider => _selectedProvider;

  // Health monitoring
  final Map<String, ProviderHealthStatus> _providerHealth = {};

  Future<void> loadProviders() async {
    try {
      // Load enhanced providers from secure storage
      _providers = await _loadEnhancedProviders();
      
      if (_providers.isEmpty) {
        // Create default enhanced provider
        _providers = [
          EnhancedAIProviderConfig.fromLegacy(
            AIProviderConfig.defaultProvider(),
            primaryApiKey: await _configService.loadApiKey('openai_default'),
          ),
        ];
      }

      // Load selected provider
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

      // Start health monitoring
      _startHealthMonitoring();

      notifyListeners();
    } catch (e) {
      _providers = [
        EnhancedAIProviderConfig.fromLegacy(
          AIProviderConfig.defaultProvider(),
        ),
      ];
      _selectedProvider = _providers.first;
      notifyListeners();
    }
  }

  Future<List<EnhancedAIProviderConfig>> _loadEnhancedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('enhanced_providers');
    
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        return list
            .map((m) => EnhancedAIProviderConfig.fromMap(
                Map<String, dynamic>.from(m as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error loading enhanced providers: $e');
      }
    }
    
    return [];
  }

  Future<void> _saveProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_providers.map((p) => p.toMap()).toList());
    await prefs.setString('enhanced_providers', jsonStr);
  }

  void updateSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    unawaited(_configService.saveSystemPrompt(prompt));
    notifyListeners();
  }

  void selectProvider(EnhancedAIProviderConfig provider) {
    if (_selectedProvider?.id != provider.id) {
      _selectedProvider = provider;
      unawaited(_configService.saveSelectedProvider(provider.id));
      notifyListeners();
    }
  }

  /// Automatically fetches the list of available models from the provider endpoint
  Future<List<String>> fetchAvailableModels(EnhancedAIProviderConfig config) async {
    try {
      final List<String> fetchedModels = [];
      if (config.formatType == 'gemini') {
        final url = Uri.parse('${config.baseUrl}/v1beta/models?key=${config.getPrimaryKey()?.key ?? ''}');
        final res = await http.get(url).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['models'] is List) {
            for (final m in data['models']) {
              final name = (m['name'] ?? '').toString().replaceAll('models/', '');
              if (name.isNotEmpty) fetchedModels.add(name);
            }
          }
        }
      } else {
        final url = Uri.parse('${config.baseUrl}/v1/models');
        final headers = <String, String>{'Content-Type': 'application/json'};
        final primaryKey = config.getPrimaryKey();
        if (primaryKey != null && primaryKey.key.isNotEmpty) {
          if (config.formatType == 'anthropic') {
            headers['x-api-key'] = primaryKey.key;
            headers['anthropic-version'] = '2023-06-01';
          } else {
            headers['Authorization'] = 'Bearer ${primaryKey.key}';
          }
        }
        final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['data'] is List) {
            for (final m in data['data']) {
              final id = (m['id'] ?? '').toString();
              if (id.isNotEmpty) fetchedModels.add(id);
            }
          }
        }
      }

      if (fetchedModels.isNotEmpty) {
        final updated = config.copyWith(
          availableModels: fetchedModels,
          selectedModel: fetchedModels.contains(config.selectedModel)
              ? config.selectedModel
              : fetchedModels.first,
          status: ProviderStatus.healthy,
          lastChecked: DateTime.now(),
        );
        updateProvider(updated);
        return fetchedModels;
      }
    } catch (e) {
      debugPrint('Error fetching models: $e');
    }
    return config.availableModels;
  }

  void addProvider(EnhancedAIProviderConfig newProvider) {
    _providers.add(newProvider);
    if (_selectedProvider == null) {
      _selectedProvider = newProvider;
      unawaited(_configService.saveSelectedProvider(newProvider.id));
    }
    _saveProviders();
    notifyListeners();
  }

  void updateProvider(EnhancedAIProviderConfig updatedProvider) {
    final index = _providers.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _providers[index] = updatedProvider;
      if (_selectedProvider?.id == updatedProvider.id) {
        _selectedProvider = updatedProvider;
      }
      _saveProviders();
      // Persist API keys to secure storage
      if (updatedProvider.getPrimaryKey()?.key.isNotEmpty ?? false) {
        unawaited(_configService.saveApiKey(updatedProvider.id, updatedProvider.getPrimaryKey()!.key));
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
    _saveProviders();
    // Also delete the secure key for this provider.
    unawaited(_configService.saveApiKey(providerId, ''));
    notifyListeners();
  }

  /// Test provider connection and update health status
  Future<void> testProviderPing(EnhancedAIProviderConfig config) async {
    try {
      final primaryKey = config.getPrimaryKey();
      if (primaryKey == null || primaryKey.key.isEmpty) {
        throw Exception('No API key available for testing');
      }

      final isValid = await _rotationService.testAPIKey(
        config.baseUrl,
        primaryKey.key,
        config.id,
      );

      final status = isValid ? ProviderStatus.healthy : ProviderStatus.failed;
      final updated = config.copyWith(
        status: status,
        lastChecked: DateTime.now(),
      );

      updateProvider(updated);

      // Record health status
      _providerHealth[config.id] = ProviderHealthStatus(
        isReachable: isValid,
        lastChecked: DateTime.now(),
        latencyMs: 0, // Would need to measure actual latency
      );
    } catch (e) {
      debugPrint('Error testing provider ping: $e');
      final updated = config.copyWith(
        status: ProviderStatus.failed,
        lastChecked: DateTime.now(),
      );
      updateProvider(updated);
    }
  }

  /// Scan for local AI services
  Future<List<LocalAIServiceInfo>> scanLocalAI() async {
    return await _localDetector.scanLocalAIServices();
  }

  /// Get health status for a provider
  ProviderHealthStatus? getProviderHealth(String providerId) {
    return _providerHealth[providerId];
  }

  /// Start periodic health monitoring
  void _startHealthMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _performHealthChecks();
      } else {
        timer.cancel();
      }
    });
  }

  /// Perform health checks for all providers
  Future<void> _performHealthChecks() async {
    for (final provider in _providers) {
      await testProviderPing(provider);
    }
  }

  /// Get models for a provider
  Future<List<String>> getModels(EnhancedAIProviderConfig config) async {
    return await fetchAvailableModels(config);
  }

  /// Get provider configuration
  Future<EnhancedAIProviderConfig?> getProviderConfig(String providerId) async {
    try {
      return _providers.firstWhere((p) => p.id == providerId);
    } catch (e) {
      return null;
    }
  }

  /// Generate HTML for a single slide (compatibility layer)
  Future<String> generateHtmlFromPrompt(String prompt) async {
    final provider = _ensureReady();
    
    try {
      switch (provider.formatType) {
        case 'openai':
          return await _callOpenAI(provider, prompt);
        case 'anthropic':
          return await _callAnthropic(provider, prompt);
        case 'gemini':
          return await _callGemini(provider, prompt, _systemPrompt);
        case 'custom':
          return await _callOpenAI(provider, prompt);
        default:
          return await _callOpenAI(provider, prompt);
      }
    } catch (e) {
      throw Exception('Failed to generate HTML: $e');
    }
  }

  /// Ensure provider is ready for use
  EnhancedAIProviderConfig _ensureReady() {
    final provider = _selectedProvider;
    if (provider == null) {
      throw Exception('No provider selected. Please configure a provider in settings.');
    }
    if (provider.getPrimaryKey() == null || 
        !provider.getPrimaryKey()!.key.isNotEmpty) {
      throw Exception('API key not set for "${provider.name}". Enter it in Provider Settings.');
    }
    if (!provider.isValid) {
      throw Exception('Provider "${provider.name}" is not fully configured.');
    }
    return provider;
  }

  // ===== OpenAI, Anthropic, Gemini call implementations (simplified) =====

  Future<String> _callOpenAI(EnhancedAIProviderConfig config, String prompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.getPrimaryKey()?.key ?? ''}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.selectedModel,
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
        throw Exception(_getFriendlyErrorMessage(response.statusCode, response.body));
      }
    } finally {
      client.close();
    }
  }

  Future<String> _callAnthropic(EnhancedAIProviderConfig config, String prompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.getPrimaryKey()?.key ?? '',
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.selectedModel,
          'max_tokens': config.maxTokens,
          'system': _systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate single slide HTML presentation content for: $prompt',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] ?? '';
      } else {
        throw Exception(_getFriendlyErrorMessage(response.statusCode, response.body));
      }
    } finally {
      client.close();
    }
  }

  Future<String> _callGemini(EnhancedAIProviderConfig config, String userText, String systemPrompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('${config.baseUrl}/v1beta/models/${config.selectedModel}:generateContent'),
        headers: {
          'x-goog-api-key': config.getPrimaryKey()?.key ?? '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_geminiBody(config, userText, systemPrompt)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini returned no candidates.');
        }
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts == null || parts.isEmpty) return '';
        return parts[0]['text'] ?? '';
      } else {
        throw Exception(_getFriendlyErrorMessage(response.statusCode, response.body));
      }
    } finally {
      client.close();
    }
  }

  // ===== Helper methods =====

  static String _getFriendlyErrorMessage(int statusCode, String body) {
    // Same implementation as in AIProviderManager
    switch (statusCode) {
      case 400:
        return 'Invalid request. Check your prompt and try again.';
      case 401:
        return 'API key invalid or expired. Please check your settings.';
      case 403:
        return 'Access denied. Check your API key permissions.';
      case 404:
        return 'API endpoint not found. Check the Base URL in settings.';
      case 429:
        return 'Rate limit exceeded. Please wait a moment and try again.';
      case 500:
        return 'Server error. The AI service may be temporarily unavailable.';
      case 502:
        return 'Bad gateway. The service is temporarily unavailable.';
      case 503:
        return 'Service temporarily overloaded. Please try again later.';
      default:
        if (statusCode >= 500) {
          return 'Server error ($statusCode). Please try again later.';
        }
        return 'API Error $statusCode: ${body.length > 100 ? '${body.substring(0, 100)}...' : body}';
    }
  }

  static Map<String, dynamic> _geminiBody(
      EnhancedAIProviderConfig config, String userText, String systemPrompt) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userText}
          ]
        }
      ],
      'generationConfig': {
        'temperature': config.temperature,
        'maxOutputTokens': config.maxTokens,
      },
    };
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  bool get mounted => true; // For health monitoring timer
}

// Health status classes
class ProviderHealthStatus {
  final bool isReachable;
  final DateTime lastChecked;
  final int? latencyMs;

  ProviderHealthStatus({
    required this.isReachable,
    required this.lastChecked,
    this.latencyMs,
  });
}

class APIFallbackCascadeService {
  Future<PingResult> testProviderPing(EnhancedAIProviderConfig config) async {
    // Implementation would test the provider connection
    return PingResult(isSuccess: true, latencyMs: 0);
  }
}

class PingResult {
  final bool isSuccess;
  final int latencyMs;

  PingResult({required this.isSuccess, required this.latencyMs});
}