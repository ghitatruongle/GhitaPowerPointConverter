import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'ppt_generator.dart';
import 'html_image_loader.dart';

/// Renders slides to a landscape PDF document, one page per slide.
///
/// Reuses [PPTGenerator.parseHtmlContentFull] so PPTX and PDF exports share
/// the exact same HTML interpretation.
class PdfExportService {
  /// Cached Unicode theme built from Windows system fonts.
  static pw.ThemeData? _cachedTheme;
  static bool _themeLoaded = false;

  /// Font family candidates with full Vietnamese/Unicode coverage, in
  /// preference order: [regular, bold, italic, boldItalic].
  static const List<List<String>> _fontCandidates = [
    ['segoeui.ttf', 'segoeuib.ttf', 'segoeuii.ttf', 'segoeuiz.ttf'],
    ['arial.ttf', 'arialbd.ttf', 'ariali.ttf', 'arialbi.ttf'],
    ['tahoma.ttf', 'tahomabd.ttf', 'tahoma.ttf', 'tahomabd.ttf'],
  ];

  /// Load a Unicode font theme from Windows system fonts so Vietnamese and
  /// other non-Latin-1 text renders correctly (the pdf package's built-in
  /// Helvetica has no Unicode support). Returns null when unavailable
  /// (non-Windows or fonts missing) — callers fall back to the default theme.
  static Future<pw.ThemeData?> loadSystemTheme() async {
    if (_themeLoaded) return _cachedTheme;
    _themeLoaded = true;

    final fontsDir =
        Platform.environment['WINDIR'] ?? r'C:\Windows';
    for (final family in _fontCandidates) {
      try {
        final files = family
            .map((name) => File('$fontsDir\\Fonts\\$name'))
            .toList();
        if (!files[0].existsSync()) continue;

        Future<pw.Font> loadFont(File f, File fallback) async {
          final source = f.existsSync() ? f : fallback;
          final bytes = await source.readAsBytes();
          return pw.Font.ttf(bytes.buffer.asByteData());
        }

        final base = await loadFont(files[0], files[0]);
        final bold = await loadFont(files[1], files[0]);
        final italic = await loadFont(files[2], files[0]);
        final boldItalic = await loadFont(files[3], files[1]);
        _cachedTheme = pw.ThemeData.withFont(
          base: base,
          bold: bold,
          italic: italic,
          boldItalic: boldItalic,
        );
        return _cachedTheme;
      } catch (_) {
        // Try the next family.
      }
    }
    return null;
  }

  Future<String> exportToPdf(
    List<Map<String, dynamic>> slides,
    String outputPath, {
    bool widescreen = true,
  }) async {
    if (slides.isEmpty) {
      throw Exception('No slides to export.');
    }

    final theme = await loadSystemTheme();
    final doc = pw.Document(theme: theme);
    // 16:9 = 13.333 x 7.5 inch, 4:3 = 10 x 7.5 inch (PowerPoint defaults).
    final pageFormat = widescreen
        ? const PdfPageFormat(13.333 * PdfPageFormat.inch, 7.5 * PdfPageFormat.inch)
        : const PdfPageFormat(10 * PdfPageFormat.inch, 7.5 * PdfPageFormat.inch);

    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      final title = (slide['title'] ?? 'Slide ${i + 1}').toString();
      final rawHtml = (slide['htmlContent'] ?? '').toString();
      final blocks = PPTGenerator.parseHtmlContentFull(rawHtml);
      final bgColor = _extractBgColor(rawHtml);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Container(
              color: bgColor,
              width: double.infinity,
              height: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: bgColor != null ? _contrastColor(bgColor) : null,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  ..._buildBlocks(blocks, bgColor),
                ],
              ),
            );
          },
        ),
      );
    }

    final outputFile = File(outputPath);
    await outputFile.create(recursive: true);
    await outputFile.writeAsBytes(await doc.save());
    return outputFile.path;
  }

  List<pw.Widget> _buildBlocks(
      List<Map<String, dynamic>> blocks, PdfColor? bgColor) {
    final widgets = <pw.Widget>[];
    final defaultColor = bgColor != null ? _contrastColor(bgColor) : null;

    for (final block in blocks) {
      final type = block['type'] as String;
      switch (type) {
        case 'text':
          for (final para
              in (block['paragraphs'] as List).cast<Map<String, String>>()) {
            final text = para['text'] ?? '';
            if (text.isEmpty) {
              if (para['isBreak'] == 'true') {
                widgets.add(pw.SizedBox(height: 8));
              }
              continue;
            }
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(text, style: _runStyle(para, 16, defaultColor)),
            ));
          }
          break;
        case 'list':
          final ordered = block['ordered'] == true;
          final items = (block['items'] as List).cast<Map<String, String>>();
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final text = item['text'] ?? '';
            if (text.isEmpty) continue;
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ordered ? '${i + 1}. ' : '\u2022 ',
                      style: _runStyle(item, 15, defaultColor)),
                  pw.Expanded(
                    child:
                        pw.Text(text, style: _runStyle(item, 15, defaultColor)),
                  ),
                ],
              ),
            ));
          }
          break;
        case 'table':
          final rowsDynamic = block['rows'] as List? ?? [];
          if (rowsDynamic.isEmpty) break;
          final rows = rowsDynamic
              .map((r) => (r as List)
                  .map((c) => Map<String, String>.from(c as Map))
                  .toList())
              .toList();
          final headerRow = block['headerRow'] == true;
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.TableHelper.fromTextArray(
              headers: headerRow && rows.isNotEmpty
                  ? rows.first.map((c) => c['text'] ?? '').toList()
                  : null,
              data: (headerRow && rows.isNotEmpty ? rows.skip(1) : rows)
                  .map((r) => r.map((c) => c['text'] ?? '').toList())
                  .toList(),
              cellStyle: pw.TextStyle(fontSize: 12, color: defaultColor),
              headerStyle: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: defaultColor),
              border: pw.TableBorder.all(
                  color: PdfColors.grey600, width: 0.5),
            ),
          ));
          break;
        case 'image':
          final src = (block['src'] ?? '').toString();
          final loaded = HtmlImageLoader.load(src);
          if (loaded != null) {
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(loaded.bytes),
                  height: 260,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ));
          }
          break;
      }
    }
    return widgets;
  }

  pw.TextStyle _runStyle(
      Map<String, String> run, double defaultSize, PdfColor? defaultColor) {
    double size = defaultSize;
    final sz = run['size'];
    if (sz != null && sz.isNotEmpty) {
      final parsed = int.tryParse(sz);
      if (parsed != null) size = parsed / 100.0;
    }
    PdfColor? color = defaultColor;
    final hex = run['color'];
    if (hex != null && hex.isNotEmpty) {
      color = PdfColor.fromHex(hex);
    }
    return pw.TextStyle(
      fontSize: size,
      fontWeight:
          run['bold'] == 'true' ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle:
          run['italic'] == 'true' ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: run['underline'] == 'true'
          ? pw.TextDecoration.underline
          : (run['strike'] == 'true' ? pw.TextDecoration.lineThrough : null),
      color: color,
    );
  }

  PdfColor? _extractBgColor(String html) {
    final match = RegExp(r"""data-bg-color=["']([^"']+)["']""",
            caseSensitive: false)
        .firstMatch(html);
    if (match == null) return null;
    final hex = PPTGenerator.cssColorToHex(match.group(1)!);
    if (hex == null) return null;
    try {
      return PdfColor.fromHex(hex);
    } catch (_) {
      return null;
    }
  }

  /// Pick black or white text depending on background luminance.
  PdfColor _contrastColor(PdfColor bg) {
    final luminance = 0.299 * bg.red + 0.587 * bg.green + 0.114 * bg.blue;
    return luminance > 0.5 ? PdfColors.black : PdfColors.white;
  }
}
