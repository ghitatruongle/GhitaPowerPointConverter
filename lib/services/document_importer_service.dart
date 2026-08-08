import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/slide.dart';

/// Omni-Importer Service: converts raw text, Markdown, HTML, Web URLs, and documents into presentation slides.
class DocumentImporterService {
  /// Escape user text before embedding into generated HTML — imported
  /// content containing `<`, `>`, `&` or `"` previously broke the slide
  /// markup or injected arbitrary HTML into the deck.
  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Parses Markdown content and chunks headers/bullets into typed Slide objects.
  List<Slide> parseMarkdownToSlides(String markdownText) {
    final List<Slide> slides = [];
    final lines = markdownText.split('\n');
    String currentTitle = '';
    final List<String> currentBody = [];

    void pushCurrentSlide() {
      if (currentTitle.isNotEmpty || currentBody.isNotEmpty) {
        final title = currentTitle.isNotEmpty ? currentTitle : 'Slide ${slides.length + 1}';
        final htmlBuffer = StringBuffer();
        htmlBuffer.writeln('<h1>${_esc(title)}</h1>');
        bool inList = false;
        for (final line in currentBody) {
          final trimmed = line.trim();
          if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            if (!inList) {
              htmlBuffer.writeln('<ul>');
              inList = true;
            }
            htmlBuffer.writeln('  <li>${_esc(trimmed.substring(2))}</li>');
          } else {
            if (inList) {
              htmlBuffer.writeln('</ul>');
              inList = false;
            }
            if (trimmed.isNotEmpty) {
              htmlBuffer.writeln('<p>${_esc(trimmed)}</p>');
            }
          }
        }
        if (inList) {
          htmlBuffer.writeln('</ul>');
        }

        slides.add(Slide(
          title: title,
          htmlContent: htmlBuffer.toString(),
        ));
      }
      currentTitle = '';
      currentBody.clear();
    }

    for (final line in lines) {
      // Accept '#Title' (no space) and '#' — previously only '# Title'
      // (with a required space after #) was recognized as a heading.
      if (RegExp(r'^#{1,6}(\s+.*|.*)$').hasMatch(line.trim()) &&
          line.trim().startsWith('#')) {
        pushCurrentSlide();
        currentTitle = line.trim().replaceAll(RegExp(r'^#+\s*'), '').trim();
      } else {
        currentBody.add(line);
      }
    }
    pushCurrentSlide();

    return slides.isNotEmpty
        ? slides
        : [
            Slide(
              title: 'Imported Document',
              htmlContent: '<h1>Imported Document</h1><p>${_esc(markdownText)}</p>',
            )
          ];
  }

  /// Scrapes content from a Web URL and converts key headers into slides.
  Future<List<Slide>> importFromWebUrl(String url) async {
    // Use a dedicated client so the timeout also aborts the underlying
    // download (http.get().timeout() only abandons the await and leaks
    // the in-flight connection).
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final html = response.body;
        // Extract title using regex
        final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(html);
        final title = titleMatch?.group(1) ?? 'Web Import';

        // Extract headings
        final headingMatches = RegExp(r'<h[12][^>]*>(.*?)</h[12]>', caseSensitive: false)
            .allMatches(html);

        final List<Slide> slides = [];
        for (final m in headingMatches) {
          final heading = m.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
          if (heading.isNotEmpty) {
            slides.add(Slide(
              title: heading,
              htmlContent: '<h1>${_esc(heading)}</h1><p>Key takeaways extracted from ${_esc(url)}</p>',
            ));
          }
        }

        if (slides.isNotEmpty) return slides;
        return [
          Slide(
            title: title,
            htmlContent: '<h1>${_esc(title)}</h1><p>Scraped content from ${_esc(url)}</p>',
          )
        ];
      }
    } catch (e) {
      debugPrint('DocumentImporterService Error scraping web URL: $e');
    } finally {
      client.close();
    }
    return [
      Slide(
        title: 'Web Import Error',
        htmlContent: '<h1>Unable to load URL</h1><p>Could not fetch content from ${_esc(url)}</p>',
      )
    ];
  }
}
