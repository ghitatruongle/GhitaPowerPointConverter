import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/export_options.dart';
import '../models/slide.dart';
import '../services/html_export_service.dart';
import '../services/export_isolate.dart';
import '../services/smart_draft_manager.dart';
import '../services/time_machine_history_service.dart';
import '../services/project_bundle_service.dart';
import 'config_service.dart';

// SlideEffect moved to models/slide.dart in 0.3.0; re-export so existing
// imports of presentation_state.dart keep working.
export '../models/slide.dart' show Slide, SlideEffect;

class PresentationState with ChangeNotifier {
  List<Slide> _slides = [];
  SlideEffect _slideEffect = SlideEffect.none;
  String _aspectRatio = '16:9';
  String _presentationTitle = 'Dự Án Thuyết Trình';
  String? exportStatus;
  String? lastExportedPath;

  // Current slide in the editor (session-only, used by "Present From Current").
  int _currentSlideIndex = 0;
  // Automatic slide advance ("Timing") — persisted across sessions.
  bool _autoAdvance = false;
  int _autoAdvanceSeconds = 5;

  final ConfigService _configService = ConfigService();
  final SmartDraftManager _smartDraftManager = SmartDraftManager();
  final TimeMachineHistoryService _historyService = TimeMachineHistoryService();
  final ProjectBundleService _bundleService = ProjectBundleService();
  Timer? _saveDebounce;
  Timer? _exportStatusTimer;
  // Reuse the HTML export service to avoid rebuilding presentation logic and
  // to benefit from its image downscaling / in-memory optimizations.
  final HtmlExportService _htmlExportService = HtmlExportService();

  List<Slide> get slides => _slides;
  SlideEffect get slideEffect => _slideEffect;
  String get aspectRatio => _aspectRatio;
  String get presentationTitle => _presentationTitle;
  bool get canUndo => _historyService.canUndo;
  bool get canRedo => _historyService.canRedo;
  int get currentSlideIndex => _currentSlideIndex;
  bool get autoAdvance => _autoAdvance;
  int get autoAdvanceSeconds => _autoAdvanceSeconds;

  /// Backward-compatible alias: returns effect name as string.
  String get currentTheme => _slideEffect.name;

  PresentationState() {
    loadPresentation();
    _loadAutoAdvance();
  }

  // ---- Auto advance ("Timing") ----

  Future<void> _loadAutoAdvance() async {
    final data = await _configService.loadAutoAdvance();
    _autoAdvance = data.enabled;
    _autoAdvanceSeconds = data.seconds;
    notifyListeners();
  }

  void _persistAutoAdvance() {
    unawaited(
        _configService.saveAutoAdvance(_autoAdvance, _autoAdvanceSeconds));
  }

  /// Track the slide currently selected in the editor (used by the ribbon's
  /// "From Current" presenter). Not persisted.
  void setCurrentSlide(int index) {
    if (index < 0 || index >= _slides.length) return;
    _currentSlideIndex = index;
  }

  /// Keep [currentSlideIndex] valid when the slide list shrinks (undo/redo,
  /// delete, load). A stale index would crash "Present From Current" /
  /// Presenter View flows.
  void _keepCurrentSlideInRange() {
    if (_slides.isEmpty) {
      _currentSlideIndex = 0;
    } else if (_currentSlideIndex >= _slides.length) {
      _currentSlideIndex = _slides.length - 1;
    }
  }

  void setAutoAdvance(bool enabled) {
    _autoAdvance = enabled;
    notifyListeners();
    _persistAutoAdvance();
  }

  /// Set the per-slide auto-advance duration. Setting a duration implies the
  /// author wants automatic pacing, so it also enables auto-advance.
  void setAutoAdvanceSeconds(int seconds) {
    _autoAdvanceSeconds = seconds.clamp(1, 60);
    _autoAdvance = true;
    notifyListeners();
    _persistAutoAdvance();
  }

  // ---- History Undo/Redo ----

  void undo() {
    final previous = _historyService.undo();
    if (previous != null) {
      _slides = previous.map((s) => s.copyWith()).toList();
      _keepCurrentSlideInRange();
      notifyListeners();
      savePresentation('Undo');
    }
  }

  void redo() {
    final next = _historyService.redo();
    if (next != null) {
      _slides = next.map((s) => s.copyWith()).toList();
      _keepCurrentSlideInRange();
      notifyListeners();
      savePresentation('Redo');
    }
  }

  void _recordHistory(String action) {
    _historyService.recordSnapshot(action, _slides);
  }

  /// Debounced save to avoid excessive disk I/O during rapid edits (drag-reorder, typing).
  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveDebounce = null;
      savePresentation();
    });
  }

  /// Auto-reset exportStatus after 5 seconds so UI doesn't show stale state.
  void _resetExportStatus() {
    _exportStatusTimer?.cancel();
    _exportStatusTimer = Timer(const Duration(seconds: 5), () {
      if (exportStatus != null && exportStatus != 'exporting') {
        exportStatus = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    final pending = _saveDebounce;
    _saveDebounce?.cancel();
    _saveDebounce = null;
    // Flush any pending debounced save so the last edits aren't lost on close.
    if (pending != null && pending.isActive) {
      unawaited(savePresentation());
    }
    _exportStatusTimer?.cancel();
    super.dispose();
  }

  // ---- Project Bundle (.ghita) ----

  Future<bool> saveProjectToFile(String targetPath) async {
    final success = await _bundleService.saveProjectBundle(
      targetPath: targetPath,
      slides: _slides,
      title: _presentationTitle,
      aspectRatio: _aspectRatio,
    );
    if (success) {
      // PURGE temporary draft from sandbox after official save
      await _smartDraftManager.purgeDraft();
    }
    return success;
  }

  Future<bool> loadProjectFromFile(String sourcePath) async {
    final data = await _bundleService.loadProjectBundle(sourcePath);
    if (data != null) {
      final rawSlides = data['slides'] as List<dynamic>?;
      if (rawSlides == null) return false;
      _slides = rawSlides.map((e) => e as Slide).toList();
      _keepCurrentSlideInRange();
      final manifest = data['manifest'] as Map<String, dynamic>?;
      if (manifest != null) {
        _presentationTitle =
            (manifest['title'] ?? 'Dự Án Thuyết Trình').toString();
        _aspectRatio = (manifest['aspectRatio'] ?? '16:9').toString();
      }
      _historyService.clear();
      _recordHistory('Loaded Project');
      notifyListeners();
      await savePresentation();
      return true;
    }
    return false;
  }

  // ---- Slide CRUD ----

  void addSlide(Slide slide) {
    _slides.add(slide);
    _recordHistory('Thêm Slide mới');
    notifyListeners();
    _debouncedSave();
  }

  void removeSlide(int index) {
    if (index >= 0 && index < _slides.length) {
      _slides.removeAt(index);
      _keepCurrentSlideInRange();
      // Record AFTER the mutation so the snapshot is the post-state
      // (matches addSlide semantics — keeps redo correct too).
      _recordHistory('Xóa Slide');
      notifyListeners();
      _debouncedSave();
    }
  }

  /// Insert a slide at an explicit [index] (used by delete-undo to restore the
  /// original position rather than appending at the end).
  void insertSlide(int index, Slide slide) {
    final clamped = index.clamp(0, _slides.length);
    _slides.insert(clamped, slide);
    _recordHistory('Chèn Slide');
    notifyListeners();
    _debouncedSave();
  }

  /// Update a slide at the given index with new data.
  void updateSlide(int index, Slide updatedSlide) {
    if (index >= 0 && index < _slides.length) {
      _slides[index] = updatedSlide;
      notifyListeners();
      _debouncedSave();
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
      _debouncedSave();
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
    _debouncedSave();
  }

  void clearSlides() {
    if (_slides.isEmpty) return;
    _slides.clear();
    _keepCurrentSlideInRange();
    // Record AFTER the mutation (post-state snapshot) so undo restores the
    // cleared slides and redo re-clears them.
    _recordHistory('Xóa tất cả Slide');
    notifyListeners();
    _debouncedSave();
  }

  /// Replaces the document with an authenticated collaboration snapshot.
  /// The operation is recorded as one history step and persisted locally so a
  /// received update behaves exactly like a normal editor change.
  void replaceSlidesFromCollaboration(List<Slide> slides) {
    _recordHistory('Before Collaboration Sync');
    _slides = slides.map((slide) => slide.copyWith()).toList(growable: true);
    _keepCurrentSlideInRange();
    _recordHistory('Collaboration Sync');
    notifyListeners();
    _debouncedSave();
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

  /// Execute the complete Advanced Export request. Every visible dialog option
  /// is carried to the selected exporter rather than being reduced to a
  /// format-only export.
  Future<String> exportWithOptions(
    String fileName,
    ExportOptions options,
  ) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final selectedSlides = options.selectSlides(_slideMaps());
      final targetDir = await getApplicationDocumentsDirectory();
      final safeName =
          fileName.replaceAll(RegExp(r'[^\w\.-]'), '_').replaceFirst(
                RegExp('\\.${RegExp.escape(options.format.extension)}' r'$'),
                '',
              );
      final outputPath =
          '${targetDir.path}/$safeName.${options.format.extension}';

      final String path;
      switch (options.format) {
        case PresentationExportFormat.pptx:
          path = await runPptExportInIsolate(
            selectedSlides,
            outputPath,
            effect: _slideEffect,
            aspectRatio: options.aspectRatio,
            includeNotes: options.includeNotes,
            includeBackgrounds: options.includeBackgrounds,
            imageMaxWidth: options.quality.imageMaxWidth,
            autoAdvance:
                _autoAdvance ? Duration(seconds: _autoAdvanceSeconds) : null,
          );
          break;
        case PresentationExportFormat.html:
          path = await runHtmlExportInIsolate(
            selectedSlides,
            outputPath,
            aspectRatio: options.aspectRatio,
            includeNotes: options.includeNotes,
            includeBackgrounds: options.includeBackgrounds,
            imageMaxWidth: options.quality.imageMaxWidth,
          );
          break;
        case PresentationExportFormat.pdf:
          path = await runPdfExportInIsolate(
            selectedSlides,
            outputPath,
            aspectRatio: options.aspectRatio,
            includeNotes: options.includeNotes,
            includeBackgrounds: options.includeBackgrounds,
            imageMaxWidth: options.quality.imageMaxWidth,
          );
          break;
      }
      lastExportedPath = path;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return path;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  // ---- Persistence ----

  Future<void> savePresentation([String? title]) async {
    await _configService.saveSlides(_slideMaps(), _slideEffect.name);
  }

  Future<void> loadPresentation([String? title]) async {
    final data = await _configService.loadSlides();
    _slides = (data['slides'] as List)
        .map((e) => Slide.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    _keepCurrentSlideInRange();
    try {
      _slideEffect = SlideEffect.values.byName(data['slide_effect'] ?? 'none');
    } catch (_) {
      _slideEffect = SlideEffect.none;
    }
    notifyListeners();
  }

  Future<String> exportToPPT(String fileName, {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String sanitizeName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$sanitizeName.pptx';

      final String path = await runPptExportInIsolate(
        _slideMaps(),
        fullPath,
        effect: _slideEffect,
        widescreen: widescreen,
        autoAdvance:
            _autoAdvance ? Duration(seconds: _autoAdvanceSeconds) : null,
      );
      lastExportedPath = path;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return path;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Export to a specific file path (used with file picker save dialog).
  Future<String> exportToPPTPath(String filePath,
      {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final String path = await runPptExportInIsolate(
        _slideMaps(),
        filePath,
        effect: _slideEffect,
        widescreen: widescreen,
        autoAdvance:
            _autoAdvance ? Duration(seconds: _autoAdvanceSeconds) : null,
      );
      lastExportedPath = path;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return path;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Export to a self-contained HTML file for browser-based presentation.
  Future<String> exportToHtml(String fileName) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String safeName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$safeName.html';
      final String exportedPath =
          await runHtmlExportInIsolate(_slideMaps(), fullPath);
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Export the HTML deck to an explicit path (save-as dialog).
  Future<String> exportToHtmlPath(String filePath) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final String exportedPath =
          await runHtmlExportInIsolate(_slideMaps(), filePath);
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Export slides as a landscape PDF document (one page per slide).
  Future<String> exportToPdf(String fileName, {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String sanitizeName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$sanitizeName.pdf';
      final String exportedPath = await runPdfExportInIsolate(
        _slideMaps(),
        fullPath,
        widescreen: widescreen,
      );
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Export PDF to an explicit path (save-as dialog).
  Future<String> exportToPdfPath(String filePath,
      {bool widescreen = true}) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final String exportedPath = await runPdfExportInIsolate(
        _slideMaps(),
        filePath,
        widescreen: widescreen,
      );
      lastExportedPath = exportedPath;
      exportStatus = 'success';
      notifyListeners();
      _resetExportStatus();
      return exportedPath;
    } catch (e) {
      exportStatus = 'error';
      notifyListeners();
      _resetExportStatus();
      rethrow;
    }
  }

  /// Build the standalone HTML deck string (used by in-app present mode).
  ///
  /// Reuses a single [HtmlExportService] instance and limits embedded images
  /// to [imageMaxWidth] to reduce memory pressure during presentation.
  String buildHtmlDeck({int startIndex = 0}) {
    final autoAdvance =
        _autoAdvance ? Duration(seconds: _autoAdvanceSeconds) : null;
    return _htmlExportService.buildPresentationHtml(
      _slideMaps(),
      startIndex: startIndex,
      autoAdvance: autoAdvance,
      imageMaxWidth: 1200,
    );
  }
}
