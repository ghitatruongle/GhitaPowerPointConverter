import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/slide.dart';

/// Service for packing and unpacking `.ghita` project bundle files.
/// A `.ghita` file is an encoded ZIP archive containing:
/// - `manifest.json` (metadata, title, author, version, ratio)
/// - `slides.json` (slides content, notes, effects, tags)
/// - `history.json` (version snapshot history)
/// - `media/` (embedded offline assets)
class ProjectBundleService {
  /// Packs a presentation into a `.ghita` bundle file at [targetPath].
  Future<bool> saveProjectBundle({
    required String targetPath,
    required List<Slide> slides,
    String title = 'Untitled Presentation',
    String author = 'Ghita User',
    String aspectRatio = '16:9',
    Map<String, dynamic>? extraManifest,
    List<Map<String, dynamic>>? historySnapshots,
  }) async {
    try {
      final archive = Archive();

      // 1. Manifest
      final manifestMap = {
        'appName': 'Ghita PowerPoint Converter',
        'version': '1.6.0+1',
        'title': title,
        'author': author,
        'aspectRatio': aspectRatio,
        'createdAt': DateTime.now().toIso8601String(),
        'slideCount': slides.length,
        if (extraManifest != null) ...extraManifest,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifestMap));
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // 2. Slides
      final slidesList = slides.map((s) => s.toMap()).toList();
      final slidesBytes = utf8.encode(jsonEncode(slidesList));
      archive.addFile(ArchiveFile('slides.json', slidesBytes.length, slidesBytes));

      // 3. History
      final historyList = historySnapshots ?? [];
      final historyBytes = utf8.encode(jsonEncode(historyList));
      archive.addFile(ArchiveFile('history.json', historyBytes.length, historyBytes));

      // 4. Encode ZIP & Write File
      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);
      if (zipBytes != null) {
        final outputFile = File(targetPath);
        // Ensure the target directory exists — writeAsBytes otherwise throws
        // when saving into a folder that doesn't exist yet, and the caller
        // only learns about it via the generic "false" return.
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(zipBytes, flush: true);
        debugPrint('ProjectBundleService: Saved .ghita bundle to $targetPath');
        return true;
      }
    } catch (e) {
      debugPrint('ProjectBundleService Error saving bundle: $e');
    }
    return false;
  }

  /// Unpacks and loads a `.ghita` bundle file from [sourcePath].
  Future<Map<String, dynamic>?> loadProjectBundle(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      Map<String, dynamic>? manifest;
      List<Slide> slides = [];
      List<Map<String, dynamic>> history = [];

      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          if (archiveFile.name == 'manifest.json') {
            final content = utf8.decode(archiveFile.content as List<int>);
            manifest = jsonDecode(content) as Map<String, dynamic>;
          } else if (archiveFile.name == 'slides.json') {
            final content = utf8.decode(archiveFile.content as List<int>);
            final rawList = jsonDecode(content) as List;
            slides = rawList
                .map((e) => Slide.fromMap(e as Map<String, dynamic>))
                .toList();
          } else if (archiveFile.name == 'history.json') {
            final content = utf8.decode(archiveFile.content as List<int>);
            final rawList = jsonDecode(content) as List;
            history = rawList
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }
      }

      return {
        'manifest': manifest ?? {},
        'slides': slides,
        'history': history,
        'filePath': sourcePath,
      };
    } catch (e) {
      debugPrint('ProjectBundleService Error loading bundle: $e');
    }
    return null;
  }
}
