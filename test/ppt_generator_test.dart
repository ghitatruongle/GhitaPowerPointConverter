import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/services/ppt_generator.dart';

void main() {
  group('PPTGenerator.parseHtmlContent', () {
    test('plain text returns single paragraph', () {
      final result = PPTGenerator.parseHtmlContent('<p>Hello world</p>');
      expect(result.length, 1);
      expect(result.first['text'], 'Hello world');
      expect(result.first['bold'], 'false');
    });
  });
}
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/services/ppt_generator.dart';

// Tests for P0-2: HTML formatting in PPTX generation
void main() {
  group('parseHtmlContent - basic text', () {
    test('returns single paragraph for <p> tag', () {
      final r = PPTGenerator.parseHtmlContent('<p>Hello world</p>');
      expect(r.length, 1);
      expect(r.first['text'], 'Hello world');
    });
    test('returns single paragraph for plain text', () {
      final r = PPTGenerator.parseHtmlContent('Plain text');
      expect(r.length, 1);
      expect(r.first['text'], 'Plain text');
    });
    test('preserves bold via <b>', () {
      final r = PPTGenerator.parseHtmlContent('<b>Bold text</b>');
      expect(r.first['bold'], 'true');
    });
    test('preserves italic via <em>', () {
      final r = PPTGenerator.parseHtmlContent('<em>Italic text</em>');
      expect(r.first['italic'], 'true');
    });
    test('preserves both bold and italic', () {
      final r = PPTGenerator.parseHtmlContent('<b><em>Both</em></b>');
      expect(r.first['bold'], 'true');
      expect(r.first['italic'], 'true');
    });
    test('preserves strong via <strong>', () {
      final r = PPTGenerator.parseHtmlContent('<strong>Strong</strong>');
      expect(r.first['bold'], 'true');
    });
    test('preserves italic via <i>', () {
      final r = PPTGenerator.parseHtmlContent('<i>Italic</i>');
      expect(r.first['italic'], 'true');
    });
  });
  group('parseHtmlContent - structure', () {
    test('br creates break paragraphs', () {
      final r = PPTGenerator.parseHtmlContent('Line1<br>Line2');
      expect(r.where((p) => p['isBreak'] == 'true'), hasLength(1));
    });
    test('multiple <p> tags create separate paragraphs', () {
      final r = PPTGenerator.parseHtmlContent('<p>A</p><p>B</p>');
      expect(r.where((p) => p['text'].isNotEmpty), hasLength(2));
    });
    test('unordered list items preserved', () {
      final r = PPTGenerator.parseHtmlContent('<ul><li>Item A</li><li>Item B</li></ul>');
      expect(r.where((p) => p['text'].contains('Item')), hasLength(2));
    });
    test('empty input returns fallback', () {
      final r = PPTGenerator.parseHtmlContent('');
      expect(r.length, 1);
    });
  });
  group('generatePPT - file creation', () {
    test('generates non-empty PPTX file', () {
      final f = File('/tmp/test_ppt.pptx');
      final slides = [{
        'title': 'Test',
        'htmlContent': '<p>Content</p>',
      }];
      PPTGenerator.generatePPT(slides, f.path).then((file) {
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(0));
        f.deleteSync();
      });
    });
  });
}
