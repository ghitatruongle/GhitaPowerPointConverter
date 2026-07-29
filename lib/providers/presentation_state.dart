import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/ppt_generator.dart';
import 'config_service.dart';

// Slide transition effects that map to PPTX transitions.
enum SlideEffect {
  none,
  fade,
  pushLeft,
  pushRight,
  pushUp,
  pushDown,
  wipe,
  splitIn,
  splitOut,
  randomBar,
  checkerboard,
  blinds,
  clock,
  zoom,
}

class PresentationState with ChangeNotifier {
  List<Map<String, dynamic>> _slides = [];
  SlideEffect _slideEffect = SlideEffect.none;
  String? exportStatus;
  String? lastExportedPath;
  final ConfigService _configService = ConfigService();

  List<Map<String, dynamic>> get slides => _slides;
  SlideEffect get slideEffect => _slideEffect;

  /// Backward-compatible alias: returns effect name as string.
  String get currentTheme => _slideEffect.name;

  PresentationState() {
    loadPresentation();
  }

  void addSlide(Map<String, dynamic> slide) {
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

  Future<void> savePresentation([String? title]) async {
    await _configService.saveSlides(_slides, _slideEffect.name);
  }

  Future<void> loadPresentation([String? title]) async {
    final data = await _configService.loadSlides();
    _slides = (data['slides'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _slideEffect = SlideEffect.values.byName(data['slide_effect'] ?? 'none');
    notifyListeners();
  }
  
  Future<String> exportToPPT(String fileName) async {
    exportStatus = 'exporting';
    notifyListeners();
    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final String sanitizeName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final String fullPath = '${targetDir.path}/$sanitizeName.pptx';
      
      final File pptFile = await PPTGenerator.generatePPT(_slides, fullPath, effect: _slideEffect);
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
}

