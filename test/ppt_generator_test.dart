import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/models/slide.dart';
import 'package:ghita_ppt_converter/services/ppt_generator.dart';
import 'package:xml/xml.dart' as xml;

/// 1x1 black PNG used for image embedding tests.
const String kOnePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// Read all text parts of a generated PPTX into a map path -> content.
Map<String, String> readPptxParts(File file) {
  final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
  final parts = <String, String>{};
  for (final f in archive.files) {
    if (f.isFile && (f.name.endsWith('.xml') || f.name.endsWith('.rels'))) {
      parts[f.name] = utf8.decode(f.content as List<int>);
    } else if (f.isFile) {
      parts[f.name] = '';
    }
  }
  return parts;
}

Future<Map<String, String>> generateParts(
  List<Map<String, dynamic>> slides, {
  SlideEffect effect = SlideEffect.none,
}) async {
  final f = File(
      '${Directory.systemTemp.path}/gen_${DateTime.now().microsecondsSinceEpoch}.pptx');
  final file = await PPTGenerator.generatePPT(slides, f.path, effect: effect);
  final parts = readPptxParts(file);
  file.deleteSync();
  return parts;
}

// Tests for the PPTX generation engine
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

  group('v0.3.0 regressions - XML validity', () {
    test('ZIP headers declare correct UTF-8 byte sizes for non-ASCII content',
        () async {
      // Vietnamese title/notes + bullet glyph exercise multi-byte UTF-8.
      final f = File(
          '${Directory.systemTemp.path}/utf8_${DateTime.now().microsecondsSinceEpoch}.pptx');
      final file = await PPTGenerator.generatePPT([
        {
          'title': 'Xin chào Việt Nam — báo cáo quý',
          'htmlContent':
              '<p>Nội dung tiếng Việt đầy đủ dấu</p><ul><li>Gạch đầu dòng</li></ul>',
          'notes': 'Ghi chú thuyết trình bằng tiếng Việt',
        }
      ], f.path);
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      for (final entry in archive.files.where((e) => e.isFile)) {
        final actual = (entry.content as List<int>).length;
        expect(entry.size, actual,
            reason:
                '${entry.name}: declared size ${entry.size} != actual bytes $actual');
      }
      f.deleteSync();
    });

    test('table cell txBody closing tag is not duplicated', () async {
      final parts = await generateParts([
        {
          'title': 'T',
          'htmlContent': '<table><tr><td>A</td></tr></table>',
        }
      ]);
      final slideXml = parts['ppt/slides/slide1.xml']!;
      expect(slideXml.contains('</a:txBody></a:txBody>'), isFalse);
      expect(() => xml.XmlDocument.parse(slideXml), returnsNormally);
    });

    test('bullet char is a real glyph, not a literal escape', () async {
      final parts = await generateParts([
        {
          'title': 'L',
          'htmlContent': '<ul><li>Item</li></ul>',
        }
      ]);
      final slideXml = parts['ppt/slides/slide1.xml']!;
      expect(slideXml, contains('buChar char="\u2022"'));
      expect(slideXml.contains(r'\u2022'), isFalse);
    });

    test('every slide XML part is well-formed', () async {
      final parts = await generateParts([
        {
          'title': 'Mix',
          'htmlContent': '<h2>Sub</h2><p>Text</p>'
              '<ul><li>A</li></ul>'
              '<table><tr><th>H</th></tr><tr><td>C</td></tr></table>',
        }
      ]);
      for (final entry in parts.entries) {
        if (entry.key.endsWith('.xml') || entry.key.endsWith('.rels')) {
          expect(() => xml.XmlDocument.parse(entry.value), returnsNormally,
              reason: '${entry.key} must be well-formed');
        }
      }
    });
  });

  group('v0.3.0 features - images', () {
    test('embeds base64 image with media part, rels and pic shape', () async {
      final parts = await generateParts([
        {
          'title': 'Img',
          'htmlContent':
              '<p>Before</p><img src="data:image/png;base64,$kOnePixelPngBase64">',
        }
      ]);
      expect(parts.keys, contains('ppt/media/image1.png'));
      expect(parts['[Content_Types].xml'],
          contains('Extension="png" ContentType="image/png"'));
      expect(parts['ppt/slides/slide1.xml'], contains('<p:pic>'));
      expect(parts['ppt/slides/_rels/slide1.xml.rels'],
          contains('../media/image1.png'));
    });

    test('image inside a paragraph is still embedded', () async {
      final parts = await generateParts([
        {
          'title': 'Img',
          'htmlContent':
              '<p>Caption <img src="data:image/png;base64,$kOnePixelPngBase64"></p>',
        }
      ]);
      expect(parts.keys, contains('ppt/media/image1.png'));
      expect(parts['ppt/slides/slide1.xml'], contains('<p:pic>'));
    });

    test('remote image URL is skipped without failing', () async {
      final parts = await generateParts([
        {
          'title': 'Img',
          'htmlContent': '<img src="https://example.com/pic.png"><p>Hi</p>',
        }
      ]);
      expect(parts['ppt/slides/slide1.xml']!.contains('<p:pic>'), isFalse);
    });
  });

  group('v0.3.0 features - styling', () {
    test('inline color, font-size and text-align are applied', () async {
      final parts = await generateParts([
        {
          'title': 'S',
          'htmlContent':
              '<p style="color:#ff0000;font-size:24px;text-align:center">Hi</p>',
        }
      ]);
      final slideXml = parts['ppt/slides/slide1.xml']!;
      expect(slideXml, contains('srgbClr val="FF0000"'));
      expect(slideXml, contains('sz="1800"')); // 24px = 18pt
      expect(slideXml, contains('algn="ctr"'));
    });

    test('underline and strike are applied', () async {
      final parts = await generateParts([
        {
          'title': 'S',
          'htmlContent': '<p><u>under</u> and <s>gone</s></p>',
        }
      ]);
      final slideXml = parts['ppt/slides/slide1.xml']!;
      expect(slideXml, contains('u="sng"'));
      expect(slideXml, contains('strike="sngStrike"'));
    });

    test('font-family maps to latin typeface', () async {
      final parts = await generateParts([
        {
          'title': 'S',
          'htmlContent': '<p style="font-family: Arial, sans-serif">Hi</p>',
        }
      ]);
      expect(parts['ppt/slides/slide1.xml'],
          contains('<a:latin typeface="Arial"/>'));
    });
  });

  group('v0.3.0 features - notes, hyperlinks, transitions', () {
    test('notes field produces a notes slide part', () async {
      final parts = await generateParts([
        {
          'title': 'N',
          'htmlContent': '<p>Body</p>',
          'notes': 'Remember to smile',
        }
      ]);
      expect(parts.keys, contains('ppt/notesSlides/notesSlide1.xml'));
      expect(parts['ppt/notesSlides/notesSlide1.xml'],
          contains('Remember to smile'));
      expect(parts['[Content_Types].xml'], contains('notesSlide1.xml'));
      expect(parts['ppt/slides/_rels/slide1.xml.rels'],
          contains('notesSlide1.xml'));
    });

    test('aside.notes in HTML becomes speaker notes, hidden from slide',
        () async {
      final parts = await generateParts([
        {
          'title': 'N',
          'htmlContent':
              '<p>Visible</p><aside class="notes">Secret note</aside>',
        }
      ]);
      expect(parts['ppt/notesSlides/notesSlide1.xml'],
          contains('Secret note'));
      expect(
          parts['ppt/slides/slide1.xml']!.contains('Secret note'), isFalse);
    });

    test('hyperlink produces external relationship and hlinkClick', () async {
      final parts = await generateParts([
        {
          'title': 'H',
          'htmlContent': '<p><a href="https://example.com">link</a></p>',
        }
      ]);
      expect(parts['ppt/slides/slide1.xml'], contains('<a:hlinkClick'));
      final rels = parts['ppt/slides/_rels/slide1.xml.rels']!;
      expect(rels, contains('https://example.com'));
      expect(rels, contains('TargetMode="External"'));
    });

    test('per-slide effect overrides the deck-wide effect', () async {
      final parts = await generateParts(
        [
          {'title': 'A', 'htmlContent': '<p>1</p>'},
          {'title': 'B', 'htmlContent': '<p>2</p>', 'effect': 'zoom'},
        ],
        effect: SlideEffect.fade,
      );
      expect(parts['ppt/slides/slide1.xml'], contains('<p:fade/>'));
      expect(parts['ppt/slides/slide2.xml'], contains('<p:zoom/>'));
    });

    test('auto-advance emits p:advTm in every slide transition', () async {
      final f = File(
          '${Directory.systemTemp.path}/gen_timing_${DateTime.now().microsecondsSinceEpoch}.pptx');
      final file = await PPTGenerator.generatePPT(
        [
          {'title': 'A', 'htmlContent': '<p>1</p>', 'effect': 'fade'},
          {'title': 'B', 'htmlContent': '<p>2</p>'},
        ],
        f.path,
        effect: SlideEffect.none,
        autoAdvance: const Duration(seconds: 4),
      );
      final parts = readPptxParts(file);
      file.deleteSync();

      // Slide with a visual transition also carries the timing element.
      expect(parts['ppt/slides/slide1.xml'], contains('<p:fade/>'));
      expect(parts['ppt/slides/slide1.xml'],
          contains('<p:advTm val="4000"/>'));
      // Slide with no visual effect still auto-advances.
      expect(parts['ppt/slides/slide2.xml'], contains('<p:transition'));
      expect(parts['ppt/slides/slide2.xml'],
          contains('<p:advTm val="4000"/>'));
      // Generated XML stays well-formed.
      expect(() => xml.XmlDocument.parse(parts['ppt/slides/slide1.xml']!),
          returnsNormally);
      expect(() => xml.XmlDocument.parse(parts['ppt/slides/slide2.xml']!),
          returnsNormally);
    });

    test('no p:advTm when auto-advance is not configured', () async {
      final parts = await generateParts([
        {'title': 'A', 'htmlContent': '<p>1</p>'},
      ]);
      expect(parts['ppt/slides/slide1.xml'],
          isNot(contains('<p:advTm')));
    });
  });

  group('v0.3.0 features - package structure', () {
    test('theme, docProps and notes master parts exist', () async {
      final parts = await generateParts([
        {'title': 'T', 'htmlContent': '<p>x</p>'}
      ]);
      expect(parts.keys, contains('ppt/theme/theme1.xml'));
      expect(parts.keys, contains('docProps/core.xml'));
      expect(parts.keys, contains('docProps/app.xml'));
      expect(parts.keys, contains('ppt/notesMasters/notesMaster1.xml'));
      expect(parts['docProps/app.xml'], contains('Ghita PPT Converter'));
      expect(parts['docProps/core.xml'], contains('<dc:title>T</dc:title>'));
      expect(() => xml.XmlDocument.parse(parts['ppt/theme/theme1.xml']!),
          returnsNormally);
    });
  });

  group('CSS helpers', () {
    test('cssColorToHex handles formats', () {
      expect(PPTGenerator.cssColorToHex('#ff0000'), 'FF0000');
      expect(PPTGenerator.cssColorToHex('#f00'), 'FF0000');
      expect(PPTGenerator.cssColorToHex('rgb(0, 128, 255)'), '0080FF');
      expect(PPTGenerator.cssColorToHex('red'), 'FF0000');
      expect(PPTGenerator.cssColorToHex('not-a-color'), isNull);
    });

    test('cssFontSizeToSz converts units', () {
      expect(PPTGenerator.cssFontSizeToSz('24px'), '1800');
      expect(PPTGenerator.cssFontSizeToSz('18pt'), '1800');
      expect(PPTGenerator.cssFontSizeToSz('1.5em'), '1800');
      expect(PPTGenerator.cssFontSizeToSz('abc'), isNull);
    });
  });
}
