import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/services/html_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider MethodChannel
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  final List<MethodCall> log = <MethodCall>[];

  channel.setMockMethodCallHandler((MethodCall call) async {
    log.add(call);
    if (call.method == 'getApplicationDocumentsDirectory') {
      // Return a real existing temp directory
      return Directory.systemTemp.path;
    }
    return null;
  });

  group('HtmlExportService', () {
    late HtmlExportService service;

    setUp(() {
      service = HtmlExportService();
    });

    test('throws on empty slides', () async {
      expect(
        () => service.exportToHtml([]),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No slides'))),
      );
    });

    test('generates valid HTML structure', () async {
      final slides = [
        {
          'title': 'Test Slide',
          'htmlContent': '<p>Hello world</p>',
        },
      ];

      final path = await service.exportToHtml(slides, fileName: 'test_export');
      expect(File(path).existsSync(), isTrue);
      final content = File(path).readAsStringSync();

      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('<html'));
      expect(content, contains('Test Slide'));
      expect(content, contains('Hello world'));
      expect(content, contains('class="deck"'));
      expect(content, contains('id="slide-0"'));
      expect(content, contains('changeSlide'));
      expect(content, contains('</html>'));
    });

    test('handles background colors from data-bg-color', () async {
      final slides = [
        {
          'title': 'Colored Slide',
          'htmlContent': '<div data-bg-color="#ff0000"><p>Red slide</p></div>',
        },
      ];

      final path = await service.exportToHtml(slides, fileName: 'test_bg');
      final content = File(path).readAsStringSync();

      expect(content, contains('#slide-0'));
      expect(content, contains('background-color: #ff0000'));
    });

    test('includes navigation controls', () async {
      final slides = [
        {'title': 'Slide 1', 'htmlContent': '<p>A</p>'},
        {'title': 'Slide 2', 'htmlContent': '<p>B</p>'},
      ];

      final path = await service.exportToHtml(slides, fileName: 'test_nav');
      final content = File(path).readAsStringSync();

      expect(content, contains('totalSlides = 2'));
      expect(content, contains('changeSlide'));
      expect(content, contains('prevBtn'));
      expect(content, contains('nextBtn'));
      expect(content, contains('toggleFullscreen'));
    });

    test('handles special characters in file name', () async {
      final slides = [
        {'title': 'Test', 'htmlContent': '<p>Content</p>'},
      ];

      final path = await service.exportToHtml(slides, fileName: 'my presentation!');
      final name = File(path).uri.pathSegments.last;
      expect(name, contains('my_presentation_'));
      expect(name, endsWith('.html'));
    });
  });
}
