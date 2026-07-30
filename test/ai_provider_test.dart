import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/providers/ai_provider_manager.dart';

void main() {
  group('parseStreamLine - OpenAI format', () {
    test('extracts delta content', () {
      final line = 'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': 'Hello'}
              }
            ]
          })}';
      expect(AIProviderManager.parseStreamLine('openai', line), 'Hello');
    });

    test('returns null for [DONE] and non-data lines', () {
      expect(AIProviderManager.parseStreamLine('openai', 'data: [DONE]'),
          isNull);
      expect(AIProviderManager.parseStreamLine('openai', ''), isNull);
      expect(AIProviderManager.parseStreamLine('openai', 'event: ping'),
          isNull);
    });

    test('returns null for malformed JSON', () {
      expect(
          AIProviderManager.parseStreamLine('openai', 'data: {broken'), isNull);
    });
  });

  group('parseStreamLine - Anthropic format', () {
    test('extracts content_block_delta text', () {
      final line = 'data: ${jsonEncode({
            'type': 'content_block_delta',
            'delta': {'type': 'text_delta', 'text': 'Chunk'}
          })}';
      expect(AIProviderManager.parseStreamLine('anthropic', line), 'Chunk');
    });

    test('ignores other event types', () {
      final line = 'data: ${jsonEncode({
            'type': 'message_start',
            'message': {'id': 'x'}
          })}';
      expect(AIProviderManager.parseStreamLine('anthropic', line), isNull);
    });
  });

  group('parseStreamLine - Gemini format', () {
    test('extracts candidate part text', () {
      final line = 'data: ${jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Gem'}
                  ]
                }
              }
            ]
          })}';
      expect(AIProviderManager.parseStreamLine('gemini', line), 'Gem');
    });

    test('returns null for empty candidates', () {
      final line = 'data: ${jsonEncode({'candidates': []})}';
      expect(AIProviderManager.parseStreamLine('gemini', line), isNull);
    });
  });

  group('parseOutlineJson', () {
    test('parses a plain JSON array', () {
      final outline = AIProviderManager.parseOutlineJson(jsonEncode([
        {
          'title': 'Intro',
          'bullets': ['What', 'Why']
        },
        {
          'title': 'Body',
          'bullets': ['How']
        },
      ]));
      expect(outline.length, 2);
      expect(outline.first['title'], 'Intro');
      expect(outline.first['bullets'], ['What', 'Why']);
    });

    test('parses fenced markdown JSON', () {
      const raw = 'Here you go:\n```json\n'
          '[{"title":"One","bullets":["a"]}]\n```';
      final outline = AIProviderManager.parseOutlineJson(raw);
      expect(outline.length, 1);
      expect(outline.first['title'], 'One');
    });

    test('throws on unparseable response', () {
      expect(() => AIProviderManager.parseOutlineJson('no json here'),
          throwsA(isA<Exception>()));
    });
  });

  group('Provider defaults and validation', () {
    test('gemini default uses gemini formatType', () {
      final p = AIProviderConfig.geminiDefault();
      expect(p.formatType, 'gemini');
      expect(p.baseUrl, contains('generativelanguage.googleapis.com'));
      expect(AIProviderManager.validateProvider(p), isNull);
    });

    test('ollama default does not require an API key', () {
      final p = AIProviderConfig.ollamaDefault();
      expect(p.requiresApiKey, isFalse);
      expect(p.formatType, 'openai');
      expect(AIProviderManager.validateProvider(p), isNull);
    });

    test('remote providers require an API key', () {
      expect(AIProviderConfig.defaultProvider().requiresApiKey, isTrue);
      expect(AIProviderConfig.anthropicDefault().requiresApiKey, isTrue);
    });

    test('validateProvider rejects invalid base URL', () {
      final p = AIProviderConfig.defaultProvider()
          .copyWith(baseUrl: 'not-a-url');
      expect(AIProviderManager.validateProvider(p), isNotNull);
    });
  });
}
