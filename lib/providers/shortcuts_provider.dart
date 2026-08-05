import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/keyboard_shortcuts.dart';

/// Provider quản lý keyboard shortcuts (có thể customize bởi user)
class ShortcutsProvider with ChangeNotifier {
  final Map<ShortcutAction, SingleActivator> _shortcuts = {};
  bool _isLoaded = false;

  ShortcutsProvider() {
    _loadShortcuts();
  }

  /// Get shortcut cho một action
  SingleActivator getShortcut(ShortcutAction action) {
    return _shortcuts[action] ?? AppShortcuts.getDefault(action);
  }

  /// Get tất cả shortcuts hiện tại
  Map<ShortcutAction, SingleActivator> getAllShortcuts() {
    return Map.from(_shortcuts);
  }

  /// Set custom shortcut cho một action
  void setShortcut(ShortcutAction action, SingleActivator shortcut) {
    _shortcuts[action] = shortcut;
    notifyListeners();
    _saveShortcuts();
  }

  /// Reset một action về default shortcut
  void resetToDefault(ShortcutAction action) {
    _shortcuts.remove(action);
    notifyListeners();
    _saveShortcuts();
  }

  /// Reset tất cả về defaults
  void resetAllToDefaults() {
    _shortcuts.clear();
    notifyListeners();
    _saveShortcuts();
  }

  /// Kiểm tra xem một shortcut có conflict với shortcuts khác không
  ShortcutAction? findConflict(ShortcutAction action, SingleActivator shortcut) {
    for (final entry in _shortcuts.entries) {
      if (entry.key != action && _shortcutsEqual(entry.value, shortcut)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Export shortcuts thành JSON string
  String exportToJson() {
    final map = <String, String>{};
    for (final entry in _shortcuts.entries) {
      map[entry.key.name] = AppShortcuts.shortcutToString(entry.value);
    }
    return jsonEncode(map);
  }

  /// Import shortcuts từ JSON string
  bool importFromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      _shortcuts.clear();
      
      for (final entry in map.entries) {
        final actionName = entry.key;
        final shortcutString = entry.value as String;
        
        // Find action by name
        ShortcutAction? action;
        for (final a in ShortcutAction.values) {
          if (a.name == actionName) {
            action = a;
            break;
          }
        }
        
        if (action != null) {
          final shortcut = AppShortcuts.parseShortcut(shortcutString);
          if (shortcut != null) {
            _shortcuts[action] = shortcut;
          }
        }
      }
      
      notifyListeners();
      _saveShortcuts();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load shortcuts từ SharedPreferences
  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('custom_shortcuts');
    
    if (jsonString != null) {
      importFromJson(jsonString);
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  /// Save shortcuts vào SharedPreferences
  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = exportToJson();
    await prefs.setString('custom_shortcuts', jsonString);
  }

  /// Check if shortcuts have been loaded
  bool get isLoaded => _isLoaded;

  /// Helper: so sánh 2 shortcuts có bằng nhau không
  bool _shortcutsEqual(SingleActivator a, SingleActivator b) {
    return a.trigger == b.trigger &&
           a.control == b.control &&
           a.shift == b.shift &&
           a.alt == b.alt;
  }
}
