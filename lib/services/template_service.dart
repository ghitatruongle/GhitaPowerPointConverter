import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/slide_template.dart';
import '../providers/presentation_state.dart';

class TemplateService {
  static const String _templatesMetaAsset = 'assets/templates/templates.json';
  static const String _templatesDir = 'assets/templates/';

  List<SlideTemplate>? _cachedTemplates;

  /// Load all available templates from assets.
  Future<List<SlideTemplate>> loadTemplates() async {
    if (_cachedTemplates != null) return _cachedTemplates!;

    try {
      final manifestContent = await rootBundle.loadString(_templatesMetaAsset);
      final List<dynamic> metaList = json.decode(manifestContent);
      final templates = <SlideTemplate>[];

      for (final meta in metaList) {
        final htmlFile = meta['htmlFile'] as String;
        try {
          final htmlContent = await rootBundle.loadString('$_templatesDir$htmlFile');
          templates.add(SlideTemplate(
            id: meta['id'] as String,
            name: meta['name'] as String,
            description: meta['description'] as String,
            htmlContent: htmlContent,
            recommendedEffect: SlideEffect.values.firstWhere(
              (e) => e.name == meta['recommendedEffect'],
              orElse: () => SlideEffect.none,
            ),
            icon: SlideTemplate.iconForCodePoint(
                meta['iconCodePoint'] as int?),
            accentColor: Color((meta['accentColor'] as int?) ?? 0xFF2196F3),
            category: (meta['category'] as String?) ?? 'General',
          ));
        } catch (e) {
          debugPrint('Failed to load template HTML: $htmlFile — $e');
        }
      }

      _cachedTemplates = templates;
      return templates;
    } catch (e) {
      debugPrint('Failed to load templates metadata: $e');
      return [];
    }
  }

  Future<SlideTemplate?> getTemplateById(String id) async {
    final templates = await loadTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } on StateError {
      return null;
    }
  }

  /// Get templates filtered by category.
  Future<List<SlideTemplate>> getTemplatesByCategory(String category) async {
    final templates = await loadTemplates();
    if (category == 'All') return templates;
    return templates.where((t) => t.category == category).toList();
  }

  /// Get all unique categories.
  Future<List<String>> getCategories() async {
    final templates = await loadTemplates();
    final categories = templates.map((t) => t.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  void invalidateCache() {
    _cachedTemplates = null;
  }
}
