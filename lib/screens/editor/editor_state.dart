import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';
import '../../models/slide_template.dart';
import '../../utils/effect_helpers.dart';
import '../../utils/error_mapper.dart';

/// Centralized editor state for the PowerPoint-style editor.
///
/// Manages HTML editing, slide CRUD, template application, export dialogs,
/// and live preview — extracted from the monolithic HtmlToPPTScreen.
class EditorState with ChangeNotifier {
  // ---- Controllers ----
  final htmlController = TextEditingController();
  final titleController = TextEditingController();
  final notesController = TextEditingController();

  // ---- Editing mode ----
  int? _editingIndex;
  SlideEffect? _slideEffectOverride;
  bool _isLoading = false;

  // ---- Live preview (debounced) ----
  Timer? _previewTimer;
  String _previewHtml = '';
  double _zoomLevel = 1.0;
  bool _showNotes = false;
  bool _showPreview = true;
  int _selectedSlideIndex = -1;

  // ---- Getters ----
  int? get editingIndex => _editingIndex;
  SlideEffect? get slideEffectOverride => _slideEffectOverride;
  bool get isLoading => _isLoading;
  String get previewHtml => _previewHtml;
  double get zoomLevel => _zoomLevel;
  bool get showNotes => _showNotes;
  bool get showPreview => _showPreview;
  int get selectedSlideIndex => _selectedSlideIndex;
  bool get isEditing => _editingIndex != null;

  EditorState() {
    titleController.text = 'New Slide';
    htmlController.addListener(_schedulePreviewUpdate);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    htmlController.dispose();
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ---- Preview debounce ----

  void _schedulePreviewUpdate() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), () {
      _previewHtml = htmlController.text;
      notifyListeners();
    });
  }

  // ---- Zoom ----

  void setZoom(double zoom) {
    _zoomLevel = zoom.clamp(0.5, 2.0);
    notifyListeners();
  }

  void zoomIn() => setZoom(_zoomLevel + 0.1);
  void zoomOut() => setZoom(_zoomLevel - 0.1);

  // ---- UI toggles ----

  void toggleNotes() {
    _showNotes = !_showNotes;
    notifyListeners();
  }

  void togglePreview() {
    _showPreview = !_showPreview;
    notifyListeners();
  }

  // ---- Slide selection ----

  void selectSlide(int index) {
    _selectedSlideIndex = index;
    notifyListeners();
  }

  // ---- Public setters for private fields (accessed from other files) ----

  void setSlideEffectOverride(SlideEffect? effect) {
    _slideEffectOverride = effect;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ---- HTML tag insertion ----

  void insertHtmlTag(String open, String close) {
    final text = htmlController.text;
    final selection = htmlController.selection;
    if (selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length) {
      final selectedText = text.substring(selection.start, selection.end);
      final replacement = '$open$selectedText$close';
      final newText =
          text.replaceRange(selection.start, selection.end, replacement);
      htmlController.text = newText;
      htmlController.selection = TextSelection.collapsed(
        offset: selection.start + open.length + selectedText.length,
      );
    } else {
      htmlController.text = '$text$open$close';
    }
  }

  // ---- Input Validation ----
  // Returns error message string on failure, or null on success (sets _lastSanitizedHtml).

  String? _lastSanitizedHtml;

  /// Validate and sanitize HTML. Returns error message on failure, null on success.
  String? validateAndSanitizeHtml(String rawHtml) {
    if (rawHtml.isEmpty) return 'HTML content cannot be empty.';
    if (rawHtml.length > 100000) return 'HTML content is too long (max 100KB).';

    final sanitizedHtml = rawHtml
        .replaceAll(
            RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<iframe[\s\S]*?<\/iframe>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<object[\s\S]*?<\/object>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<embed[\s\S]*?\/>', caseSensitive: false), '');

    if (sanitizedHtml.trim().isEmpty) {
      return 'HTML contains only blocked elements.';
    }
    _lastSanitizedHtml = sanitizedHtml;
    return null; // null = no error
  }

  /// Get the last sanitized HTML (call after validateAndSanitizeHtml returns null).
  String get lastSanitizedHtml => _lastSanitizedHtml ?? '';

  // ---- Add / Update Slide ----

  Future<void> addOrUpdateSlide(BuildContext context) async {
    final rawHtml = htmlController.text.trim();
    final error = validateAndSanitizeHtml(rawHtml);
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    final sanitizedHtml = lastSanitizedHtml;
    final state = Provider.of<PresentationState>(context, listen: false);

    _isLoading = true;
    notifyListeners();

    try {
      final document = html_parser.parse(sanitizedHtml);
      String title = titleController.text.trim();

      final h1 = document.querySelector('h1');
      if (h1 != null && h1.text.isNotEmpty) {
        title = h1.text;
      } else if (title.isEmpty) {
        title = 'Untitled Slide';
      }

      final slide = Slide(
        title: title,
        htmlContent: sanitizedHtml,
        notes: notesController.text.trim(),
        effect: _slideEffectOverride,
      );

      if (_editingIndex != null) {
        state.updateSlide(_editingIndex!, slide);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slide updated!')),
          );
        }
      } else {
        state.addSlide(slide);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slide added successfully!')),
          );
        }
      }

      clearEditor();
    } catch (e) {
      if (context.mounted) {
        ErrorMapper.showErrorSnackBar(context, e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Edit existing slide ----

  void editSlide(int index, PresentationState state) {
    if (index < 0 || index >= state.slides.length) return;

    final slide = state.slides[index];
    htmlController.text = slide.htmlContent;
    titleController.text = slide.title;
    notesController.text = slide.notes;
    _editingIndex = index;
    _slideEffectOverride = slide.effect;
    _selectedSlideIndex = index;
    // Force preview update immediately (don't wait for debounce)
    _previewHtml = slide.htmlContent;
    notifyListeners();
  }

  // ---- Clear editor ----

  void clearEditor() {
    htmlController.clear();
    titleController.text = 'New Slide';
    notesController.clear();
    _editingIndex = null;
    _slideEffectOverride = null;
    notifyListeners();
  }

  // ---- Apply template ----

  void applyTemplate(SlideTemplate template, BuildContext context) {
    htmlController.text = template.htmlContent;
    titleController.text = _extractTitleFromHtml(template.htmlContent);
    _editingIndex = null;
    // Force preview update immediately
    _previewHtml = template.htmlContent;

    final state = Provider.of<PresentationState>(context, listen: false);
    state.setEffect(template.recommendedEffect);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied "${template.name}" template!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    notifyListeners();
  }

  String _extractTitleFromHtml(String html) {
    try {
      final doc = html_parser.parse(html);
      final h1 = doc.querySelector('h1');
      if (h1 != null && h1.text.trim().isNotEmpty) {
        return h1.text.trim();
      }
    } catch (_) {}
    return 'New Slide';
  }

  // ---- Effect name display ----

  static String effectName(SlideEffect effect) => EffectHelpers.effectName(effect);
}
