import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/slide.dart';
import '../services/ppt_generator.dart';
import '../services/html_export_service.dart';
import '../services/pdf_export_service.dart';
import 'config_service.dart';

// SlideEffect moved to models/slide.dart in 0.3.0; re-export so existing
// imports of presentation_state.dart keep working.
export '../models/slide.dart' show Slide, SlideEffect;

class PresentationState with ChangeNotifier {
  List<Slide> _slides = [];
  SlideEffect _slideEffect = SlideEffect.none;
  String? exportStatus;
  String? lastExportedPath;
  final ConfigService _configService = ConfigService();

  List<Slide> get slides => _slides;
  SlideEffect get slideEffect => _slideEffect;

  /// Backward-compatible alias: returns effect name as string.
  String get currentTheme => _slideEffect.name;

  PresentationState() {
    loadPresentation();
  }

  // ---- Slide CRUD ----

  void addSlide(Slide slide) {
    _slides.add(slide);
    notifyListeners();
    savePresentation();
  }

  void removeSlide(int index) {
    if (index >= 0 && index < _slides.length) {
      _slides.removeAt(index);
      notifyListeners();
      savePresentation();
    }
  }

  /// Update a slide at the given index with new data.
  void updateSlide(int index, Slide updatedSlide) {
    if (index >= 0 && index < _slides.length) {
      _slides[index] = updatedSlide;
      notifyListeners();
      savePresentation();
    }
  }

  /// Duplicate a slide at the given index.
  void duplicateSlide(int index) {
    if (index >= 0 && index < _slides.length) {
      final original = _slides[index];
      final duplicate = original.copyWith(
        title: '${original.title} (Copy)',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _slides.insert(index + 1, duplicate);
      notifyListeners();
      savePresentation();
    }
  }

  /// Move a slide from [oldIndex] to [newIndex].
  void moveSlide(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _slides.length) return;
    if (newIndex < 0 || newIndex >= _slides.length) return;
    if (oldIndex == newIndex) return;

    final slide = _slides.removeAt(oldIndex);
    _slides.insert(newIndex, slide);
    notifyListeners();
    savePresentation();
  }

  void clearSlides() {
    _slides.clear();
    notifyListeners();
    savePresentation();
  }

  void setEffect(SlideEffect effect) {
    _slideEffect = effect;
    notifyListeners();
    savePresentation();
  }

  /// Set (or clear with null) the per-slide transition override.
  void setSlideEffectOverride(int index, SlideEffect? effect) {
    if (index >= 0 && index < _slides.length) {
      _slides[index] =
          _slides[index].copyWith(effect: effect, clearEffect: effect == null);
      notifyListeners();
      savePresentation();
    }
  }

  List<Map<String, dynamic>> _slideMaps() =>
      _slides.map((s) => s.toMap()).toList();

  // ---- Persistence ----

  Future<void> savePresentation([String? title]) async {
    await _configService.saveSlides(_slideMaps(), _slideEffect.name);
  }

  Future<void> loadPresentation([String? title]) async {
    final data = await _configService.loadSlides();
    _slides = (data['slides'] as List)
        .map((e) => Slide.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    try {
      _slideEffect =
          SlideEffect.values.byName(data['slide_effect'] ?? 'none');
    } catch (_) {
      _slideEffect = SlideEffect.none;
    }
    notifyListeners();
  }

  Future<String> exportToPPT(String fileName,
      {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String sanitizeName =
          fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$sanitizeName.pptx';

      final File pptFile = await PPTGenerator.generatePPT(
        _slideMaps(),
        fullPath,
        effect: _slideEffect,
        widescreen: widescreen,
      );
      lastExportedPath = pptFile.path;
      exportStatus = 'success';
      notifyListeners();
      return pptFile.path;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Export to a specific file path (used with file picker save dialog).
  Future<String> exportToPPTPath(String filePath,
      {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final File pptFile = await PPTGenerator.generatePPT(
        _slideMaps(),
        filePath,
        effect: _slideEffect,
        widescreen: widescreen,
      );
      lastExportedPath = pptFile.path;
      exportStatus = 'success';
      notifyListeners();
      return pptFile.path;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Export to a self-contained HTML file for browser-based presentation.
  Future<String> exportToHtml(String fileName) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final htmlService = HtmlExportService();
      final exportedPath = await htmlService.exportToHtml(
        _slideMaps(),
        fileName: fileName,
      );
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Export the HTML deck to an explicit path (save-as dialog).
  Future<String> exportToHtmlPath(String filePath) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final htmlService = HtmlExportService();
      final exportedPath =
          await htmlService.exportToHtmlPath(_slideMaps(), filePath);
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Export slides as a landscape PDF document (one page per slide).
  Future<String> exportToPdf(String fileName, {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String sanitizeName =
          fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$sanitizeName.pdf';
      final pdfService = PdfExportService();
      final exportedPath = await pdfService.exportToPdf(
        _slideMaps(),
        fullPath,
        widescreen: widescreen,
      );
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Export PDF to an explicit path (save-as dialog).
  Future<String> exportToPdfPath(String filePath,
      {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final pdfService = PdfExportService();
      final exportedPath = await pdfService.exportToPdf(
        _slideMaps(),
        filePath,
        widescreen: widescreen,
      );
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      rethrow;
    }
  }

  /// Build the standalone HTML deck string (used by in-app present mode).
  String buildHtmlDeck() {
    return HtmlExportService().buildPresentationHtml(_slideMaps());
  }
}
