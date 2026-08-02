import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/slide.dart';

/// Smart Draft Manager following Microsoft PowerPoint's AutoSave behavior:
/// - Auto-saves unsaved presentation work into a background draft file in the app sandbox.
/// - Instantly PURGES (deletes) the draft file once the user explicitly saves to a `.ghita` file on disk.
class SmartDraftManager {
  static const String _draftFileName = 'ghita_ppt_unsaved_draft.json';

  Future<File> _getDraftFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final draftsDir = Directory(p.join(dir.path, 'GhitaPPT', 'drafts'));
    if (!await draftsDir.exists()) {
      await draftsDir.create(recursive: true);
    }
    return File(p.join(draftsDir.path, _draftFileName));
  }

  /// Saves the current presentation slides & metadata to the temporary draft sandbox.
  Future<void> saveDraft(List<Slide> slides, {Map<String, dynamic>? metadata}) async {
    try {
      final file = await _getDraftFile();
      final draftData = {
        'version': '1.0.2',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'metadata': metadata ?? {},
        'slides': slides.map((s) => s.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(draftData), flush: true);
      debugPrint('SmartDraftManager: Draft auto-saved (${slides.length} slides)');
    } catch (e) {
      debugPrint('SmartDraftManager Error saving draft: $e');
    }
  }

  /// Checks whether an unsaved recoverable draft exists.
  Future<bool> hasRecoverableDraft() async {
    try {
      final file = await _getDraftFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final map = jsonDecode(content) as Map<String, dynamic>;
          final slidesList = map['slides'] as List?;
          return slidesList != null && slidesList.isNotEmpty;
        }
      }
    } catch (e) {
      debugPrint('SmartDraftManager Error checking draft: $e');
    }
    return false;
  }

  /// Loads and returns the recoverable draft dataset, or null if none.
  Future<Map<String, dynamic>?> loadRecoverableDraft() async {
    try {
      final file = await _getDraftFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('SmartDraftManager Error loading draft: $e');
    }
    return null;
  }

  /// Purges (deletes) the draft file from the sandbox after an official save to `.ghita`.
  Future<void> purgeDraft() async {
    try {
      final file = await _getDraftFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint('SmartDraftManager: Unsaved draft purged cleanly from sandbox.');
      }
    } catch (e) {
      debugPrint('SmartDraftManager Error purging draft: $e');
    }
  }
}
