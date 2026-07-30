import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalAIServiceInfo {
  final String name;
  final String baseUrl;
  final List<String> models;
  final bool isOnline;

  LocalAIServiceInfo({
    required this.name,
    required this.baseUrl,
    required this.models,
    required this.isOnline,
  });
}

/// Service to automatically discover running local AI instances (Ollama, LM Studio, vLLM, LocalAI).
class LocalAIDetectorService {
  static const List<Map<String, String>> _knownEndpoints = [
    {
      'name': 'Ollama (Local)',
      'baseUrl': 'http://localhost:11434',
      'modelsPath': '/api/tags',
      'type': 'ollama',
    },
    {
      'name': 'Ollama OpenAI API',
      'baseUrl': 'http://localhost:11434/v1',
      'modelsPath': '/models',
      'type': 'openai',
    },
    {
      'name': 'LM Studio',
      'baseUrl': 'http://localhost:1234/v1',
      'modelsPath': '/models',
      'type': 'openai',
    },
    {
      'name': 'vLLM / LocalAI',
      'baseUrl': 'http://localhost:8000/v1',
      'modelsPath': '/models',
      'type': 'openai',
    },
  ];

  /// Scans local ports and returns a list of detected local AI services with available models.
  Future<List<LocalAIServiceInfo>> scanLocalAIServices() async {
    final List<LocalAIServiceInfo> results = [];

    for (final ep in _knownEndpoints) {
      final name = ep['name']!;
      final baseUrl = ep['baseUrl']!;
      final modelsPath = ep['modelsPath']!;
      final type = ep['type']!;

      try {
        final fullPath = '$baseUrl$modelsPath';
        final url = Uri.parse(fullPath);
        final response = await http
            .get(url)
            .timeout(const Duration(milliseconds: 1200));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<String> models = [];

          if (type == 'ollama' && data['models'] is List) {
            for (final m in data['models']) {
              if (m['name'] != null) models.add(m['name'].toString());
            }
          } else if (data['data'] is List) {
            for (final m in data['data']) {
              if (m['id'] != null) models.add(m['id'].toString());
            }
          }

          if (models.isNotEmpty) {
            results.add(LocalAIServiceInfo(
              name: name,
              baseUrl: baseUrl,
              models: models,
              isOnline: true,
            ));
          }
        }
      } catch (_) {
        // Connection refused or timeout — endpoint is offline
      }
    }

    return results;
  }
}
