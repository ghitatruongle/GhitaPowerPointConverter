import 'dart:async';
import 'dart:isolate';
import '../models/export_options.dart';
import '../models/slide.dart';
import 'html_export_service.dart';
import 'pdf_export_service.dart';
import 'ppt_generator.dart';

// Background-isolate entry points for the heavy export pipeline.
//
// PPTX/PDF generation (and HTML file export) does HTML parsing, image
// decoding and byte packing that can block the UI on large decks. These
// wrappers run the same services off the UI isolate.
//
// All services involved ([PPTGenerator], [PdfExportService],
// [HtmlExportService], [HtmlImageLoader]) are pure Dart (dart:io + the
// archive/html/image/pdf packages) and are therefore safe to run off the UI
// isolate.

typedef _ExportJob = Map<String, dynamic>;

/// Export slides to PPTX on the background worker isolate.
/// Returns the output file path.
Future<String> runPptExportInIsolate(
  List<Map<String, dynamic>> slides,
  String outputPath, {
  SlideEffect effect = SlideEffect.none,
  bool widescreen = true,
  ExportAspectRatio? aspectRatio,
  bool includeNotes = true,
  bool includeBackgrounds = true,
  int? imageMaxWidth,
  Duration? autoAdvance,
}) async {
  final result = await ExportIsolateService.instance._runJob(<String, dynamic>{
    'type': 'ppt',
    'slides': slides,
    'outputPath': outputPath,
    'effect': effect.name,
    'widescreen': widescreen,
    'aspectRatio': aspectRatio?.name,
    'includeNotes': includeNotes,
    'includeBackgrounds': includeBackgrounds,
    'imageMaxWidth': imageMaxWidth,
    'autoAdvanceMs': autoAdvance?.inMilliseconds ?? 0,
  });
  if (result['ok'] == true) return result['path'] as String;
  throw Exception(result['error'] ?? 'PPT export failed');
}

/// Export slides to PDF on the background worker isolate.
/// Returns the output file path.
Future<String> runPdfExportInIsolate(
  List<Map<String, dynamic>> slides,
  String outputPath, {
  bool widescreen = true,
  ExportAspectRatio? aspectRatio,
  bool includeNotes = false,
  bool includeBackgrounds = true,
  int? imageMaxWidth,
}) async {
  final result = await ExportIsolateService.instance._runJob(<String, dynamic>{
    'type': 'pdf',
    'slides': slides,
    'outputPath': outputPath,
    'effect': 'none',
    'widescreen': widescreen,
    'aspectRatio': aspectRatio?.name,
    'includeNotes': includeNotes,
    'includeBackgrounds': includeBackgrounds,
    'imageMaxWidth': imageMaxWidth,
    'autoAdvanceMs': 0,
  });
  if (result['ok'] == true) return result['path'] as String;
  throw Exception(result['error'] ?? 'PDF export failed');
}

/// Export slides to a standalone HTML file on the background worker isolate.
/// Returns the output file path.
Future<String> runHtmlExportInIsolate(
  List<Map<String, dynamic>> slides,
  String outputPath, {
  ExportAspectRatio? aspectRatio,
  bool includeNotes = false,
  bool includeBackgrounds = true,
  int? imageMaxWidth,
}) async {
  final result = await ExportIsolateService.instance._runJob(<String, dynamic>{
    'type': 'html',
    'slides': slides,
    'outputPath': outputPath,
    'effect': 'none',
    'widescreen': true,
    'aspectRatio': aspectRatio?.name,
    'includeNotes': includeNotes,
    'includeBackgrounds': includeBackgrounds,
    'imageMaxWidth': imageMaxWidth,
    'autoAdvanceMs': 0,
  });
  if (result['ok'] == true) return result['path'] as String;
  throw Exception(result['error'] ?? 'HTML export failed');
}

/// A long-lived background isolate reused for every export.
///
/// Spawning one isolate per export wastes time re-loading the AOT snapshot and
/// — for PDF — re-parsing the Windows system fonts ([PdfExportService] caches
/// the theme in its static state, which only pays off when the isolate lives
/// across calls). Keeping one worker also means the expensive services run on
/// a dedicated isolate while the UI stays responsive.
class ExportIsolateService {
  ExportIsolateService._();

  static final ExportIsolateService instance = ExportIsolateService._();

  Isolate? _isolate;
  SendPort? _workerPort;
  Future<void> _queue = Future<void>.value();

  /// Serializes requests so concurrent exports can't interleave replies on the
  /// single shared worker port.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<SendPort> _ensureWorker() async {
    final cached = _workerPort;
    if (cached != null) return cached;

    final greeting = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
        _isolateMain,
        greeting.sendPort,
        debugName: 'ghita-export',
      );
      _isolate = isolate;
      // Wait for the worker to hand us its request port.
      final workerPort =
          await greeting.first.timeout(const Duration(seconds: 15));
      _workerPort = workerPort as SendPort;
      return _workerPort!;
    } catch (_) {
      // Failed to start or handshake — reset so the caller can retry.
      _disposeWorker();
      rethrow;
    } finally {
      greeting.close();
    }
  }

  void _disposeWorker() {
    _workerPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<Map<String, dynamic>> _runJob(_ExportJob job) {
    return _serialized(() async {
      final workerPort = await _ensureWorker();
      final reply = ReceivePort();
      try {
        workerPort.send(<String, dynamic>{...job, 'replyPort': reply.sendPort});
        final message = await reply.first.timeout(const Duration(minutes: 2));
        return Map<String, dynamic>.from(message as Map);
      } on TimeoutException {
        // The worker likely died mid-job — drop it and let the next call
        // spawn a fresh one.
        _disposeWorker();
        rethrow;
      } finally {
        reply.close();
      }
    });
  }
}

/// Worker isolate main loop: answers one export request per message and stays
/// alive until the app shuts down (or the isolate is killed).
///
/// Top-level + entry-point annotation so release (AOT) builds keep it.
@pragma('vm:entry-point')
Future<void> _isolateMain(SendPort initialPort) async {
  final port = ReceivePort();
  // Tell the host where to send jobs.
  initialPort.send(port.sendPort);

  await for (final message in port) {
    final job = Map<String, dynamic>.from(message as Map);
    final replyPort = job['replyPort'] as SendPort?;
    if (replyPort == null) continue;
    try {
      final path = await _doExport(job);
      replyPort.send(<String, dynamic>{'ok': true, 'path': path});
    } catch (e) {
      replyPort.send(<String, dynamic>{'ok': false, 'error': e.toString()});
    }
  }
}

Future<String> _doExport(_ExportJob job) async {
  final type = job['type'] as String;
  final slides = (job['slides'] as List).cast<Map<String, dynamic>>();
  final outputPath = job['outputPath'] as String;
  final widescreen = job['widescreen'] as bool? ?? true;
  final aspectRatioName = job['aspectRatio'] as String?;
  final aspectRatio = aspectRatioName == null
      ? null
      : ExportAspectRatio.values.byName(aspectRatioName);
  final includeNotes = job['includeNotes'] as bool? ?? false;
  final includeBackgrounds = job['includeBackgrounds'] as bool? ?? true;
  final imageMaxWidth = job['imageMaxWidth'] as int?;
  final effect = SlideEffect.values.byName(job['effect'] as String? ?? 'none');
  final autoAdvanceMs = job['autoAdvanceMs'] as int? ?? 0;

  switch (type) {
    case 'ppt':
      final file = await PPTGenerator.generatePPT(
        slides,
        outputPath,
        effect: effect,
        widescreen: widescreen,
        aspectRatio: aspectRatio,
        includeNotes: includeNotes,
        includeBackgrounds: includeBackgrounds,
        imageMaxWidth: imageMaxWidth,
        autoAdvance:
            autoAdvanceMs > 0 ? Duration(milliseconds: autoAdvanceMs) : null,
      );
      return file.path;
    case 'pdf':
      final svc = PdfExportService();
      return await svc.exportToPdf(
        slides,
        outputPath,
        widescreen: widescreen,
        aspectRatio: aspectRatio,
        includeNotes: includeNotes,
        includeBackgrounds: includeBackgrounds,
        imageMaxWidth: imageMaxWidth,
      );
    case 'html':
      final svc = HtmlExportService();
      return await svc.exportToHtmlPath(
        slides,
        outputPath,
        aspectRatio: aspectRatio ?? ExportAspectRatio.widescreen16x9,
        includeNotes: includeNotes,
        includeBackgrounds: includeBackgrounds,
        imageMaxWidth: imageMaxWidth,
      );
    default:
      throw Exception('Unknown export type: $type');
  }
}
