import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../providers/presentation_state.dart';

class PPTGenerator {
  static Future<File> generatePPT(List<Map<String, dynamic>> slides, String outputPath, {SlideEffect effect = SlideEffect.none}) async {
    try {
      final pptxBytes = _createPPTXArchive(slides, effect: effect);
      final outputFile = File(outputPath);
      await outputFile.create(recursive: true);
      await outputFile.writeAsBytes(pptxBytes);
      return outputFile;
    } catch (e) {
      throw Exception('Failed to generate PPT: $e');
    }
  }

  static Uint8List _createPPTXArchive(List<Map<String, dynamic>> slides, {SlideEffect effect = SlideEffect.none}) {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = _buildContentTypesXml(slides.length);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    const dotRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', dotRelsXml.length, utf8.encode(dotRelsXml)));

    // 3. ppt/presentation.xml
    final presentationXml = _buildPresentationXml(slides.length);
    archive.addFile(ArchiveFile('ppt/presentation.xml', presentationXml.length, utf8.encode(presentationXml)));

    // 4. ppt/_rels/presentation.xml.rels
    final presentationRelsXml = _buildPresentationRelsXml(slides.length);
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presentationRelsXml.length, utf8.encode(presentationRelsXml)));

    // 5. ppt/slideMaster/slideMaster1.xml
    const slideMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
</p:sldMaster>''';
    archive.addFile(ArchiveFile('ppt/slideMaster/slideMaster1.xml', slideMasterXml.length, utf8.encode(slideMasterXml)));

    // 6. ppt/slideLayouts/slideLayout1.xml
    const slideLayoutXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
</p:sldLayout>''';
    archive.addFile(ArchiveFile('ppt/slideLayouts/slideLayout1.xml', slideLayoutXml.length, utf8.encode(slideLayoutXml)));

    // 7. Individual slides XML & slide rels
    for (int i = 0; i < slides.length; i++) {
      final slideNum = i + 1;
      final slide = slides[i];
      final slideXml = _buildSlideXml(slide, slideNum, effect);
      archive.addFile(ArchiveFile('ppt/slides/slide$slideNum.xml', slideXml.length, utf8.encode(slideXml)));

      const slideRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/slides/_rels/slide$slideNum.xml.rels', slideRelsXml.length, utf8.encode(slideRelsXml)));
    }

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    return Uint8List.fromList(bytes ?? []);
  }

  static String _buildContentTypesXml(int count) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    buffer.write('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    buffer.write('  <Default Extension="xml" ContentType="application/xml"/>\n');
    buffer.write('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');
    buffer.write('  <Override PartName="/ppt/slideMaster/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>\n');
    buffer.write('  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>\n');

    for (int i = 1; i <= count; i++) {
      buffer.write('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    buffer.write('</Types>');
    return buffer.toString();
  }

  static String _buildPresentationXml(int count) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');
    buffer.write('  <p:sldMasterIdLst>\n');
    buffer.write('    <p:sldMasterId id="2147483648" r:id="rId1"/>\n');
    buffer.write('  </p:sldMasterIdLst>\n');
    buffer.write('  <p:sldIdLst>\n');
    for (int i = 1; i <= count; i++) {
      final rId = i + 1; // rId1 is slideMaster, rId2+ are slides
      final sldId = 255 + i;
      buffer.write('    <p:sldId id="$sldId" r:id="rId$rId"/>\n');
    }
    buffer.write('  </p:sldIdLst>\n');
    buffer.write('  <p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>\n');
    buffer.write('  <p:notesSz cx="6858000" cy="9144000"/>\n');
    buffer.write('</p:presentation>');
    return buffer.toString();
  }

  static String _buildPresentationRelsXml(int count) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    buffer.write('  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMaster/slideMaster1.xml"/>\n');
    for (int i = 1; i <= count; i++) {
      final rId = i + 1;
      buffer.write('  <Relationship Id="rId$rId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>\n');
    }
    buffer.write('</Relationships>');
    return buffer.toString();
  }

  static String _buildSlideXml(Map<String, dynamic> slide, int slideNum, SlideEffect effect) {
    final rawTitle = slide['title'] ?? 'Slide $slideNum';
    final rawHtml = slide['htmlContent'] ?? '';

    final cleanTitle = _xmlEscape(rawTitle.toString());
    final paragraphs = parseHtmlContent(rawHtml);

    final b = StringBuffer();
    b.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    b.write('<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');
    b.write('  <p:cSld>\n');
    b.write('    <p:spTree>\n');
    b.write('      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n');
    b.write('      <p:grpSpPr/>\n');

    // --- Title shape ---
    b.write('      <p:sp>\n');
    b.write('        <p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>\n');
    b.write('        <p:spPr><a:xfrm><a:off x="457200" y="274320"/><a:ext cx="8229600" cy="1143000"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');
    b.write('          <a:p><a:r><a:rPr lang="en-US" sz="3600" b="1"/><a:t>$cleanTitle</a:t></a:r></a:p>\n');
    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');

    // --- Content shape (HTML with formatting preserved) ---
    b.write('      <p:sp>\n');
    b.write('        <p:nvSpPr><p:cNvPr id="3" name="Content 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write('        <p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (final para in paragraphs) {
      final text = para['text'] as String;
      final isBold = para['bold'] == 'true';
      final isItalic = para['italic'] == 'true';
      final isBreak = para['isBreak'] == 'true';

      if (text.isEmpty && !isBreak) continue;

      b.write('          <a:p>\n');
      b.write('            <a:pPr');
      if (isBold) b.write(' b="1"');
      if (isItalic) b.write(' i="1"');
      b.write('/>\n');
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

    b.write('    </p:spTree>\n');
    // Add slide transition effect
    b.write('    ' + _buildTransitionXml(effect) + '\n');
    b.write('  </p:cSld>\n');
    b.write('</p:sld>');
    return b.toString();
  }

  // ---- HTML parsing ----

  static List<Map<String, String>> parseHtmlContent(String html) {
    final document = html_parser.parse(html);
    final body = document.body;
    if (body == null) {
      return [{'text': html, 'bold': 'false', 'italic': 'false'}];
    }
    return _extractParagraphs(body);
  }

  static List<Map<String, String>> _extractParagraphs(dom.Element element) {
    final result = <Map<String, String>>[];
    for (final node in element.nodes) {
      if (node is dom.Text) {
        final trimmed = node.text.trim();
        if (trimmed.isNotEmpty) {
          result.add({'text': trimmed, 'bold': 'false', 'italic': 'false'});
        }
      } else if (node is dom.Element) {
        final tag = node.localName;
        switch (tag) {
          case 'br':
            result.add({'text': '', 'bold': 'false', 'italic': 'false', 'isBreak': 'true'});
            break;
          case 'p':
          case 'div':
          case 'h1':
          case 'h2':
          case 'h3':
          case 'h4':
          case 'h5':
          case 'h6':
          case 'li':
            result.addAll(_extractParagraphs(node));
            break;
          case 'strong':
          case 'b':
            for (final child in _extractParagraphs(node)) {
              result.add({'text': child['text'] ?? '', 'bold': 'true', 'italic': child['italic'] ?? 'false'});
            }
            break;
          case 'em':
          case 'i':
            for (final child in _extractParagraphs(node)) {
              result.add({'text': child['text'] ?? '', 'bold': child['bold'] ?? 'false', 'italic': 'true'});
            }
            break;
          case 'ul':
          case 'ol':
            for (final child in _extractParagraphs(node)) {
              result.add(child);
            }
            break;
          default:
            result.addAll(_extractParagraphs(node));
            break;
        }
      }
    }
    return result;
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
    const dur = 500; // 500ms default transition
    final String type;
    switch (effect) {
      case SlideEffect.fade:
        type = 'fade';
        break;
      case SlideEffect.pushLeft:
      case SlideEffect.pushRight:
      case SlideEffect.pushUp:
      case SlideEffect.pushDown:
        type = 'push';
        break;
      case SlideEffect.wipe:
        type = 'wipe';
        break;
      case SlideEffect.splitIn:
      case SlideEffect.splitOut:
        type = 'split';
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
      case SlideEffect.randomBar:
      case SlideEffect.checkerboard:
        type = 'random';
        break;
      default:
        return '';
    }
    return '<p:transition spd="slow" advClick="1">'
        '<p:$type dur="$dur"/>'
        '</p:transition>';
  }
}

