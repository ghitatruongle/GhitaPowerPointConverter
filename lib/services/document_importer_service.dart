import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/slide.dart';

/// Omni-Importer Service: converts raw text, Markdown, HTML, Web URLs, and documents into presentation slides.
class DocumentImporterService {
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
        htmlBuffer.writeln('<h1>$title</h1>');
        bool inList = false;
        for (final line in currentBody) {
          final trimmed = line.trim();
          if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            if (!inList) {
              htmlBuffer.writeln('<ul>');
              inList = true;
            }
            htmlBuffer.writeln('  <li>${trimmed.substring(2)}</li>');
          } else {
            if (inList) {
              htmlBuffer.writeln('</ul>');
              inList = false;
            }
            if (trimmed.isNotEmpty) {
              htmlBuffer.writeln('<p>$trimmed</p>');
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
      if (RegExp(r'^#{1,6}\s+').hasMatch(line)) {
        pushCurrentSlide();
        currentTitle = line.replaceAll(RegExp(r'^#+\s*'), '').trim();
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
              htmlContent: '<h1>Imported Document</h1><p>$markdownText</p>',
            )
          ];
  }

  /// Scrapes content from a Web URL and converts key headers into slides.
  Future<List<Slide>> importFromWebUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
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
              htmlContent: '<h1>$heading</h1><p>Key takeaways extracted from $url</p>',
            ));
          }
        }

        if (slides.isNotEmpty) return slides;
        return [
          Slide(
            title: title,
            htmlContent: '<h1>$title</h1><p>Scraped content from $url</p>',
          )
        ];
      }
    } catch (e) {
      debugPrint('DocumentImporterService Error scraping web URL: $e');
    }
    return [
      Slide(
        title: 'Web Import Error',
        htmlContent: '<h1>Unable to load URL</h1><p>Could not fetch content from $url</p>',
      )
    ];
  }
}
