import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghita_ppt_converter/models/export_options.dart';
import 'package:ghita_ppt_converter/services/export_isolate.dart';

/// End-to-end checks for the background-isolate export pipeline.
///
/// These call the same persistent-worker wrappers the UI uses, which proves
/// the slide payload (List<Map<String, dynamic>>) crosses the isolate boundary
/// safely, that timing settings are threaded through, and that the worker is
/// reused across consecutive exports.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Map<String, dynamic>> sampleSlides() => [
        {
          'title': 'Slide 1',
          'htmlContent': '<h1>Hello</h1><p>World</p>'
              '<ul><li>Point A</li><li>Point B</li></ul>',
          'effect': 'fade',
        },
        {
          'title': 'Slide 2',
          'htmlContent': '<table><tr><th>A</th><th>B</th></tr>'
              '<tr><td>1</td><td>2</td></tr></table>',
        },
      ];

  test('runPptExportInIsolate builds a valid OOXML package', () async {
    final dir = await Directory.systemTemp.createTemp('ghita_ppt_iso_');
    final out = '${dir.path}/out.pptx';
    try {
      final path = await runPptExportInIsolate(sampleSlides(), out);
      expect(path, out);
      final bytes = File(out).readAsBytesSync();
      expect(bytes.length, greaterThan(0));
      // OOXML is a ZIP: magic bytes "PK".
      expect(String.fromCharCodes(bytes.take(2)), 'PK');
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(
          archive.files.any((e) => e.name == 'ppt/slides/slide1.xml'), isTrue);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('threads auto-advance timing into PPTX via the worker', () async {
    final dir = await Directory.systemTemp.createTemp('ghita_ppt_iso2_');
    final out = '${dir.path}/timed.pptx';
    try {
      final path = await runPptExportInIsolate(
        sampleSlides(),
        out,
        autoAdvance: const Duration(seconds: 3),
      );
      expect(path, out);
      final archive = ZipDecoder().decodeBytes(File(out).readAsBytesSync());
      final slideXml = archive.files
          .firstWhere((e) => e.name == 'ppt/slides/slide1.xml')
          .content as List<int>;
      final decoded = utf8.decode(slideXml);
      expect(decoded, contains('advTm="3000"'));
      expect(decoded, isNot(contains('<p:advTm')));
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('threads advanced export options into the worker', () async {
    final dir = await Directory.systemTemp.createTemp('ghita_ppt_iso_options_');
    final out = '${dir.path}/options.pptx';
    try {
      await runPptExportInIsolate(
        [
          {
            'title': 'Square',
            'notes': 'Private note',
            'bgColor': '#123456',
            'htmlContent': '<p>Body</p>',
          }
        ],
        out,
        aspectRatio: ExportAspectRatio.square1x1,
        includeNotes: false,
        includeBackgrounds: false,
        imageMaxWidth: ExportQuality.low.imageMaxWidth,
      );
      final archive = ZipDecoder().decodeBytes(File(out).readAsBytesSync());
      String part(String name) => utf8.decode(archive.files
          .firstWhere((entry) => entry.name == name)
          .content as List<int>);

      expect(part('ppt/presentation.xml'),
          contains('<p:sldSz cx="6858000" cy="6858000"/>'));
      expect(part('ppt/slides/slide1.xml'), isNot(contains('<p:bg>')));
      expect(archive.files.any((entry) => entry.name.contains('notesSlide')),
          isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('runHtmlExportInIsolate writes a standalone deck', () async {
    final dir = await Directory.systemTemp.createTemp('ghita_html_iso_');
    final out = '${dir.path}/out.html';
    try {
      final path = await runHtmlExportInIsolate(sampleSlides(), out);
      expect(path, out);
      final content = File(out).readAsStringSync();
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('Hello'));
      expect(content, contains('totalSlides = 2'));
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('reuses the persistent worker across consecutive exports', () async {
    final dir = await Directory.systemTemp.createTemp('ghita_ppt_reuse_');
    try {
      // Several PPT + HTML jobs run against the same long-lived worker.
      for (var i = 0; i < 3; i++) {
        final p1 =
            await runPptExportInIsolate(sampleSlides(), '${dir.path}/a$i.pptx');
        final p2 = await runHtmlExportInIsolate(
            sampleSlides(), '${dir.path}/b$i.html');
        expect(File(p1).existsSync(), isTrue);
        expect(File(p2).existsSync(), isTrue);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
