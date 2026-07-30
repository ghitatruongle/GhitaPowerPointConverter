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
  final List<String> availableModels;
  final String selectedModel;
  final int contextWindow;
  final String formatType; // openai, anthropic, gemini, custom
  final double temperature;
  final int maxTokens;

  AIProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.availableModels,
    required this.selectedModel,
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
    List<String>? availableModels,
    String? selectedModel,
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
      availableModels: availableModels ?? this.availableModels,
      selectedModel: selectedModel ?? this.selectedModel,
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
      'availableModels': availableModels,
      'selectedModel': selectedModel,
      'contextWindow': contextWindow,
      'formatType': formatType,
      'temperature': temperature,
      'maxTokens': maxTokens,
    };
  }

  factory AIProviderConfig.fromMap(Map<String, dynamic> map) {
    final modelsList = (map['availableModels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return AIProviderConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      baseUrl: map['baseUrl'] ?? '',
      apiKey: '', // apiKey is loaded separately from secure storage
      availableModels: modelsList.isNotEmpty ? modelsList : [map['model'] ?? ''],
      selectedModel: map['selectedModel'] ??
          (modelsList.isNotEmpty ? modelsList.first : (map['model'] ?? '')),
      contextWindow: map['contextWindow'] ?? 4096,
      formatType: map['formatType'] ?? 'openai',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: map['maxTokens'] as int? ?? 4096,
    );
  }

  static AIProviderConfig defaultProvider() {
    return AIProviderConfig(
      id: 'openai_default',
      name: 'OpenAI (GPT-4o / GPT-3.5)',
      baseUrl: 'https://api.openai.com',
      apiKey: '',
      availableModels: [
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-3.5-turbo',
        'o1-preview',
      ],
      selectedModel: 'gpt-4o',
      contextWindow: 128000,
      formatType: 'openai',
      temperature: 0.7,
      maxTokens: 4096,
    );
  }

  static AIProviderConfig anthropicDefault() {
    return AIProviderConfig(
      id: 'anthropic_default',
      name: 'Anthropic (Claude)',
      baseUrl: 'https://api.anthropic.com',
      apiKey: '',
      availableModels: [
        'claude-3-5-sonnet-20240620',
        'claude-3-opus-20240229',
        'claude-3-haiku-20240307',
      ],
      selectedModel: 'claude-3-5-sonnet-20240620',
      contextWindow: 200000,
      formatType: 'anthropic',
      temperature: 0.7,
      maxTokens: 4096,
    );
  }

  static AIProviderConfig geminiDefault() {
    return AIProviderConfig(
      id: 'gemini_default',
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com',
      apiKey: '',
      availableModels: [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
      ],
      selectedModel: 'gemini-2.5-flash',
      contextWindow: 1000000,
      formatType: 'gemini',
      temperature: 0.7,
      maxTokens: 8192,
    );
  }

  static AIProviderConfig ollamaDefault() {
    return AIProviderConfig(
      id: 'ollama_default',
      name: 'Ollama (Local)',
      baseUrl: 'http://localhost:11434/v1',
      apiKey: '',
      availableModels: [
        'llama3.1',
        'mistral',
        'qwen2.5',
      ],
      selectedModel: 'llama3.1',
      contextWindow: 32768,
      formatType: 'openai',
      temperature: 0.7,
      maxTokens: 4096,
    );
  }

  /// Whether this provider needs an API key (local endpoints don't).
  bool get requiresApiKey {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host != 'localhost' && host != '127.0.0.1' && host != '0.0.0.0';
  }

  /// Validate that this provider has all required non-secret fields.
  bool get isValid => id.isNotEmpty && baseUrl.isNotEmpty && selectedModel.isNotEmpty;

  /// Convenience getter for backward compatibility in a few places.
  String get model => selectedModel;
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

  // ---- Error handling helpers ----

  /// Classify HTTP error into a user-friendly message.
  static String _friendlyErrorMessage(int statusCode, String body) {
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

  /// Validate provider config and return an error message, or null if valid.
  static String? validateProvider(AIProviderConfig provider) {
    if (provider.id.trim().isEmpty) {
      return 'Provider ID cannot be empty.';
    }
    if (provider.name.trim().isEmpty) {
      return 'Provider name cannot be empty.';
    }
    if (provider.baseUrl.trim().isEmpty) {
      return 'Base URL cannot be empty.';
    }
    final uri = Uri.tryParse(provider.baseUrl.trim());
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      return 'Base URL is not a valid URL (must start with http:// or https://).';
    }
    if (provider.availableModels.isEmpty) {
      return 'Provider must have at least 1 model configured.';
    }
    if (provider.selectedModel.isEmpty) {
      return 'No model selected. Please choose an active model.';
    }
    if (provider.contextWindow <= 0) {
      return 'Context window must be a positive number.';
    }
    if (provider.temperature < 0 || provider.temperature > 2) {
      return 'Temperature must be between 0.0 and 2.0.';
    }
    if (provider.maxTokens <= 0) {
      return 'Max tokens must be a positive number.';
    }
    return null;
  }

  // ---- Single slide generation ----

  /// Validate the selected provider is ready for a call; returns it.
  AIProviderConfig _ensureReady() {
    final provider = _selectedProvider;
    if (provider == null) {
      throw Exception('No provider selected. Please configure a provider in settings.');
    }
    if (provider.apiKey.isEmpty && provider.requiresApiKey) {
      throw Exception(
        'API key not set for "${provider.name}". Enter it in Provider Settings.',
      );
    }
    if (!provider.isValid) {
      throw Exception('Provider "${provider.name}" is not fully configured.');
    }
    return provider;
  }

  Future<String> generateHtmlFromPrompt(String prompt) async {
    final provider = _ensureReady();

    try {
      switch (provider.formatType) {
        case 'openai':
          return await _callOpenAI(provider, prompt);
        case 'anthropic':
          return await _callAnthropic(provider, prompt);
        case 'gemini':
          return await _callGemini(provider,
              'Generate single slide HTML presentation content for: $prompt', _systemPrompt);
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
    final provider = _ensureReady();

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
        'gemini' => await _callGemini(provider, topic, multiSlideSystemPrompt),
        _ => await _callOpenAIMulti(provider, topic, multiSlideSystemPrompt),
      };
      return _parseSlideJson(result, slideCount);
    } catch (e) {
      throw Exception('Failed to generate slides: $e');
    }
  }

  // ---- Outline mode ----

  /// Generate a presentation outline: list of {title, bullets} entries.
  Future<List<Map<String, dynamic>>> generateOutline(String topic,
      {int slideCount = 5}) async {
    final provider = _ensureReady();

    final outlinePrompt =
        'You are a presentation planner. Create an outline for a presentation.\n'
        'Return ONLY a valid JSON array with exactly $slideCount objects. Each object has:\n'
        '  - "title": slide title (string)\n'
        '  - "bullets": array of 2-4 short bullet point strings\n'
        'No markdown, no extra text.';

    final raw = switch (provider.formatType) {
      'openai' || 'custom' => await _callOpenAIMulti(provider, topic, outlinePrompt),
      'anthropic' => await _callAnthropicMulti(provider, topic, outlinePrompt),
      'gemini' => await _callGemini(provider, topic, outlinePrompt),
      _ => await _callOpenAIMulti(provider, topic, outlinePrompt),
    };
    return parseOutlineJson(raw);
  }

  /// Parse outline JSON (public for unit testing).
  static List<Map<String, dynamic>> parseOutlineJson(String raw) {
    final jsonStr = _extractJsonArrayStatic(raw) ?? raw;
    try {
      final List<dynamic> entries = jsonDecode(jsonStr);
      return entries
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'title': (e['title'] ?? 'Untitled').toString(),
                'bullets': ((e['bullets'] as List?) ?? const [])
                    .map((b) => b.toString())
                    .toList(),
              })
          .toList();
    } catch (_) {
      throw Exception('Could not parse outline from AI response.');
    }
  }

  /// Generate the HTML for a single slide from an outline entry.
  Future<String> generateSlideFromOutline(
      String topic, Map<String, dynamic> outlineEntry) async {
    final title = (outlineEntry['title'] ?? '').toString();
    final bullets =
        ((outlineEntry['bullets'] as List?) ?? const []).join('; ');
    final prompt =
        'Topic: $topic. Create the slide titled "$title" covering: $bullets';
    return generateHtmlFromPrompt(prompt);
  }

  // ---- Streaming generation ----

  http.Client? _streamClient;
  bool _streamCancelled = false;

  /// Cancel an in-flight streaming request, if any.
  void cancelStream() {
    _streamCancelled = true;
    _streamClient?.close();
    _streamClient = null;
  }

  /// Generate HTML for a single slide, streaming text chunks as they arrive.
  Stream<String> generateHtmlFromPromptStream(String prompt) async* {
    final provider = _ensureReady();
    final client = http.Client();
    _streamClient = client;
    _streamCancelled = false;

    try {
      final http.Request request;
      switch (provider.formatType) {
        case 'anthropic':
          request = http.Request(
              'POST', Uri.parse('${provider.baseUrl}/v1/messages'))
            ..headers.addAll({
              'x-api-key': provider.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode({
              'model': provider.selectedModel,
              'max_tokens': provider.maxTokens,
              'system': _systemPrompt,
              'stream': true,
              'messages': [
                {
                  'role': 'user',
                  'content':
                      'Generate presentation HTML slide content for: $prompt',
                },
              ],
            });
          break;
        case 'gemini':
          request = http.Request(
              'POST',
              Uri.parse(
                  '${provider.baseUrl}/v1beta/models/${provider.selectedModel}:streamGenerateContent?alt=sse'))
            ..headers.addAll({
              'x-goog-api-key': provider.apiKey,
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode(_geminiBody(provider,
                'Generate single slide HTML presentation content for: $prompt', _systemPrompt));
          break;
        default: // openai / custom
          request = http.Request(
              'POST', Uri.parse('${provider.baseUrl}/v1/chat/completions'))
            ..headers.addAll({
              'Authorization': 'Bearer ${provider.apiKey}',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode({
              'model': provider.selectedModel,
              'stream': true,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {
                  'role': 'user',
                  'content':
                      'Generate single slide HTML presentation content for: $prompt',
                },
              ],
              'temperature': provider.temperature,
              'max_tokens': provider.maxTokens,
            });
      }

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception(_friendlyErrorMessage(response.statusCode, body));
      }

      // Parse SSE lines across chunk boundaries.
      var buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete tail
        for (final line in lines) {
          final delta = parseStreamLine(provider.formatType, line);
          if (delta != null && delta.isNotEmpty) yield delta;
        }
      }
      final delta = parseStreamLine(provider.formatType, buffer);
      if (delta != null && delta.isNotEmpty) yield delta;
    } on http.ClientException {
      // ClientException also wraps genuine network failures (connection
      // refused, reset mid-stream) — only swallow it for an explicit cancel.
      if (!_streamCancelled) rethrow;
    } finally {
      if (identical(_streamClient, client)) _streamClient = null;
      client.close();
    }
  }

  /// Parse a single SSE line into a text delta (public for unit testing).
  /// Returns null when the line carries no text.
  static String? parseStreamLine(String formatType, String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return null;
    final payload = trimmed.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') return null;
    try {
      final data = jsonDecode(payload);
      switch (formatType) {
        case 'anthropic':
          if (data['type'] == 'content_block_delta') {
            return data['delta']?['text'] as String?;
          }
          return null;
        case 'gemini':
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) return null;
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts == null || parts.isEmpty) return null;
          return parts[0]['text'] as String?;
        default: // openai / custom
          final choices = data['choices'] as List?;
          if (choices == null || choices.isEmpty) return null;
          return choices[0]['delta']?['content'] as String?;
      }
    } catch (_) {
      return null;
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
  String? _extractJsonArray(String text) => _extractJsonArrayStatic(text);

  static String? _extractJsonArrayStatic(String text) {
    // Try to find content between ```json and ``` markers
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)?.trim();
    }
    // Scan for a balanced top-level JSON array (handles nested arrays and
    // strings, which a non-greedy regex would truncate).
    final start = text.indexOf('[');
    if (start == -1) return null;
    var depth = 0;
    var inString = false;
    for (var i = start; i < text.length; i++) {
      final c = text[i];
      if (inString) {
        if (c == r'\') {
          i++; // skip escaped character
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '[') {
        depth++;
      } else if (c == ']') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
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
        throw Exception(_friendlyErrorMessage(response.statusCode, response.body));
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
          'model': config.selectedModel,
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
        throw Exception(_friendlyErrorMessage(response.statusCode, response.body));
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
          'model': config.selectedModel,
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
        throw Exception(_friendlyErrorMessage(response.statusCode, response.body));
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
          'model': config.selectedModel,
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
        throw Exception(_friendlyErrorMessage(response.statusCode, response.body));
      }
    } finally {
      client.close();
    }
  }

  // ---- Gemini calls ----

  static Map<String, dynamic> _geminiBody(
      AIProviderConfig config, String userText, String systemPrompt) {
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

  Future<String> _callGemini(
      AIProviderConfig config, String userText, String systemPrompt) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse(
            '${config.baseUrl}/v1beta/models/${config.selectedModel}:generateContent'),
        headers: {
          'x-goog-api-key': config.apiKey,
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
        throw Exception(_friendlyErrorMessage(response.statusCode, response.body));
      }
    } finally {
      client.close();
    }
  }
}
