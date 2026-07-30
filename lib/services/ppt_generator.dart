import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../providers/presentation_state.dart';

class PPTGenerator {
  static Future<File> generatePPT(
    List<Map<String, dynamic>> slides,
    String outputPath, {
    SlideEffect effect = SlideEffect.none,
    bool widescreen = true,
  }) async {
    try {
      final pptxBytes =
          _createPPTXArchive(slides, effect: effect, widescreen: widescreen);
      final outputFile = File(outputPath);
      await outputFile.create(recursive: true);
      await outputFile.writeAsBytes(pptxBytes);
      return outputFile;
    } catch (e) {
      throw Exception('Failed to generate PPT: $e');
    }
  }

  static Uint8List _createPPTXArchive(
    List<Map<String, dynamic>> slides, {
    SlideEffect effect = SlideEffect.none,
    bool widescreen = true,
  }) {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = _buildContentTypesXml(slides.length);
    archive.addFile(ArchiveFile('[Content_Types].xml',
        contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    const dotRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile(
        '_rels/.rels', dotRelsXml.length, utf8.encode(dotRelsXml)));

    // 3. ppt/presentation.xml
    final presentationXml =
        _buildPresentationXml(slides.length, widescreen: widescreen);
    archive.addFile(ArchiveFile('ppt/presentation.xml',
        presentationXml.length, utf8.encode(presentationXml)));

    // 4. ppt/_rels/presentation.xml.rels
    final presentationRelsXml = _buildPresentationRelsXml(slides.length);
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels',
        presentationRelsXml.length, utf8.encode(presentationRelsXml)));

    // 5. ppt/slideMaster/slideMaster1.xml
    const slideMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
</p:sldMaster>''';
    archive.addFile(ArchiveFile('ppt/slideMaster/slideMaster1.xml',
        slideMasterXml.length, utf8.encode(slideMasterXml)));

    // 6. ppt/slideLayouts/slideLayout1.xml
    const slideLayoutXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
</p:sldLayout>''';
    archive.addFile(ArchiveFile('ppt/slideLayouts/slideLayout1.xml',
        slideLayoutXml.length, utf8.encode(slideLayoutXml)));

    // 7. Individual slides XML & slide rels
    for (int i = 0; i < slides.length; i++) {
      final slideNum = i + 1;
      final slide = slides[i];
      final slideXml = _buildSlideXml(slide, slideNum, effect);
      archive.addFile(ArchiveFile('ppt/slides/slide$slideNum.xml',
          slideXml.length, utf8.encode(slideXml)));

      const slideRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile(
          'ppt/slides/_rels/slide$slideNum.xml.rels',
          slideRelsXml.length,
          utf8.encode(slideRelsXml)));
    }

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    return Uint8List.fromList(bytes ?? []);
  }

  static String _buildContentTypesXml(int count) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write(
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    buffer.write(
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    buffer.write(
        '  <Default Extension="xml" ContentType="application/xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/slideMaster/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>\n');

    for (int i = 1; i <= count; i++) {
      buffer.write(
          '  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    buffer.write('</Types>');
    return buffer.toString();
  }

  static String _buildPresentationXml(int count, {bool widescreen = true}) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write(
        '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');
    buffer.write('  <p:sldMasterIdLst>\n');
    buffer.write(
        '    <p:sldMasterId id="2147483648" r:id="rId1"/>\n');
    buffer.write('  </p:sldMasterIdLst>\n');
    buffer.write('  <p:sldIdLst>\n');
    for (int i = 1; i <= count; i++) {
      final rId = i + 1; // rId1 is slideMaster, rId2+ are slides
      final sldId = 255 + i;
      buffer.write(
          '    <p:sldId id="$sldId" r:id="rId$rId"/>\n');
    }
    buffer.write('  </p:sldIdLst>\n');
    if (widescreen) {
      // 16:9 — 12192000 x 6858000 EMUs
      buffer.write(
          '  <p:sldSz cx="12192000" cy="6858000" type="screen16x9"/>\n');
    } else {
      // 4:3 — 9144000 x 6858000 EMUs
      buffer.write(
          '  <p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>\n');
    }
    buffer.write('  <p:notesSz cx="6858000" cy="9144000"/>\n');
    buffer.write('</p:presentation>');
    return buffer.toString();
  }

  static String _buildPresentationRelsXml(int count) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write(
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    buffer.write(
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMaster/slideMaster1.xml"/>\n');
    for (int i = 1; i <= count; i++) {
      final rId = i + 1;
      buffer.write(
          '  <Relationship Id="rId$rId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>\n');
    }
    buffer.write('</Relationships>');
    return buffer.toString();
  }

  static String _buildSlideXml(
      Map<String, dynamic> slide, int slideNum, SlideEffect effect) {
    final rawTitle = slide['title'] ?? 'Slide $slideNum';
    final rawHtml = slide['htmlContent'] ?? '';

    final cleanTitle = _xmlEscape(rawTitle.toString());
    final parsed = parseHtmlContentFull(rawHtml);

    // Extract background color from data-bg-color attribute
    String? bgColor;
    final bgColorRegExp = RegExp(r"""data-bg-color=["']([^"']+)["']""", caseSensitive: false);
    final bgMatch = bgColorRegExp.firstMatch(rawHtml);
    if (bgMatch != null) {
      bgColor = bgMatch.group(1);
    }

    // Extract subtitle from h2 elements
    String? subtitleText;
    final h2Doc = html_parser.parse(rawHtml);
    final h2 = h2Doc.querySelector('h2');
    if (h2 != null && h2.text.trim().isNotEmpty) {
      subtitleText = h2.text.trim();
    }

    final b = StringBuffer();
    b.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    b.write(
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');

    // Transition (applied outside cSld per OOXML spec)
    final transitionXml = _buildTransitionXml(effect);
    if (transitionXml.isNotEmpty) {
      b.write('  $transitionXml\n');
    }

    b.write('  <p:cSld>\n');

    // Background fill (if bgColor is specified)
    if (bgColor != null) {
      final cleanBg = _xmlEscape(bgColor);
      b.write('    <p:bg>\n');
      b.write('      <p:bgPr>\n');
      b.write('        <a:solidFill>\n');
      b.write('          <a:srgbClr val="$cleanBg"/>\n');
      b.write('        </a:solidFill>\n');
      b.write('      </p:bgPr>\n');
      b.write('    </p:bg>\n');
    }

    b.write('    <p:spTree>\n');
    b.write(
        '      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n');
    b.write('      <p:grpSpPr/>\n');

    // --- Title shape ---
    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="457200" y="274320"/><a:ext cx="8229600" cy="1143000"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');
    b.write(
        '          <a:p><a:r><a:rPr lang="en-US" sz="3600" b="1"/><a:t>$cleanTitle</a:t></a:r></a:p>\n');
    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');

    // --- Subtitle shape (if h2 present) ---
    if (subtitleText != null && subtitleText.isNotEmpty) {
      final cleanSubtitle = _xmlEscape(subtitleText);
      b.write('      <p:sp>\n');
      b.write(
          '        <p:nvSpPr><p:cNvPr id="7" name="Subtitle 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="subTitle"/></p:nvPr></p:nvSpPr>\n');
      b.write(
          '        <p:spPr><a:xfrm><a:off x="457200" y="1371600"/><a:ext cx="8229600" cy="457200"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
      b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');
      b.write(
          '          <a:p><a:r><a:rPr lang="en-US" sz="2400" i="1"/><a:t>$cleanSubtitle</a:t></a:r></a:p>\n');
      b.write('        </p:txBody>\n');
      b.write('      </p:sp>\n');
    }

    // --- Content shapes ---
    for (final block in parsed) {
      final type = block['type'] as String;

      if (type == 'text') {
        _buildTextContentShape(b, block);
      } else if (type == 'list') {
        _buildListContentShape(b, block);
      } else if (type == 'table') {
        _buildTableShape(b, block);
      }
    }

    b.write('    </p:spTree>\n');
    b.write('  </p:cSld>\n');
    b.write('</p:sld>');
    return b.toString();
  }

  /// Build a simple text content shape
  static void _buildTextContentShape(
      StringBuffer b, Map<String, dynamic> block) {
    final paragraphs = (block['paragraphs'] as List).cast<Map<String, String>>();
    if (paragraphs.isEmpty) return;

    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="4" name="Content Text"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (final para in paragraphs) {
      _writeParagraph(b, para, indentLevel: 0);
    }

    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');
  }

  /// Build a list content shape with bullet or numbered formatting
  static void _buildListContentShape(
      StringBuffer b, Map<String, dynamic> block) {
    final items = (block['items'] as List).cast<Map<String, String>>();
    final ordered = block['ordered'] as bool;
    if (items.isEmpty) return;

    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="5" name="List Content"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final text = item['text'] ?? '';
      final isBold = item['bold'] == 'true';
      final isItalic = item['italic'] == 'true';

      b.write('          <a:p>\n');
      b.write('            <a:pPr marL="457200" indent="-228600"');
      if (ordered) {
        // Numbered list
        b.write('><a:buAutoNum type="arabicPeriod" startAt="${i + 1}"/></a:pPr>\n');
      } else {
        // Bullet list — use bullet character
        b.write('><a:buChar char="\\u2022"/></a:pPr>\n');
      }
      b.write('            <a:r>\n');
      b.write('              <a:rPr lang="en-US" sz="1800"');
      if (isBold) b.write(' b="1"');
      if (isItalic) b.write(' i="1"');
      b.write('/>\n');
      b.write('              <a:t>${_xmlEscape(text)}</a:t>\n');
      b.write('            </a:r>\n');
      b.write('          </a:p>\n');
    }

    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');
  }

  /// Build a table content shape (placeholder — basic structure)
  static void _buildTableShape(
      StringBuffer b, Map<String, dynamic> block) {
    final rowsDynamic = block['rows'] as List?;
    if (rowsDynamic == null || rowsDynamic.isEmpty) return;

    // Convert dynamic rows to properly typed data
    final rows = <List<Map<String, String>>>[];
    for (final rowDynamic in rowsDynamic) {
      final rowList = rowDynamic as List;
      final typedRow = <Map<String, String>>[];
      for (final cellDynamic in rowList) {
        typedRow.add(Map<String, String>.from(cellDynamic as Map));
      }
      rows.add(typedRow);
    }

    final cols = rows
        .fold<int>(0, (max, row) => row.length > max ? row.length : max);
    if (cols == 0) return;

    b.write('      <p:graphicFrame>\n');
    b.write(
        '        <p:nvGraphicFramePr><p:cNvPr id="6" name="Table"/><p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr><p:nvPr/></p:nvGraphicFramePr>\n');
    b.write(
        '        <p:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="${rows.length * 400000}"/></a:xfrm>\n');
    b.write(
        '        <a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table">\n');
    b.write(
        '          <a:tbl><a:tblPr/><a:tblGrid>\n');

    for (int c = 0; c < cols; c++) {
      b.write('            <a:gridCol w="${(8229600 / cols).round()}"/>\n');
    }

    b.write('          </a:tblGrid>\n');

    for (int r = 0; r < rows.length; r++) {
      final isHeader = block['headerRow'] == true && r == 0;
      b.write('          <a:tr h="400000">\n');
      for (int c = 0; c < rows[r].length; c++) {
        final cell = rows[r][c];
        final text = cell['text'] ?? '';
        final isBold = cell['bold'] == 'true' || isHeader;

        b.write('            <a:tc>\n');
        b.write('              <a:txBody><a:bodyPr/><a:lstStyle/>\n');
        b.write('                <a:p>\n');
        b.write('                  <a:pPr marL="0" indent="0"/>\n');
        b.write('                  <a:r>\n');
        b.write('                    <a:rPr lang="en-US" sz="1600"');
        if (isBold) b.write(' b="1"');
        b.write('/>\n');
        b.write(
            '                    <a:t>${_xmlEscape(text)}</a:t>\n');
        b.write('                  </a:r>\n');
        b.write('                </a:p>\n');
        b.write('              </a:txBody></a:txBody>\n');
        b.write('            </a:tc>\n');
      }
      b.write('          </a:tr>\n');
    }

    b.write('          </a:tbl>\n');
    b.write('        </a:graphicData></a:graphic>\n');
    b.write('      </p:graphicFrame>\n');
  }

  /// Write a single paragraph run into a text body
  static void _writeParagraph(
      StringBuffer b, Map<String, String> para, {int indentLevel = 0}) {
    final text = para['text'] as String;
    final isBold = para['bold'] == 'true';
    final isItalic = para['italic'] == 'true';
    final isBreak = para['isBreak'] == 'true';

    if (text.isEmpty && !isBreak) return;

    b.write('          <a:p>\n');
    if (indentLevel > 0) {
      b.write(
          '            <a:pPr marL="${indentLevel * 457200}" indent="-228600"/>\n');
    }
    b.write('            <a:r>\n');
    b.write('              <a:rPr lang="en-US" sz="1800"');
    if (isBold) b.write(' b="1"');
    if (isItalic) b.write(' i="1"');
    b.write('/>\n');
    if (isBreak) {
      b.write('              <a:br/>\n');
    } else {
      b.write('              <a:t>${_xmlEscape(text)}</a:t>\n');
    }
    b.write('            </a:r>\n');
    b.write('          </a:p>\n');
  }

  // ---- HTML parsing ----

  /// Parse HTML content and return structured blocks (text, list, table)
  static List<Map<String, dynamic>> parseHtmlContentFull(String html) {
    if (html.trim().isEmpty) {
      return [
        {
          'type': 'text',
          'paragraphs': [
            {'text': '', 'bold': 'false', 'italic': 'false'}
          ]
        }
      ];
    }
    final document = html_parser.parse(html);
    final body = document.body;
    if (body == null) {
      return [
        {
          'type': 'text',
          'paragraphs': [
            {'text': html, 'bold': 'false', 'italic': 'false'}
          ]
        }
      ];
    }
    final blocks = _extractBlocks(body);
    if (blocks.isEmpty) {
      return [
        {
          'type': 'text',
          'paragraphs': [
            {'text': html, 'bold': 'false', 'italic': 'false'}
          ]
        }
      ];
    }
    return blocks;
  }

  /// Legacy single-paragraph extraction (kept for backward compatibility)
  static List<Map<String, String>> parseHtmlContent(String html) {
    final blocks = parseHtmlContentFull(html);
    final paragraphs = <Map<String, String>>[];
    for (final block in blocks) {
      if (block['type'] == 'text') {
        paragraphs.addAll(
            (block['paragraphs'] as List).cast<Map<String, String>>());
      } else if (block['type'] == 'list') {
        for (final item in (block['items'] as List).cast<Map<String, String>>()) {
          paragraphs.add(item);
        }
      }
    }
    return paragraphs;
  }

  static List<Map<String, dynamic>> _extractBlocks(dom.Element element) {
    final result = <Map<String, dynamic>>[];
    List<Map<String, String>> currentParagraphs = [];
    List<Map<String, String>> currentListItems = [];
    bool currentListOrdered = false;
    bool inList = false;
    bool headerRow = true;

    void flushParagraphs() {
      if (currentParagraphs.isNotEmpty) {
        result.add({
          'type': 'text',
          'paragraphs': List.from(currentParagraphs),
        });
        currentParagraphs = [];
      }
    }

    void flushList() {
      if (currentListItems.isNotEmpty) {
        result.add({
          'type': 'list',
          'items': List.from(currentListItems),
          'ordered': currentListOrdered,
        });
        currentListItems = [];
      }
      inList = false;
    }

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final trimmed = node.text.trim();
        if (trimmed.isNotEmpty) {
          if (inList) {
            currentListItems.add({
              'text': trimmed,
              'bold': 'false',
              'italic': 'false',
            });
          } else {
            currentParagraphs.add({
              'text': trimmed,
              'bold': 'false',
              'italic': 'false',
            });
          }
        }
      } else if (node is dom.Element) {
        final tag = node.localName;

        if (tag == 'br') {
          if (inList) {
            currentListItems.add({
              'text': '',
              'bold': 'false',
              'italic': 'false',
              'isBreak': 'true',
            });
          } else {
            currentParagraphs.add({
              'text': '',
              'bold': 'false',
              'italic': 'false',
              'isBreak': 'true',
            });
          }
        } else if (tag == 'p' || tag == 'div' || tag == 'h1' ||
            tag == 'h2' || tag == 'h3' || tag == 'h4' || tag == 'h5' ||
            tag == 'h6') {
          flushList();
          final subPars = _extractInlineParagraphs(node);
          if (subPars.isNotEmpty) {
            // For headings, make them bold
            if (tag != null && tag.startsWith('h')) {
              for (final p in subPars) {
                p['bold'] = 'true';
                p['italic'] = p['italic'] ?? 'false';
              }
            }
            currentParagraphs.addAll(subPars);
          }
        } else if (tag == 'ul' || tag == 'ol') {
          flushParagraphs();
          flushList();
          inList = true;
          currentListOrdered = (tag == 'ol');
          for (final child in node.nodes) {
            if (child is dom.Element && child.localName == 'li') {
              final items = _extractInlineParagraphs(child);
              for (final item in items) {
                currentListItems.add(item);
              }
            }
          }
        } else if (tag == 'table') {
          flushParagraphs();
          flushList();
          final tableData = _extractTable(node);
          if (tableData.isNotEmpty) {
            result.add({
              'type': 'table',
              'rows': tableData,
              'headerRow': headerRow,
            });
            headerRow = false;
          }
        } else if (tag == 'strong' || tag == 'b') {
          for (final child in _extractInlineParagraphs(node)) {
            child['bold'] = 'true';
            if (inList) {
              currentListItems.add(child);
            } else {
              currentParagraphs.add(child);
            }
          }
        } else if (tag == 'em' || tag == 'i') {
          for (final child in _extractInlineParagraphs(node)) {
            child['italic'] = 'true';
            if (inList) {
              currentListItems.add(child);
            } else {
              currentParagraphs.add(child);
            }
          }
        } else {
          // Recurse into unknown elements
          final subBlocks = _extractBlocks(node);
          for (final block in subBlocks) {
            if (block['type'] == 'text') {
              currentParagraphs
                  .addAll((block['paragraphs'] as List).cast<Map<String, String>>());
            } else if (block['type'] == 'list') {
              flushParagraphs();
              result.add(block);
            }
          }
        }
      }
    }

    flushParagraphs();
    flushList();
    return result;
  }

  /// Extract inline paragraphs from an element (text leaves only)
  static List<Map<String, String>> _extractInlineParagraphs(
      dom.Element element) {
    final result = <Map<String, String>>[];
    for (final node in element.nodes) {
      if (node is dom.Text) {
        final trimmed = node.text.trim();
        if (trimmed.isNotEmpty) {
          result.add({
            'text': trimmed,
            'bold': 'false',
            'italic': 'false',
          });
        }
      } else if (node is dom.Element) {
        final tag = node.localName;
        if (tag == 'br') {
          result.add({
            'text': '',
            'bold': 'false',
            'italic': 'false',
            'isBreak': 'true',
          });
        } else if (tag == 'strong' || tag == 'b') {
          for (final child in _extractInlineParagraphs(node)) {
            child['bold'] = 'true';
            result.add(child);
          }
        } else if (tag == 'em' || tag == 'i') {
          for (final child in _extractInlineParagraphs(node)) {
            child['italic'] = 'true';
            result.add(child);
          }
        } else {
          result.addAll(_extractInlineParagraphs(node));
        }
      }
    }
    return result;
  }

  /// Extract table data as list of rows (each row is list of cell paragraphs)
  static List<List<Map<String, String>>> _extractTable(dom.Element tableEl) {
    final rows = <List<Map<String, String>>>[];
    for (final child in tableEl.nodes) {
      if (child is dom.Element) {
        if (child.localName == 'thead') {
          for (final th in child.nodes) {
            if (th is dom.Element && th.localName == 'tr') {
              rows.add(_extractTableRow(th));
            }
          }
        } else if (child.localName == 'tbody') {
          for (final tr in child.nodes) {
            if (tr is dom.Element && tr.localName == 'tr') {
              rows.add(_extractTableRow(tr));
            }
          }
        } else if (child.localName == 'tr') {
          rows.add(_extractTableRow(child));
        }
      }
    }
    return rows;
  }

  static List<Map<String, String>> _extractTableRow(dom.Element tr) {
    final cells = <Map<String, String>>[];
    for (final child in tr.nodes) {
      if (child is dom.Element &&
          (child.localName == 'th' || child.localName == 'td')) {
        final text = child.text.trim();
        final isHeader = child.localName == 'th';
        cells.add({
          'text': text,
          'bold': isHeader ? 'true' : 'false',
          'italic': 'false',
        });
      }
    }
    return cells;
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ---- PPTX transition XML from SlideEffect ----

  static String _buildTransitionXml(SlideEffect effect) {
    // OOXML-compliant transition: spd on parent, no dur on child
    final String type;
    String? subtype;
    switch (effect) {
      case SlideEffect.fade:
        type = 'fade';
        break;
      case SlideEffect.pushLeft:
        type = 'push';
        subtype = 'l';
        break;
      case SlideEffect.pushRight:
        type = 'push';
        subtype = 'r';
        break;
      case SlideEffect.pushUp:
        type = 'push';
        subtype = 'u';
        break;
      case SlideEffect.pushDown:
        type = 'push';
        subtype = 'd';
        break;
      case SlideEffect.wipe:
        type = 'wipe';
        break;
      case SlideEffect.splitIn:
        type = 'split';
        subtype = 'in';
        break;
      case SlideEffect.splitOut:
        type = 'split';
        subtype = 'out';
        break;
      case SlideEffect.randomBar:
        type = 'randomBar';
        break;
      case SlideEffect.checkerboard:
        type = 'checkerboard';
        break;
      case SlideEffect.blinds:
        type = 'blinds';
        break;
      case SlideEffect.clock:
        type = 'clock';
        break;
      case SlideEffect.zoom:
        type = 'zoom';
        break;
      default:
        return '';
    }

    String xml = '<p:transition spd="slow" advClick="1">';
    xml += '<p:$type';
    if (subtype != null) {
      xml += ' dir="$subtype"';
    }
    xml += '/>';
    xml += '</p:transition>';
    return xml;
  }
}
