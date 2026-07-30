import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/services/ppt_generator.dart';

// Tests for P0-2: HTML formatting in PPTX generation
void main() {
  final tmpDir = Directory.systemTemp.path;

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
      expect(r.where((p) => (p['text'] ?? '').isNotEmpty), hasLength(2));
    });
    test('unordered list items preserved', () {
      final r =
          PPTGenerator.parseHtmlContent('<ul><li>Item A</li><li>Item B</li></ul>');
      expect(r.where((p) => (p['text'] ?? '').contains('Item')), hasLength(2));
    });
    test('empty input returns fallback', () {
      final r = PPTGenerator.parseHtmlContent('');
      expect(r.length, 1);
    });
  });
  group('parseHtmlContentFull - structured blocks', () {
    test('detects list blocks', () {
      final blocks =
          PPTGenerator.parseHtmlContentFull('<ul><li>One</li><li>Two</li></ul>');
      expect(blocks.any((b) => b['type'] == 'list'), isTrue);
      final listBlock = blocks.firstWhere((b) => b['type'] == 'list');
      expect((listBlock['items'] as List).length, 2);
      expect(listBlock['ordered'], false);
    });
    test('detects ordered list', () {
      final blocks =
          PPTGenerator.parseHtmlContentFull('<ol><li>First</li></ol>');
      final listBlock = blocks.firstWhere((b) => b['type'] == 'list');
      expect(listBlock['ordered'], true);
    });
    test('detects table blocks', () {
      final blocks = PPTGenerator.parseHtmlContentFull(
          '<table><tr><td>A</td><td>B</td></tr></table>');
      expect(blocks.any((b) => b['type'] == 'table'), isTrue);
    });
  });
  group('generatePPT - file creation', () {
    test('generates non-empty PPTX file with 16:9 default', () async {
      final f = File('$tmpDir/test_ppt.pptx');
      final slides = [
        {'title': 'Test', 'htmlContent': '<p>Content</p>'},
      ];
      final file = await PPTGenerator.generatePPT(slides, f.path);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
      f.deleteSync();
    });
    test('generates PPTX with 4:3 when widescreen=false', () async {
      final f = File('$tmpDir/test_ppt_43.pptx');
      final slides = [
        {'title': 'Test', 'htmlContent': '<p>Content</p>'},
      ];
      final file =
          await PPTGenerator.generatePPT(slides, f.path, widescreen: false);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
      f.deleteSync();
    });
    test('generates PPTX with list content', () async {
      final f = File('$tmpDir/test_ppt_list.pptx');
      final slides = [
        {
          'title': 'List Test',
          'htmlContent': '<ul><li>Item 1</li><li>Item 2</li></ul>',
        },
      ];
      final file = await PPTGenerator.generatePPT(slides, f.path);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
      f.deleteSync();
    });
    test('generates PPTX with table content', () async {
      final f = File('$tmpDir/test_ppt_table.pptx');
      final slides = [
        {
          'title': 'Table Test',
          'htmlContent':
              '<table><tr><th>Name</th><th>Value</th></tr><tr><td>A</td><td>1</td></tr></table>',
        },
      ];
      final file = await PPTGenerator.generatePPT(slides, f.path);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
      f.deleteSync();
    });
  });
}
