import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import '../models/export_options.dart';
import 'effect_preview_service.dart';
import '../models/slide.dart';
import 'html_image_loader.dart';
import 'ppt_generator.dart';

class HtmlExportService {
  static const String _defaultFileName = 'presentation';

  Future<String> exportToHtml(
    List<Map<String, dynamic>> slides, {
    String? fileName,
    ExportAspectRatio aspectRatio = ExportAspectRatio.widescreen16x9,
    bool includeNotes = false,
    bool includeBackgrounds = true,
    int? imageMaxWidth,
  }) async {
    if (slides.isEmpty) {
      throw Exception('No slides to export.');
    }

    final safeName = (fileName ?? _defaultFileName).replaceAll(
      RegExp(r'[^\w.\-]'),
      '_',
    );
    final htmlContent = _buildHtmlPresentation(
      slides,
      aspectRatio: aspectRatio,
      includeNotes: includeNotes,
      includeBackgrounds: includeBackgrounds,
      imageMaxWidth: imageMaxWidth,
    );

    final Directory targetDir = await getApplicationDocumentsDirectory();
    final String fullPath = '${targetDir.path}/$safeName.html';
    final File htmlFile = File(fullPath);
    await htmlFile.create(recursive: true);
    await htmlFile.writeAsString(htmlContent, flush: true);
    return htmlFile.path;
  }

  /// Export the HTML deck to an explicit file path (save-as dialog).
  Future<String> exportToHtmlPath(
    List<Map<String, dynamic>> slides,
    String filePath, {
    ExportAspectRatio aspectRatio = ExportAspectRatio.widescreen16x9,
    bool includeNotes = false,
    bool includeBackgrounds = true,
    int? imageMaxWidth,
  }) async {
    if (slides.isEmpty) {
      throw Exception('No slides to export.');
    }
    final htmlContent = _buildHtmlPresentation(
      slides,
      aspectRatio: aspectRatio,
      includeNotes: includeNotes,
      includeBackgrounds: includeBackgrounds,
      imageMaxWidth: imageMaxWidth,
    );
    final File htmlFile = File(filePath);
    await htmlFile.create(recursive: true);
    await htmlFile.writeAsString(htmlContent, flush: true);
    return htmlFile.path;
  }

  /// Build the standalone presentation HTML (used by in-app present mode).
  ///
  /// [startIndex] selects the first visible slide (for "Present From Current");
  /// [autoAdvance] enables automatic slide advancement in the embedded player.
  String buildPresentationHtml(
    List<Map<String, dynamic>> slides, {
    int startIndex = 0,
    Duration? autoAdvance,
  }) {
    return _buildHtmlPresentation(
      slides,
      startIndex: startIndex,
      autoAdvance: autoAdvance,
    );
  }

  String _buildHtmlPresentation(
    List<Map<String, dynamic>> slides, {
    int startIndex = 0,
    Duration? autoAdvance,
    ExportAspectRatio aspectRatio = ExportAspectRatio.widescreen16x9,
    bool includeNotes = false,
    bool includeBackgrounds = true,
    int? imageMaxWidth,
  }) {
    final buffer = StringBuffer();
    // Clamp safely — the caller guards against empty decks, but keep this
    // robust in case a deck becomes empty between build and render.
    final int initIndex =
        slides.isEmpty ? 0 : startIndex.clamp(0, slides.length - 1).toInt();
    final int autoMs = autoAdvance?.inMilliseconds ?? 0;

    // Collect per-slide background colors and transition effects
    final slideBgStyles = <String>[];
    final slideTransitions = <String>[];
    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      final color = includeBackgrounds ? _extractSlideBgColor(slide) : null;
      if (color != null) {
        slideBgStyles.add('#slide-$i { background-color: #$color; }');
      }
      // Parse per-slide transition effect
      final effectName = slides[i]['effect'] as String?;
      if (effectName != null && effectName.isNotEmpty && effectName != 'none') {
        try {
          final effect = SlideEffect.values.byName(effectName);
          slideTransitions.add('"slide-$i": "${effect.name}"');
        } catch (_) {}
      }
    }

    final bgStylesBlock = slideBgStyles.join('\n  ');
    final transitionBlock = slideTransitions.join(',');

    // Generate CSS for all effects
    final effectsCss =
        EffectPreviewService.generateAllEffectsCss(duration: 0.6);

    buffer.write('<!DOCTYPE html>');
    buffer.write('<html lang="en">');
    buffer.write('<head>');
    buffer.write('<meta charset="UTF-8">');
    buffer.write(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.write('<title>Presentation</title>');
    buffer.write('<style>');
    buffer.write('  * { margin: 0; padding: 0; box-sizing: border-box; }');
    buffer.write('  body {');
    buffer.write(
        "    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;");
    buffer.write('    background: #1a1a2e;');
    buffer.write('    overflow: hidden;');
    buffer.write('    height: 100vh;');
    buffer.write('    width: 100vw;');
    buffer.write('    display: grid;');
    buffer.write('    place-items: center;');
    buffer.write('  }');
    buffer.write('  .deck {');
    buffer.write('    position: relative;');
    buffer.write('    aspect-ratio: ${aspectRatio.cssAspectRatio};');
    buffer.write('    width: min(100vw, calc(100vh * ${aspectRatio.ratio}));');
    buffer.write('    height: auto;');
    buffer.write('    overflow: hidden;');
    buffer.write('  }');
    buffer.write('  .slide {');
    buffer.write('    position: absolute;');
    buffer.write('    top: 0; left: 0;');
    buffer.write('    width: 100%;');
    buffer.write('    height: 100%;');
    buffer.write('    display: none;');
    buffer.write('    padding: 5vh 8vw;');
    buffer.write('    overflow-y: auto;');
    buffer.write('    color: #e0e0e0;');
    buffer.write('    animation: fadeIn 0.5s ease;');
    buffer.write('  }');
    buffer.write(
        '  .slide.active { display: flex; flex-direction: column; justify-content: center; }');
    buffer.write('  @keyframes fadeIn {');
    buffer.write('    from { opacity: 0; transform: translateY(10px); }');
    buffer.write('    to { opacity: 1; transform: translateY(0); }');
    buffer.write('  }');
    buffer.write('  .slide h1 {');
    buffer.write('    font-size: clamp(1.8rem, 4vw, 3.5rem);');
    buffer.write('    font-weight: 700;');
    buffer.write('    margin-bottom: 0.3em;');
    buffer.write('    line-height: 1.2;');
    buffer.write('    color: #ffffff;');
    buffer.write('  }');
    buffer.write('  .slide h2 {');
    buffer.write('    font-size: clamp(1.2rem, 2.5vw, 2rem);');
    buffer.write('    font-weight: 500;');
    buffer.write('    margin-bottom: 1em;');
    buffer.write('    color: #cccccc;');
    buffer.write('    font-style: italic;');
    buffer.write('  }');
    buffer.write('  .slide p {');
    buffer.write('    font-size: clamp(0.95rem, 1.8vw, 1.4rem);');
    buffer.write('    line-height: 1.7;');
    buffer.write('    margin-bottom: 0.8em;');
    buffer.write('    color: #d0d0d0;');
    buffer.write('  }');
    buffer.write('  .slide b, .slide strong { color: #ffffff; }');
    buffer.write('  .slide i, .slide em { color: #bbbbbb; }');
    buffer.write('  .slide ul, .slide ol {');
    buffer.write('    margin: 0.5em 0 0.5em 1.5em;');
    buffer.write('    font-size: clamp(0.95rem, 1.8vw, 1.4rem);');
    buffer.write('    line-height: 1.8;');
    buffer.write('  }');
    buffer.write('  .slide li { margin-bottom: 0.4em; }');
    buffer.write('  .slide ul li { list-style-type: disc; }');
    buffer.write('  .slide ol li { list-style-type: decimal; }');
    buffer.write('  .slide table {');
    buffer.write('    width: 80%;');
    buffer.write('    border-collapse: collapse;');
    buffer.write('    margin: 1em 0;');
    buffer.write('    font-size: clamp(0.85rem, 1.5vw, 1.2rem);');
    buffer.write('  }');
    buffer.write('  .slide th, .slide td {');
    buffer.write('    padding: 10px 14px;');
    buffer.write('    border: 1px solid rgba(255,255,255,0.2);');
    buffer.write('    text-align: left;');
    buffer.write('  }');
    buffer.write('  .slide th {');
    buffer.write('    background: rgba(255,255,255,0.1);');
    buffer.write('    font-weight: 600;');
    buffer.write('    color: #ffffff;');
    buffer.write('  }');
    buffer.write('  .controls {');
    buffer.write('    position: fixed;');
    buffer.write('    bottom: 20px;');
    buffer.write('    left: 50%;');
    buffer.write('    transform: translateX(-50%);');
    buffer.write('    display: flex;');
    buffer.write('    align-items: center;');
    buffer.write('    gap: 12px;');
    buffer.write('    background: rgba(0,0,0,0.6);');
    buffer.write('    backdrop-filter: blur(12px);');
    buffer.write('    padding: 10px 20px;');
    buffer.write('    border-radius: 50px;');
    buffer.write('    z-index: 100;');
    buffer.write('    border: 1px solid rgba(255,255,255,0.1);');
    buffer.write('  }');
    buffer.write('  .controls button {');
    buffer.write('    background: rgba(255,255,255,0.15);');
    buffer.write('    border: none;');
    buffer.write('    color: white;');
    buffer.write('    width: 40px; height: 40px;');
    buffer.write('    border-radius: 50%;');
    buffer.write('    cursor: pointer;');
    buffer.write('    font-size: 18px;');
    buffer.write('    display: flex;');
    buffer.write('    align-items: center;');
    buffer.write('    justify-content: center;');
    buffer.write('    transition: all 0.2s;');
    buffer.write('  }');
    buffer.write(
        '  .controls button:hover { background: rgba(255,255,255,0.3); }');
    buffer.write(
        '  .controls button:disabled { opacity: 0.3; cursor: not-allowed; }');
    buffer.write(
        '  .controls button.auto-armed { background: rgba(102,126,234,0.5); }');
    buffer.write('  .slide-counter {');
    buffer.write('    color: #ccc;');
    buffer.write('    font-size: 14px;');
    buffer.write('    min-width: 60px;');
    buffer.write('    text-align: center;');
    buffer.write('    font-variant-numeric: tabular-nums;');
    buffer.write('  }');
    buffer.write('  .progress-bar {');
    buffer.write('    position: fixed;');
    buffer.write('    top: 0; left: 0;');
    buffer.write('    height: 3px;');
    buffer.write('    background: linear-gradient(90deg, #667eea, #764ba2);');
    buffer.write('    transition: width 0.3s ease;');
    buffer.write('    z-index: 100;');
    buffer.write('  }');
    buffer.write('  .fullscreen-btn {');
    buffer.write('    position: fixed;');
    buffer.write('    top: 16px;');
    buffer.write('    right: 16px;');
    buffer.write('    background: rgba(0,0,0,0.5);');
    buffer.write('    border: 1px solid rgba(255,255,255,0.2);');
    buffer.write('    color: white;');
    buffer.write('    padding: 8px 14px;');
    buffer.write('    border-radius: 8px;');
    buffer.write('    cursor: pointer;');
    buffer.write('    font-size: 13px;');
    buffer.write('    z-index: 100;');
    buffer.write('    backdrop-filter: blur(8px);');
    buffer.write('  }');
    buffer.write('  .fullscreen-btn:hover { background: rgba(0,0,0,0.7); }');
    buffer.write(
        '  .speaker-notes { display: none; margin-top: 1rem; padding: 0.8rem; border-left: 3px solid #667eea; background: rgba(0,0,0,0.24); color: #f1f1f1; font-size: 0.9rem; white-space: pre-wrap; }');
    buffer.write('  .slide.notes-visible .speaker-notes { display: block; }');
    if (bgStylesBlock.isNotEmpty) {
      buffer.write('  $bgStylesBlock');
    }
    // Add effects CSS
    buffer.write('\n  /* Slide transition effects */');
    buffer.write('\n  $effectsCss');
    buffer.write('</style>');
    buffer.write('</head>');
    buffer.write('<body>');
    buffer.write('<div class="progress-bar" id="progressBar"></div>');
    buffer.write(
        '<button class="fullscreen-btn" onclick="toggleFullscreen()" title="Fullscreen">&#x26F6; Fullscreen</button>');
    buffer.write('<div class="deck" id="deck">');

    final hasNotes =
        includeNotes && slides.any((slide) => _speakerNotes(slide).isNotEmpty);
    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      final title = slide['title'] ?? 'Slide ${i + 1}';
      final rawHtml = slide['htmlContent'] ?? '';
      final cleanTitle = _xmlEscape(title.toString());
      final processedContent = _processSlideHtml(
        rawHtml.toString(),
        imageMaxWidth: imageMaxWidth,
      );
      final notes = includeNotes ? _speakerNotes(slide) : '';

      // Get transition class for this slide
      String transitionClass = '';
      final effectName = slide['effect'] as String?;
      if (effectName != null && effectName.isNotEmpty && effectName != 'none') {
        transitionClass = ' slide-transition-$effectName';
      }

      buffer.write('  <div class="slide$transitionClass" id="slide-$i">');
      buffer.write('    <h1>$cleanTitle</h1>');
      buffer.write('    $processedContent');
      if (notes.isNotEmpty) {
        buffer.write(
            '    <aside class="speaker-notes">${_htmlEscape(notes)}</aside>');
      }
      buffer.write('  </div>');
    }

    buffer.write('</div>');
    buffer.write('<div class="controls">');
    buffer.write(
        '  <button id="prevBtn" onclick="changeSlide(-1)" title="Previous">&#x25C0;</button>');
    buffer.write(
        '  <span class="slide-counter" id="counter">1 / ${slides.length}</span>');
    // Auto-advance toggle (only shown when the deck is configured with timing).
    if (autoMs > 0) {
      buffer.write(
          '  <button id="autoBtn" class="auto-armed" onclick="toggleAuto()" title="Pause auto-play">&#10074;&#10074; Auto</button>');
    }
    if (hasNotes) {
      buffer.write(
          '  <button id="notesBtn" onclick="toggleNotes()" title="Show or hide speaker notes">Notes</button>');
    }
    buffer.write(
        '  <button id="nextBtn" onclick="changeSlide(1)" title="Next">&#x25B6;</button>');
    buffer.write('</div>');
    buffer.write('<script>');
    buffer.write('  let currentSlide = 0;');
    buffer.write('  const totalSlides = ${slides.length};');
    buffer.write('  const deck = document.getElementById("deck");');
    buffer.write('  const counter = document.getElementById("counter");');
    buffer
        .write('  const progressBar = document.getElementById("progressBar");');
    buffer.write('  const prevBtn = document.getElementById("prevBtn");');
    buffer.write('  const nextBtn = document.getElementById("nextBtn");');
    buffer.write('  const autoBtn = document.getElementById("autoBtn");');
    buffer.write('  const notesBtn = document.getElementById("notesBtn");');
    buffer.write('  let autoMs = $autoMs;');
    buffer.write('  let autoTimer = null;');
    buffer.write('  let autoPaused = false;');
    buffer.write('  const transitionMap = { $transitionBlock };');
    buffer.write('  function scheduleAuto() {');
    buffer.write(
        '    if (autoTimer) { clearTimeout(autoTimer); autoTimer = null; }');
    buffer.write(
        '    if (autoMs > 0 && !autoPaused && currentSlide < totalSlides - 1) {');
    buffer.write('      autoTimer = setTimeout(() => changeSlide(1), autoMs);');
    buffer.write('    }');
    buffer.write('  }');
    buffer.write('  function toggleAuto() {');
    buffer.write('    if (autoMs <= 0 || !autoBtn) return;');
    buffer.write('    autoPaused = !autoPaused;');
    buffer.write(
        '    if (autoTimer) { clearTimeout(autoTimer); autoTimer = null; }');
    buffer.write('    if (!autoPaused) scheduleAuto();');
    buffer.write('    autoBtn.classList.toggle("auto-armed", !autoPaused);');
    buffer.write(
        '    autoBtn.title = autoPaused ? "Resume auto-play" : "Pause auto-play";');
    buffer.write(
        '    autoBtn.innerHTML = (autoPaused ? "&#9654;" : "&#10074;&#10074;") + " Auto";');
    buffer.write('  }');
    buffer.write('  function showSlide(index) {');
    buffer.write('    if (index < 0 || index >= totalSlides) return;');
    buffer.write('    deck.querySelectorAll(".slide").forEach(s => {');
    buffer.write('      s.classList.remove("active");');
    buffer.write(
        '      // Remove and re-add transition class to re-trigger animation');
    buffer.write(
        '      const cls = s.className.split(" ").filter(c => !c.startsWith("slide-transition-"));');
    buffer.write('      s.className = cls.join(" ");');
    buffer.write('    });');
    buffer
        .write('    const slide = document.getElementById("slide-" + index);');
    buffer.write('    if (slide) {');
    buffer.write('      // Force reflow to restart animation');
    buffer.write('      void slide.offsetWidth;');
    buffer.write('      // Re-apply transition class');
    buffer.write('      const eff = transitionMap["slide-" + index];');
    buffer.write(
        '      if (eff) slide.classList.add("slide-transition-" + eff);');
    buffer.write('      slide.classList.add("active");');
    buffer.write('      slide.scrollTop = 0;');
    buffer.write('    }');
    buffer.write('    currentSlide = index;');
    buffer
        .write('    counter.textContent = (index + 1) + " / " + totalSlides;');
    buffer.write(
        '    progressBar.style.width = ((index + 1) / totalSlides * 100) + "%";');
    buffer.write('    prevBtn.disabled = index === 0;');
    buffer.write('    nextBtn.disabled = index === totalSlides - 1;');
    buffer.write('    scheduleAuto();');
    buffer.write('  }');
    buffer.write('  function changeSlide(delta) {');
    buffer.write('    showSlide(currentSlide + delta);');
    buffer.write('  }');
    buffer.write('  function toggleNotes() {');
    buffer.write(
        '    const slide = document.getElementById("slide-" + currentSlide);');
    buffer.write('    if (slide) slide.classList.toggle("notes-visible");');
    buffer.write('  }');
    buffer.write('  function toggleFullscreen() {');
    buffer.write('    if (!document.fullscreenElement) {');
    buffer.write(
        '      document.documentElement.requestFullscreen().catch(() => {});');
    buffer.write('    } else {');
    buffer.write('      document.exitFullscreen();');
    buffer.write('    }');
    buffer.write('  }');
    buffer.write('  document.addEventListener("keydown", (e) => {');
    buffer.write(
        '    if (e.key === "ArrowRight" || e.key === " " || e.key === "PageDown") {');
    buffer.write('      e.preventDefault(); changeSlide(1);');
    buffer
        .write('    } else if (e.key === "ArrowLeft" || e.key === "PageUp") {');
    buffer.write('      e.preventDefault(); changeSlide(-1);');
    buffer.write('    } else if (e.key === "Home") {');
    buffer.write('      e.preventDefault(); showSlide(0);');
    buffer.write('    } else if (e.key === "End") {');
    buffer.write('      e.preventDefault(); showSlide(totalSlides - 1);');
    buffer.write('    } else if (e.key === "f" || e.key === "F") {');
    buffer.write('      toggleFullscreen();');
    buffer.write('    }');
    buffer.write('  });');
    buffer.write('  let touchStartX = 0;');
    buffer.write(
        '  deck.addEventListener("touchstart", (e) => { touchStartX = e.touches[0].clientX; });');
    buffer.write('  deck.addEventListener("touchend", (e) => {');
    buffer.write('    const diff = touchStartX - e.changedTouches[0].clientX;');
    buffer
        .write('    if (Math.abs(diff) > 50) changeSlide(diff > 0 ? 1 : -1);');
    buffer.write('  });');
    buffer.write('  showSlide($initIndex);');
    buffer.write('</script>');
    buffer.write('</body>');
    buffer.write('</html>');

    return buffer.toString();
  }

  String? _extractSlideBgColor(Map<String, dynamic> slide) {
    final typed =
        PPTGenerator.cssColorToHex((slide['bgColor'] ?? '').toString());
    if (typed != null) return typed;
    final html = (slide['htmlContent'] ?? '').toString();
    final match =
        RegExp(r"""data-bg-color=["']([^"']+)["']""", caseSensitive: false)
            .firstMatch(html);
    return match == null ? null : PPTGenerator.cssColorToHex(match.group(1)!);
  }

  String _speakerNotes(Map<String, dynamic> slide) {
    final explicit = (slide['notes'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    return PPTGenerator.extractNotes((slide['htmlContent'] ?? '').toString());
  }

  String _processSlideHtml(String rawHtml, {int? imageMaxWidth}) {
    final document = html_parser.parse(rawHtml);
    final body = document.body;
    if (body == null) return '';

    for (final aside in body.querySelectorAll('aside.notes')) {
      aside.remove();
    }
    for (final image in body.querySelectorAll('img')) {
      final loaded = HtmlImageLoader.load(
        image.attributes['src'] ?? '',
        maxWidth: imageMaxWidth,
      );
      if (loaded != null) {
        image.attributes['src'] =
            'data:image/${loaded.ext};base64,${base64Encode(loaded.bytes)}';
      }
    }

    var processed = body.innerHtml;

    // Remove data-bg-color attributes (both single and double quotes)
    processed = processed.replaceAll(
      RegExp(r'data-bg-color="[^"]*"', caseSensitive: false),
      '',
    );
    processed = processed.replaceAll(
      RegExp(r"data-bg-color='[^']*'", caseSensitive: false),
      '',
    );

    // Remove empty divs
    processed = processed.replaceAll(
      RegExp(r'<div[^>]*>\s*</div>', caseSensitive: false),
      '',
    );

    // Clean up excessive breaks
    processed = processed.replaceAll(
      RegExp(r'(<br\s*/?>\s*){3,}', caseSensitive: false),
      '<br><br>',
    );

    return processed.trim();
  }

  static String _htmlEscape(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('\n', '<br>');

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
