import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/office_colors.dart';

/// Preset theme definitions
enum PresetTheme {
  officeBlue,
  darkProfessional,
  lightMinimal,
  custom,
}

/// ThemeProvider quản lý custom theme settings
class ThemeProvider with ChangeNotifier {
  Color _primaryColor = OfficeColors.officeBlue;
  Color _accentColor = OfficeColors.accentOrange;
  String _fontFamily = 'Segoe UI';
  PresetTheme _presetTheme = PresetTheme.officeBlue;
  bool _isLoaded = false;

  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  String get fontFamily => _fontFamily;
  PresetTheme get presetTheme => _presetTheme;
  bool get isLoaded => _isLoaded;

  ThemeProvider() {
    _loadTheme();
  }

  /// Set primary color
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _presetTheme = PresetTheme.custom;
    notifyListeners();
    _saveTheme();
  }

  /// Set accent color
  void setAccentColor(Color color) {
    _accentColor = color;
    _presetTheme = PresetTheme.custom;
    notifyListeners();
    _saveTheme();
  }

  /// Set font family
  void setFontFamily(String fontFamily) {
    _fontFamily = fontFamily;
    notifyListeners();
    _saveTheme();
  }

  /// Apply preset theme
  void applyPreset(PresetTheme preset) {
    _presetTheme = preset;

    switch (preset) {
      case PresetTheme.officeBlue:
        _primaryColor = OfficeColors.officeBlue;
        _accentColor = OfficeColors.accentOrange;
        _fontFamily = 'Segoe UI';
        break;
      case PresetTheme.darkProfessional:
        _primaryColor = const Color(0xFF1F2937);
        _accentColor = const Color(0xFF10B981);
        _fontFamily = 'Segoe UI';
        break;
      case PresetTheme.lightMinimal:
        _primaryColor = const Color(0xFF6B7280);
        _accentColor = const Color(0xFFF59E0B);
        _fontFamily = 'Segoe UI';
        break;
      case PresetTheme.custom:
        // Keep current colors
        break;
    }

    notifyListeners();
    _saveTheme();
  }

  /// Reset về Office Blue preset
  void resetToDefault() {
    applyPreset(PresetTheme.officeBlue);
  }

  /// Export theme thành JSON string
  String exportToJson() {
    return jsonEncode({
      'primaryColor': _colorToHex(_primaryColor),
      'accentColor': _colorToHex(_accentColor),
      'fontFamily': _fontFamily,
      'presetTheme': _presetTheme.name,
    });
  }

  /// Import theme từ JSON string
  bool importFromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      final primaryHex = map['primaryColor'] as String?;
      final accentHex = map['accentColor'] as String?;
      final fontFamily = map['fontFamily'] as String?;
      final presetName = map['presetTheme'] as String?;

      if (primaryHex != null) {
        _primaryColor = _hexToColor(primaryHex);
      }
      if (accentHex != null) {
        _accentColor = _hexToColor(accentHex);
      }
      if (fontFamily != null) {
        _fontFamily = fontFamily;
      }
      if (presetName != null) {
        _presetTheme = PresetTheme.values.firstWhere(
          (p) => p.name == presetName,
          orElse: () => PresetTheme.custom,
        );
      }

      notifyListeners();
      _saveTheme();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convert Color to hex string (ARGB)
  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Convert hex string to Color
  /// Supports both 8-digit ARGB (#AARRGGBB) and 6-digit RGB (#RRGGBB) formats.
  Color _hexToColor(String hex) {
    try {
      var cleaned = hex.trim().replaceFirst(RegExp(r'^#'), '');
      // Validate strictly: 3/4/5/7-digit hex previously parsed into garbage
      // colors (e.g. 'FFF' became nearly-transparent) or threw. Only accept
      // real 6- or 8-digit values, otherwise fall back to the default.
      if (!RegExp(r'^[0-9A-Fa-f]{6}$|^[0-9A-Fa-f]{8}$').hasMatch(cleaned)) {
        return OfficeColors.officeBlue;
      }
      // If only 6 digits (RGB), treat as fully opaque to avoid transparent color
      if (cleaned.length == 6) {
        cleaned = 'FF$cleaned';
      }
      final value = int.parse(cleaned, radix: 16);
      return Color(value);
    } catch (e) {
      return OfficeColors.officeBlue;
    }
  }

  /// Load theme từ SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final primaryHex = prefs.getString('theme_primary_color');
      if (primaryHex != null) {
        _primaryColor = _hexToColor(primaryHex);
      }

      final accentHex = prefs.getString('theme_accent_color');
      if (accentHex != null) {
        _accentColor = _hexToColor(accentHex);
      }

      final font = prefs.getString('theme_font_family');
      if (font != null) {
        _fontFamily = font;
      }

      final presetName = prefs.getString('theme_preset');
      if (presetName != null) {
        _presetTheme = PresetTheme.values.firstWhere(
          (p) => p.name == presetName,
          orElse: () => PresetTheme.officeBlue,
        );
      }
    } catch (e) {
      // A prefs failure must never crash startup — keep the defaults.
      debugPrint('ThemeProvider: failed to load theme: $e');
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Save theme vào SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_primary_color', _colorToHex(_primaryColor));
      await prefs.setString('theme_accent_color', _colorToHex(_accentColor));
      await prefs.setString('theme_font_family', _fontFamily);
      await prefs.setString('theme_preset', _presetTheme.name);
    } catch (e) {
      debugPrint('ThemeProvider: failed to save theme: $e');
    }
  }
}
