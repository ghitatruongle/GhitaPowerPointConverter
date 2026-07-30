import 'package:flutter/material.dart';
import 'package:ghita_ppt_converter/providers/presentation_state.dart';

/// A pre-made HTML template for presentation slides.
class SlideTemplate {
  final String id;
  final String name;
  final String description;
  final String htmlContent;
  final SlideEffect recommendedEffect;
  final IconData icon;
  final Color accentColor;

  /// Known template icons keyed by code point (tree-shake friendly:
  /// dynamic IconData construction breaks icon font tree shaking).
  static const Map<int, IconData> knownIcons = {
    983162: Icons.business_center,
    983166: Icons.palette,
    983195: Icons.school,
    983187: Icons.campaign,
    983173: Icons.crop_square,
  };

  static IconData iconForCodePoint(int? codePoint) =>
      knownIcons[codePoint] ?? Icons.description;

  SlideTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.htmlContent,
    required this.recommendedEffect,
    required this.icon,
    required this.accentColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'htmlContent': htmlContent,
      'recommendedEffect': recommendedEffect.name,
      'icon': icon.codePoint,
      'accentColor': accentColor.toARGB32(),
    };
  }

  factory SlideTemplate.fromMap(Map<String, dynamic> map) {
    return SlideTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      htmlContent: map['htmlContent'] as String,
      recommendedEffect: SlideEffect.values.firstWhere(
        (e) => e.name == map['recommendedEffect'],
        orElse: () => SlideEffect.none,
      ),
      icon: iconForCodePoint(map['icon'] as int?),
      accentColor: Color(map['accentColor'] as int),
    );
  }
}
