import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/slide.dart';
import 'html_image_loader.dart';

/// Relationship registrar for a single slide part.
class _SlideRels {
  final List<String> _entries = [];
  int _next = 2; // rId1 is reserved for the slideLayout

  String _add(String type, String target, {bool external = false}) {
    final id = 'rId$_next';
    _next++;
    final mode = external ? ' TargetMode="External"' : '';
    _entries.add(
        '  <Relationship Id="$id" Type="$type" Target="$target"$mode/>');
    return id;
  }

  String addImage(String target) => _add(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',
      target);

  String addHyperlink(String url) => _add(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
      url,
      external: true);

  String addNotesSlide(String target) => _add(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide',
      target);

  String toXml() {
    final b = StringBuffer();
    b.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    b.write(
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    b.write(
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>\n');
    for (final e in _entries) {
      b.write('$e\n');
    }
    b.write('</Relationships>');
    return b.toString();
  }
}

/// A media file to be embedded under ppt/media/.
class _MediaFile {
  final String name;
  final Uint8List bytes;
  _MediaFile(this.name, this.bytes);
}

class PPTGenerator {
  // EMU geometry constants.
  static const int _emuPerPx = 9525;
  static const int _contentX = 457200;
  static const int _contentBottom = 6583680;

  /// Add an XML/text part using the actual UTF-8 byte length.
  ///
  /// `String.length` counts UTF-16 code units; for non-ASCII content (bullet
  /// glyphs, Vietnamese titles, notes) it understates the byte count, and the
  /// archive package writes that value into the ZIP headers verbatim — which
  /// makes PowerPoint flag the package as corrupt.
  static void _addTextFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

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
    final mediaFiles = <_MediaFile>[];
    final mediaExts = <String>{};
    final notesSlideNums = <int>[];
    var mediaCounter = 0;

    // 1. Individual slides XML, slide rels, notes slides and media.
    final slideXmls = <String>[];
    final slideRelsXmls = <String>[];
    for (int i = 0; i < slides.length; i++) {
      final slideNum = i + 1;
      final slide = slides[i];
      final rels = _SlideRels();
      final slideMedia = <_MediaFile>[];

      // Per-slide transition override (falls back to the deck-wide effect).
      var slideEffect = effect;
      final effectOverride = slide['effect'];
      if (effectOverride is String && effectOverride.isNotEmpty) {
        try {
          slideEffect = SlideEffect.values.byName(effectOverride);
        } catch (_) {}
      }

      final slideXml = _buildSlideXml(
        slide,
        slideNum,
        slideEffect,
        widescreen: widescreen,
        rels: rels,
        media: slideMedia,
        nextMediaIndex: () => ++mediaCounter,
      );

      for (final m in slideMedia) {
        mediaFiles.add(m);
        mediaExts.add(m.name.substring(m.name.lastIndexOf('.') + 1));
      }

      // Speaker notes: explicit 'notes' field wins, then <aside class="notes">.
      var notes = (slide['notes'] ?? '').toString().trim();
      if (notes.isEmpty) {
        notes = extractNotes((slide['htmlContent'] ?? '').toString());
      }
      if (notes.isNotEmpty) {
        notesSlideNums.add(slideNum);
        rels.addNotesSlide('../notesSlides/notesSlide$slideNum.xml');
        final notesXml = _buildNotesSlideXml(notes);
        _addTextFile(
            archive, 'ppt/notesSlides/notesSlide$slideNum.xml', notesXml);
        final notesRelsXml =
            '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="../slides/slide$slideNum.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesMaster" Target="../notesMasters/notesMaster1.xml"/>
</Relationships>''';
        _addTextFile(archive,
            'ppt/notesSlides/_rels/notesSlide$slideNum.xml.rels', notesRelsXml);
      }

      slideXmls.add(slideXml);
      slideRelsXmls.add(rels.toXml());
    }

    // 2. [Content_Types].xml
    final contentTypesXml = _buildContentTypesXml(
      slides.length,
      mediaExtensions: mediaExts,
      notesSlideNums: notesSlideNums,
    );
    _addTextFile(archive, '[Content_Types].xml', contentTypesXml);

    // 3. _rels/.rels
    const dotRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
    _addTextFile(archive, '_rels/.rels', dotRelsXml);

    // 4. docProps (title from first slide, app name).
    final docTitle = slides.isNotEmpty
        ? _xmlEscape((slides.first['title'] ?? 'Presentation').toString())
        : 'Presentation';
    final coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$docTitle</dc:title>
  <dc:creator>Ghita PPT Converter</dc:creator>
  <cp:lastModifiedBy>Ghita PPT Converter</cp:lastModifiedBy>
</cp:coreProperties>''';
    _addTextFile(archive, 'docProps/core.xml', coreXml);
    final appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Ghita PPT Converter</Application>
  <Slides>${slides.length}</Slides>
</Properties>''';
    _addTextFile(archive, 'docProps/app.xml', appXml);

    // 5. ppt/presentation.xml + rels
    final presentationXml =
        _buildPresentationXml(slides.length, widescreen: widescreen);
    _addTextFile(archive, 'ppt/presentation.xml', presentationXml);
    final presentationRelsXml = _buildPresentationRelsXml(slides.length);
    _addTextFile(
        archive, 'ppt/_rels/presentation.xml.rels', presentationRelsXml);

    // 6. ppt/slideMaster/slideMaster1.xml + rels (layout + theme)
    const slideMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
</p:sldMaster>''';
    _addTextFile(archive, 'ppt/slideMaster/slideMaster1.xml', slideMasterXml);
    const slideMasterRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
    _addTextFile(archive, 'ppt/slideMaster/_rels/slideMaster1.xml.rels',
        slideMasterRelsXml);

    // 7. ppt/slideLayouts/slideLayout1.xml + rels (master)
    const slideLayoutXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
</p:sldLayout>''';
    _addTextFile(archive, 'ppt/slideLayouts/slideLayout1.xml', slideLayoutXml);
    const slideLayoutRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMaster/slideMaster1.xml"/>
</Relationships>''';
    _addTextFile(archive, 'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
        slideLayoutRelsXml);

    // 8. ppt/notesMasters/notesMaster1.xml + rels (theme)
    const notesMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:notesMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
</p:notesMaster>''';
    _addTextFile(archive, 'ppt/notesMasters/notesMaster1.xml', notesMasterXml);
    const notesMasterRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
    _addTextFile(archive, 'ppt/notesMasters/_rels/notesMaster1.xml.rels',
        notesMasterRelsXml);

    // 9. ppt/theme/theme1.xml
    final themeXml = _buildThemeXml();
    _addTextFile(archive, 'ppt/theme/theme1.xml', themeXml);

    // 10. Slides + rels + media
    for (int i = 0; i < slideXmls.length; i++) {
      final slideNum = i + 1;
      _addTextFile(archive, 'ppt/slides/slide$slideNum.xml', slideXmls[i]);
      _addTextFile(archive, 'ppt/slides/_rels/slide$slideNum.xml.rels',
          slideRelsXmls[i]);
    }
    for (final m in mediaFiles) {
      archive
          .addFile(ArchiveFile('ppt/media/${m.name}', m.bytes.length, m.bytes));
    }

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    return Uint8List.fromList(bytes ?? []);
  }

  static String _buildContentTypesXml(
    int count, {
    Set<String> mediaExtensions = const {},
    List<int> notesSlideNums = const [],
  }) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write(
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    buffer.write(
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    buffer.write(
        '  <Default Extension="xml" ContentType="application/xml"/>\n');
    if (mediaExtensions.contains('png')) {
      buffer.write('  <Default Extension="png" ContentType="image/png"/>\n');
    }
    if (mediaExtensions.contains('jpg')) {
      buffer.write('  <Default Extension="jpg" ContentType="image/jpeg"/>\n');
    }
    if (mediaExtensions.contains('gif')) {
      buffer.write('  <Default Extension="gif" ContentType="image/gif"/>\n');
    }
    buffer.write(
        '  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/slideMaster/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/notesMasters/notesMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml"/>\n');
    buffer.write(
        '  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>\n');
    buffer.write(
        '  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>\n');
    buffer.write(
        '  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>\n');

    for (int i = 1; i <= count; i++) {
      buffer.write(
          '  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    for (final n in notesSlideNums) {
      buffer.write(
          '  <Override PartName="/ppt/notesSlides/notesSlide$n.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"/>\n');
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
    // Notes master (rId after all slides).
    buffer.write('  <p:notesMasterIdLst>\n');
    buffer.write('    <p:notesMasterId r:id="rId${count + 2}"/>\n');
    buffer.write('  </p:notesMasterIdLst>\n');
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
    buffer.write(
        '  <Relationship Id="rId${count + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesMaster" Target="notesMasters/notesMaster1.xml"/>\n');
    buffer.write('</Relationships>');
    return buffer.toString();
  }

  static String _buildNotesSlideXml(String notes) {
    final b = StringBuffer();
    b.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    b.write(
        '<p:notes xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');
    b.write('  <p:cSld>\n');
    b.write('    <p:spTree>\n');
    b.write(
        '      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n');
    b.write('      <p:grpSpPr/>\n');
    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="2" name="Notes Placeholder"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write('        <p:spPr/>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');
    for (final line in notes.split('\n')) {
      b.write(
          '          <a:p><a:r><a:rPr/><a:t>${_xmlEscape(line)}</a:t></a:r></a:p>\n');
    }
    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');
    b.write('    </p:spTree>\n');
    b.write('  </p:cSld>\n');
    b.write('  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>\n');
    b.write('</p:notes>');
    return b.toString();
  }

  /// Minimal but complete Office theme so PowerPoint/LibreOffice open the
  /// package without a repair prompt.
  static String _buildThemeXml() {
    const fill = '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>';
    const ln =
        '<a:ln w="9525" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>';
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Ghita Theme">'
        '<a:themeElements>'
        '<a:clrScheme name="Ghita">'
        '<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>'
        '<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>'
        '<a:dk2><a:srgbClr val="44546A"/></a:dk2>'
        '<a:lt2><a:srgbClr val="E7E6E6"/></a:lt2>'
        '<a:accent1><a:srgbClr val="4472C4"/></a:accent1>'
        '<a:accent2><a:srgbClr val="ED7D31"/></a:accent2>'
        '<a:accent3><a:srgbClr val="A5A5A5"/></a:accent3>'
        '<a:accent4><a:srgbClr val="FFC000"/></a:accent4>'
        '<a:accent5><a:srgbClr val="5B9BD5"/></a:accent5>'
        '<a:accent6><a:srgbClr val="70AD47"/></a:accent6>'
        '<a:hlink><a:srgbClr val="0563C1"/></a:hlink>'
        '<a:folHlink><a:srgbClr val="954F72"/></a:folHlink>'
        '</a:clrScheme>'
        '<a:fontScheme name="Ghita">'
        '<a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>'
        '<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>'
        '</a:fontScheme>'
        '<a:fmtScheme name="Ghita">'
        '<a:fillStyleLst>$fill$fill$fill</a:fillStyleLst>'
        '<a:lnStyleLst>$ln$ln$ln</a:lnStyleLst>'
        '<a:effectStyleLst>'
        '<a:effectStyle><a:effectLst/></a:effectStyle>'
        '<a:effectStyle><a:effectLst/></a:effectStyle>'
        '<a:effectStyle><a:effectLst/></a:effectStyle>'
        '</a:effectStyleLst>'
        '<a:bgFillStyleLst>$fill$fill$fill</a:bgFillStyleLst>'
        '</a:fmtScheme>'
        '</a:themeElements>'
        '</a:theme>';
  }

  static String _buildSlideXml(
    Map<String, dynamic> slide,
    int slideNum,
    SlideEffect effect, {
    bool widescreen = true,
    _SlideRels? rels,
    List<_MediaFile>? media,
    int Function()? nextMediaIndex,
  }) {
    final rawTitle = slide['title'] ?? 'Slide $slideNum';
    final rawHtml = slide['htmlContent'] ?? '';

    final cleanTitle = _xmlEscape(rawTitle.toString());
    // Single-pass HTML parse: reuse the DOM for content blocks, h2, and bg-color.
    final parsedDoc = html_parser.parse(rawHtml);
    final parsed = parseHtmlContentFullFromDoc(parsedDoc, fallbackText: rawHtml);
    final contentW = widescreen ? 11277600 : 8229600;

    // Extract background color from data-bg-color attribute (regex on raw HTML — fast)
    String? bgColor;
    final bgColorRegExp = RegExp(r"""data-bg-color=["']([^"']+)["']""", caseSensitive: false);
    final bgMatch = bgColorRegExp.firstMatch(rawHtml);
    if (bgMatch != null) {
      bgColor = bgMatch.group(1);
    }

    // Extract subtitle from h2 elements (reuse parsed DOM)
    String? subtitleText;
    final h2 = parsedDoc.querySelector('h2');
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
      final cleanBg = _xmlEscape(bgColor.replaceAll('#', ''));
      b.write('    <p:bg>\n');
      b.write('      <p:bgPr>\n');
      b.write('        <a:solidFill>\n');
      b.write('          <a:srgbClr val="$cleanBg"/>\n');
      b.write('        </a:solidFill>\n');
      b.write('        <a:effectLst/>\n');
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
        '        <p:spPr><a:xfrm><a:off x="$_contentX" y="274320"/><a:ext cx="$contentW" cy="1143000"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
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
          '        <p:spPr><a:xfrm><a:off x="$_contentX" y="1371600"/><a:ext cx="$contentW" cy="457200"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
      b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');
      b.write(
          '          <a:p><a:r><a:rPr lang="en-US" sz="2400" i="1"/><a:t>$cleanSubtitle</a:t></a:r></a:p>\n');
      b.write('        </p:txBody>\n');
      b.write('      </p:sp>\n');
    }

    // --- Content shapes (simple vertical flow layout) ---
    int y = subtitleText != null ? 1943100 : 1600200;
    int shapeId = 10;

    int advance(int estimatedHeight) {
      final available = _contentBottom - y;
      final h = estimatedHeight.clamp(360000, available > 360000 ? available : 360000);
      final usedY = y;
      if (y + h < _contentBottom) y += h + 91440;
      return usedY;
    }

    for (final block in parsed) {
      final type = block['type'] as String;

      if (type == 'text') {
        final count = (block['paragraphs'] as List).length;
        _buildTextContentShape(b, block,
            shapeId: shapeId++,
            x: _contentX,
            y: advance(360000 * count + 91440),
            w: contentW,
            rels: rels);
      } else if (type == 'list') {
        final count = (block['items'] as List).length;
        _buildListContentShape(b, block,
            shapeId: shapeId++,
            x: _contentX,
            y: advance(360000 * count + 91440),
            w: contentW,
            rels: rels);
      } else if (type == 'table') {
        final count = (block['rows'] as List).length;
        _buildTableShape(b, block,
            shapeId: shapeId++,
            x: _contentX,
            y: advance(400000 * count),
            w: contentW);
      } else if (type == 'image' &&
          rels != null &&
          media != null &&
          nextMediaIndex != null) {
        _buildImageShape(b, block,
            shapeId: shapeId++,
            x: _contentX,
            yProvider: advance,
            w: contentW,
            rels: rels,
            media: media,
            nextMediaIndex: nextMediaIndex);
      }
    }

    b.write('    </p:spTree>\n');
    b.write('  </p:cSld>\n');
    b.write('</p:sld>');
    return b.toString();
  }

  /// Build a picture shape from an image block; embeds media + relationship.
  static void _buildImageShape(
    StringBuffer b,
    Map<String, dynamic> block, {
    required int shapeId,
    required int x,
    required int Function(int) yProvider,
    required int w,
    required _SlideRels rels,
    required List<_MediaFile> media,
    required int Function() nextMediaIndex,
  }) {
    final src = (block['src'] ?? '').toString();
    final loaded = HtmlImageLoader.load(src);
    if (loaded == null) return;

    final index = nextMediaIndex();
    final name = 'image$index.${loaded.ext}';
    media.add(_MediaFile(name, loaded.bytes));
    final rId = rels.addImage('../media/$name');

    // Scale to fit the content width and remaining vertical space.
    int imgW = loaded.width * _emuPerPx;
    int imgH = loaded.height * _emuPerPx;
    final y = yProvider(imgH);
    final availH = (_contentBottom - y).clamp(914400, 6858000);
    final scale = [
      1.0,
      w / imgW,
      availH / imgH,
    ].reduce((a, c) => a < c ? a : c);
    imgW = (imgW * scale).round();
    imgH = (imgH * scale).round();
    final xOff = x + ((w - imgW) ~/ 2);

    b.write('      <p:pic>\n');
    b.write(
        '        <p:nvPicPr><p:cNvPr id="$shapeId" name="Picture $shapeId"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>\n');
    b.write(
        '        <p:blipFill><a:blip r:embed="$rId"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="$xOff" y="$y"/><a:ext cx="$imgW" cy="$imgH"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>\n');
    b.write('      </p:pic>\n');
  }

  /// Build a simple text content shape
  static void _buildTextContentShape(
    StringBuffer b,
    Map<String, dynamic> block, {
    int shapeId = 4,
    int x = 457200,
    int y = 1600200,
    int w = 8229600,
    _SlideRels? rels,
  }) {
    final paragraphs = (block['paragraphs'] as List).cast<Map<String, String>>();
    if (paragraphs.isEmpty) return;

    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="$shapeId" name="Content Text"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$w" cy="4525963"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (final para in paragraphs) {
      _writeParagraph(b, para, indentLevel: 0, rels: rels);
    }

    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');
  }

  /// Build a list content shape with bullet or numbered formatting
  static void _buildListContentShape(
    StringBuffer b,
    Map<String, dynamic> block, {
    int shapeId = 5,
    int x = 457200,
    int y = 1600200,
    int w = 8229600,
    _SlideRels? rels,
  }) {
    final items = (block['items'] as List).cast<Map<String, String>>();
    final ordered = block['ordered'] as bool;
    if (items.isEmpty) return;

    b.write('      <p:sp>\n');
    b.write(
        '        <p:nvSpPr><p:cNvPr id="$shapeId" name="List Content"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>\n');
    b.write(
        '        <p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$w" cy="4525963"/></a:xfrm><a:presetGeom geom="rect"><a:avLst/></a:presetGeom></p:spPr>\n');
    b.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      b.write('          <a:p>\n');
      b.write('            <a:pPr marL="457200" indent="-228600"');
      final align = item['align'];
      if (align != null && align.isNotEmpty) b.write(' algn="$align"');
      if (ordered) {
        // Numbered list
        b.write('><a:buAutoNum type="arabicPeriod" startAt="${i + 1}"/></a:pPr>\n');
      } else {
        // Bullet list — actual bullet glyph (fixed literal \u2022 bug)
        b.write('><a:buChar char="\u2022"/></a:pPr>\n');
      }
      b.write('            <a:r>\n');
      b.write('              ${_runProps(item, defaultSize: '1800', rels: rels)}\n');
      b.write('              <a:t>${_xmlEscape(item['text'] ?? '')}</a:t>\n');
      b.write('            </a:r>\n');
      b.write('          </a:p>\n');
    }

    b.write('        </p:txBody>\n');
    b.write('      </p:sp>\n');
  }

  /// Build a table content shape
  static void _buildTableShape(
    StringBuffer b,
    Map<String, dynamic> block, {
    int shapeId = 6,
    int x = 457200,
    int y = 1600200,
    int w = 8229600,
  }) {
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
        '        <p:nvGraphicFramePr><p:cNvPr id="$shapeId" name="Table"/><p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr><p:nvPr/></p:nvGraphicFramePr>\n');
    b.write(
        '        <p:xfrm><a:off x="$x" y="$y"/><a:ext cx="$w" cy="${rows.length * 400000}"/></p:xfrm>\n');
    b.write(
        '        <a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table">\n');
    b.write(
        '          <a:tbl><a:tblPr/><a:tblGrid>\n');

    for (int c = 0; c < cols; c++) {
      b.write('            <a:gridCol w="${(w / cols).round()}"/>\n');
    }

    b.write('          </a:tblGrid>\n');

    for (int r = 0; r < rows.length; r++) {
      final isHeader = block['headerRow'] == true && r == 0;
      b.write('          <a:tr h="400000">\n');
      for (int c = 0; c < cols; c++) {
        final cell = c < rows[r].length
            ? rows[r][c]
            : <String, String>{'text': '', 'bold': 'false', 'italic': 'false'};
        final effectiveCell = Map<String, String>.from(cell);
        if (isHeader) effectiveCell['bold'] = 'true';

        b.write('            <a:tc>\n');
        b.write('              <a:txBody><a:bodyPr/><a:lstStyle/>\n');
        b.write('                <a:p>\n');
        b.write('                  <a:pPr marL="0" indent="0"/>\n');
        b.write('                  <a:r>\n');
        b.write(
            '                    ${_runProps(effectiveCell, defaultSize: '1600')}\n');
        b.write(
            '                    <a:t>${_xmlEscape(cell['text'] ?? '')}</a:t>\n');
        b.write('                  </a:r>\n');
        b.write('                </a:p>\n');
        // Fixed: single closing tag (was duplicated, producing invalid OOXML)
        b.write('              </a:txBody>\n');
        b.write('              <a:tcPr/>\n');
        b.write('            </a:tc>\n');
      }
      b.write('          </a:tr>\n');
    }

    b.write('          </a:tbl>\n');
    b.write('        </a:graphicData></a:graphic>\n');
    b.write('      </p:graphicFrame>\n');
  }

  /// Build run properties (<a:rPr>) from a paragraph/run map.
  ///
  /// Supported keys: bold, italic, underline, strike, size (hundredths of a
  /// point), color / highlight (RRGGBB), font, href.
  static String _runProps(
    Map<String, String> run, {
    required String defaultSize,
    _SlideRels? rels,
  }) {
    final size = run['size']?.isNotEmpty == true ? run['size']! : defaultSize;
    final b = StringBuffer('<a:rPr lang="en-US" sz="$size"');
    if (run['bold'] == 'true') b.write(' b="1"');
    if (run['italic'] == 'true') b.write(' i="1"');
    if (run['underline'] == 'true') b.write(' u="sng"');
    if (run['strike'] == 'true') b.write(' strike="sngStrike"');

    final color = run['color'];
    final highlight = run['highlight'];
    final font = run['font'];
    final href = run['href'];
    final hasChildren = (color != null && color.isNotEmpty) ||
        (highlight != null && highlight.isNotEmpty) ||
        (font != null && font.isNotEmpty) ||
        (href != null && href.isNotEmpty && rels != null);

    if (!hasChildren) {
      b.write('/>');
      return b.toString();
    }
    b.write('>');
    if (color != null && color.isNotEmpty) {
      b.write('<a:solidFill><a:srgbClr val="$color"/></a:solidFill>');
    }
    if (highlight != null && highlight.isNotEmpty) {
      b.write('<a:highlight><a:srgbClr val="$highlight"/></a:highlight>');
    }
    if (font != null && font.isNotEmpty) {
      b.write('<a:latin typeface="${_xmlEscape(font)}"/>');
    }
    if (href != null && href.isNotEmpty && rels != null) {
      final rId = rels.addHyperlink(_xmlEscape(href));
      b.write('<a:hlinkClick xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:id="$rId"/>');
    }
    b.write('</a:rPr>');
    return b.toString();
  }

  /// Write a single paragraph run into a text body
  static void _writeParagraph(
    StringBuffer b,
    Map<String, String> para, {
    int indentLevel = 0,
    _SlideRels? rels,
  }) {
    final text = para['text'] ?? '';
    final isBreak = para['isBreak'] == 'true';

    if (text.isEmpty && !isBreak) return;

    b.write('          <a:p>\n');
    final align = para['align'];
    if (indentLevel > 0 || (align != null && align.isNotEmpty)) {
      b.write('            <a:pPr');
      if (indentLevel > 0) {
        b.write(' marL="${indentLevel * 457200}" indent="-228600"');
      }
      if (align != null && align.isNotEmpty) b.write(' algn="$align"');
      b.write('/>\n');
    }
    b.write('            <a:r>\n');
    b.write('              ${_runProps(para, defaultSize: '1800', rels: rels)}\n');
    if (isBreak) {
      b.write('              <a:br/>\n');
    } else {
      b.write('              <a:t>${_xmlEscape(text)}</a:t>\n');
    }
    b.write('            </a:r>\n');
    b.write('          </a:p>\n');
  }

  // ---- HTML parsing ----

  /// Extract speaker notes from an `<aside class="notes">` element.
  static String extractNotes(String html) {
    if (html.trim().isEmpty) return '';
    try {
      final doc = html_parser.parse(html);
      final aside = doc.querySelector('aside.notes');
      return aside?.text.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Parse HTML content and return structured blocks (text, list, table, image)
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
    return parseHtmlContentFullFromDoc(document, fallbackText: html);
  }

  /// Parse from an already-parsed DOM document (avoids double-parsing).
  static List<Map<String, dynamic>> parseHtmlContentFullFromDoc(
      dom.Document document,
      {String fallbackText = ''}) {
    final body = document.body;
    if (body == null) {
      return [
        {
          'type': 'text',
          'paragraphs': [
            {'text': fallbackText, 'bold': 'false', 'italic': 'false'}
          ]
        }
      ];
    }
    // Speaker notes are not part of the visible slide content.
    for (final aside in body.querySelectorAll('aside.notes')) {
      aside.remove();
    }
    final blocks = _extractBlocks(body);
    if (blocks.isEmpty) {
      return [
        {
          'type': 'text',
          'paragraphs': [
            {'text': body.text, 'bold': 'false', 'italic': 'false'}
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

  // ---- Inline style parsing ----

  static final RegExp _styleDeclRegExp = RegExp(r'([\w-]+)\s*:\s*([^;]+)');

  static const Map<String, String> _cssColorNames = {
    'black': '000000',
    'white': 'FFFFFF',
    'red': 'FF0000',
    'green': '008000',
    'blue': '0000FF',
    'yellow': 'FFFF00',
    'orange': 'FFA500',
    'purple': '800080',
    'gray': '808080',
    'grey': '808080',
    'silver': 'C0C0C0',
    'navy': '000080',
    'teal': '008080',
    'maroon': '800000',
    'olive': '808000',
    'lime': '00FF00',
    'aqua': '00FFFF',
    'cyan': '00FFFF',
    'magenta': 'FF00FF',
    'fuchsia': 'FF00FF',
    'pink': 'FFC0CB',
    'brown': 'A52A2A',
    'gold': 'FFD700',
  };

  /// Normalize a CSS color (#rgb, #rrggbb, rgb(), named) to RRGGBB, or null.
  static String? cssColorToHex(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.startsWith('#')) {
      final hex = v.substring(1);
      if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) return hex.toUpperCase();
      if (RegExp(r'^[0-9a-f]{3}$').hasMatch(hex)) {
        return hex.split('').map((c) => '$c$c').join().toUpperCase();
      }
      return null;
    }
    final rgbMatch =
        RegExp(r'^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(v);
    if (rgbMatch != null) {
      String toHex(String s) =>
          int.parse(s).clamp(0, 255).toRadixString(16).padLeft(2, '0');
      return (toHex(rgbMatch.group(1)!) +
              toHex(rgbMatch.group(2)!) +
              toHex(rgbMatch.group(3)!))
          .toUpperCase();
    }
    return _cssColorNames[v]?.toUpperCase();
  }

  /// Convert a CSS font-size (px/pt/em/rem) to OOXML hundredths of a point.
  static String? cssFontSizeToSz(String raw) {
    final v = raw.trim().toLowerCase();
    final match = RegExp(r'^([\d.]+)\s*(px|pt|em|rem)?$').firstMatch(v);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null || value <= 0) return null;
    final unit = match.group(2) ?? 'px';
    double pt;
    switch (unit) {
      case 'pt':
        pt = value;
        break;
      case 'em':
      case 'rem':
        pt = value * 12; // 1em ~ 16px = 12pt
        break;
      default: // px
        pt = value * 0.75;
    }
    final sz = (pt * 100).round();
    if (sz < 100 || sz > 40000) return null;
    return sz.toString();
  }

  /// Parse style/attributes of [el] and merge run-level styling into [style].
  static Map<String, String> _mergeElementStyle(
      dom.Element el, Map<String, String> style) {
    final merged = Map<String, String>.from(style);
    final styleAttr = el.attributes['style'];
    if (styleAttr != null && styleAttr.isNotEmpty) {
      for (final m in _styleDeclRegExp.allMatches(styleAttr)) {
        final prop = m.group(1)!.trim().toLowerCase();
        final value = m.group(2)!.trim();
        switch (prop) {
          case 'color':
            final hex = cssColorToHex(value);
            if (hex != null) merged['color'] = hex;
            break;
          case 'background-color':
            final hex = cssColorToHex(value);
            if (hex != null) merged['highlight'] = hex;
            break;
          case 'font-size':
            final sz = cssFontSizeToSz(value);
            if (sz != null) merged['size'] = sz;
            break;
          case 'font-family':
            final family = value.split(',').first.trim().replaceAll(RegExp(r'''["']'''), '');
            if (family.isNotEmpty) merged['font'] = family;
            break;
          case 'font-weight':
            if (value == 'bold' || (int.tryParse(value) ?? 0) >= 600) {
              merged['bold'] = 'true';
            }
            break;
          case 'font-style':
            if (value == 'italic') merged['italic'] = 'true';
            break;
          case 'text-decoration':
            if (value.contains('underline')) merged['underline'] = 'true';
            if (value.contains('line-through')) merged['strike'] = 'true';
            break;
          case 'text-align':
            final algn = _cssAlignToAlgn(value);
            if (algn != null) merged['align'] = algn;
            break;
        }
      }
    }
    final alignAttr = el.attributes['align'];
    if (alignAttr != null) {
      final algn = _cssAlignToAlgn(alignAttr);
      if (algn != null) merged['align'] = algn;
    }
    return merged;
  }

  static String? _cssAlignToAlgn(String value) {
    switch (value.trim().toLowerCase()) {
      case 'left':
        return 'l';
      case 'center':
        return 'ctr';
      case 'right':
        return 'r';
      case 'justify':
        return 'just';
    }
    return null;
  }

  static Map<String, String> _makeRun(String text, Map<String, String> style,
      {bool isBreak = false}) {
    return {
      'text': text,
      'bold': style['bold'] ?? 'false',
      'italic': style['italic'] ?? 'false',
      if (style['underline'] == 'true') 'underline': 'true',
      if (style['strike'] == 'true') 'strike': 'true',
      if ((style['color'] ?? '').isNotEmpty) 'color': style['color']!,
      if ((style['highlight'] ?? '').isNotEmpty) 'highlight': style['highlight']!,
      if ((style['size'] ?? '').isNotEmpty) 'size': style['size']!,
      if ((style['font'] ?? '').isNotEmpty) 'font': style['font']!,
      if ((style['align'] ?? '').isNotEmpty) 'align': style['align']!,
      if ((style['href'] ?? '').isNotEmpty) 'href': style['href']!,
      if (isBreak) 'isBreak': 'true',
    };
  }

  static List<Map<String, dynamic>> _extractBlocks(dom.Element element,
      [Map<String, String> inheritedStyle = const {}]) {
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
          final run = _makeRun(trimmed, inheritedStyle);
          if (inList) {
            currentListItems.add(run);
          } else {
            currentParagraphs.add(run);
          }
        }
      } else if (node is dom.Element) {
        final tag = node.localName;
        final style = _mergeElementStyle(node, inheritedStyle);

        if (tag == 'br') {
          final run = _makeRun('', inheritedStyle, isBreak: true);
          if (inList) {
            currentListItems.add(run);
          } else {
            currentParagraphs.add(run);
          }
        } else if (tag == 'img') {
          flushParagraphs();
          flushList();
          final src = node.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            result.add({'type': 'image', 'src': src});
          }
        } else if (tag == 'p' || tag == 'div' || tag == 'h1' ||
            tag == 'h2' || tag == 'h3' || tag == 'h4' || tag == 'h5' ||
            tag == 'h6') {
          flushList();
          // Nested block content (images, lists, tables inside div/p).
          final hasBlockChildren = node.children.any((c) => const [
                'img', 'ul', 'ol', 'table', 'p', 'div'
              ].contains(c.localName));
          if ((tag == 'div' || tag == 'p') && hasBlockChildren) {
            flushParagraphs();
            result.addAll(_extractBlocks(node, style));
            continue;
          }
          final subPars = _extractInlineParagraphs(node, style);
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
              final liStyle = _mergeElementStyle(child, style);
              final items = _extractInlineParagraphs(child, liStyle);
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
          for (final child in _extractInlineParagraphs(
              node, {...style, 'bold': 'true'})) {
            if (inList) {
              currentListItems.add(child);
            } else {
              currentParagraphs.add(child);
            }
          }
        } else if (tag == 'em' || tag == 'i') {
          for (final child in _extractInlineParagraphs(
              node, {...style, 'italic': 'true'})) {
            if (inList) {
              currentListItems.add(child);
            } else {
              currentParagraphs.add(child);
            }
          }
        } else {
          // Recurse into unknown elements
          final subBlocks = _extractBlocks(node, style);
          for (final block in subBlocks) {
            if (block['type'] == 'text') {
              currentParagraphs
                  .addAll((block['paragraphs'] as List).cast<Map<String, String>>());
            } else if (block['type'] == 'list' ||
                block['type'] == 'image' ||
                block['type'] == 'table') {
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
      dom.Element element, [Map<String, String> inheritedStyle = const {}]) {
    final result = <Map<String, String>>[];
    for (final node in element.nodes) {
      if (node is dom.Text) {
        final trimmed = node.text.trim();
        if (trimmed.isNotEmpty) {
          result.add(_makeRun(trimmed, inheritedStyle));
        }
      } else if (node is dom.Element) {
        final tag = node.localName;
        final style = _mergeElementStyle(node, inheritedStyle);
        if (tag == 'br') {
          result.add(_makeRun('', inheritedStyle, isBreak: true));
        } else if (tag == 'strong' || tag == 'b') {
          result.addAll(
              _extractInlineParagraphs(node, {...style, 'bold': 'true'}));
        } else if (tag == 'em' || tag == 'i') {
          result.addAll(
              _extractInlineParagraphs(node, {...style, 'italic': 'true'}));
        } else if (tag == 'u' || tag == 'ins') {
          result.addAll(
              _extractInlineParagraphs(node, {...style, 'underline': 'true'}));
        } else if (tag == 's' || tag == 'del' || tag == 'strike') {
          result.addAll(
              _extractInlineParagraphs(node, {...style, 'strike': 'true'}));
        } else if (tag == 'a') {
          final href = node.attributes['href'] ?? '';
          result.addAll(_extractInlineParagraphs(
              node, href.isNotEmpty ? {...style, 'href': href} : style));
        } else {
          result.addAll(_extractInlineParagraphs(node, style));
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
        final style = _mergeElementStyle(child, const {});
        final text = child.text.trim();
        final isHeader = child.localName == 'th';
        final cell = _makeRun(text, style);
        if (isHeader) cell['bold'] = 'true';
        cells.add(cell);
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
