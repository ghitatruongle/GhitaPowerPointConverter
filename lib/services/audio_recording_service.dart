import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

/// Audio Recording Service — v1.2.0
/// Records per-slide narration, stores as WAV files, provides playback sync.
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentPath;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentPath => _currentPath;
  int get elapsedSeconds => _elapsedSeconds;

  StreamController<int>? _durationStreamController;
  Stream<int>? get durationStream => _durationStreamController?.stream;

  /// Start recording audio for a specific slide.
  Future<bool> startRecording({int slideIndex = 0}) async {
    if (_isRecording) return false; // v1.2.0: guard against re-entrant
    try {
      // Clean up any leftover stream/timer from previous session
      _durationTimer?.cancel();
      _durationTimer = null;
      await _durationStreamController?.close();

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return false;
      }

      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(dir.path, 'GhitaPPT', 'audio'));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      _currentPath = p.join(audioDir.path, 'slide_${slideIndex}_${DateTime.now().millisecondsSinceEpoch}.wav');
      _elapsedSeconds = 0;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentPath!,
      );

      _isRecording = true;

      // Duration timer
      _durationStreamController = StreamController<int>.broadcast();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        _durationStreamController?.add(_elapsedSeconds);
      });

      debugPrint('AudioRecordingService: Started recording to $_currentPath');
      return true;
    } catch (e) {
      debugPrint('AudioRecordingService Error starting: $e');
      return false;
    }
  }

  /// Stop recording and return the file path.
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _isPaused = false;
      _durationTimer?.cancel();
      _durationTimer = null;
      // v1.2.0: close stream controller to prevent leak
      await _durationStreamController?.close();
      _durationStreamController = null;

      debugPrint('AudioRecordingService: Stopped recording at $path');
      // v1.2.0: verify file exists before returning path
      if (path != null) {
        final file = File(path);
        if (await file.exists()) return path;
      }
      return _currentPath; // fallback
    } catch (e) {
      debugPrint('AudioRecordingService Error stopping: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Pause recording.
  Future<void> pauseRecording() async {
    try {
      if (_isRecording && !_isPaused) {
        await _recorder.pause();
        _isPaused = true;
        _durationTimer?.cancel();
      }
    } catch (e) {
      debugPrint('AudioRecordingService Error pausing: $e');
    }
  }

  /// Resume recording.
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return; // v1.2.0: guard state
    try {
      await _recorder.resume();
      _isPaused = false;
      // Only create timer if controller is still open
      if (_durationStreamController != null && !_durationStreamController!.isClosed) {
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _elapsedSeconds++;
          _durationStreamController?.add(_elapsedSeconds);
        });
      }
    } catch (e) {
      debugPrint('AudioRecordingService Error resuming: $e');
    }
  }

  /// Get all audio files for the presentation.
  Future<List<AudioFileInfo>> listAudioFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(dir.path, 'GhitaPPT', 'audio'));
      if (!await audioDir.exists()) return [];

      final files = await audioDir.list().where((f) => f is File && f.path.endsWith('.wav')).toList();
      return files.map((f) {
        final stat = File(f.path).statSync();
        return AudioFileInfo(
          path: f.path,
          fileName: p.basename(f.path),
          sizeBytes: stat.size,
          modified: stat.modified,
        );
      }).toList();
    } catch (e) {
      debugPrint('AudioRecordingService Error listing: $e');
      return [];
    }
  }

  /// Delete an audio file.
  Future<bool> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('AudioRecordingService Error deleting: $e');
    }
    return false;
  }

  /// Clean up resources.
  void dispose() {
    _durationTimer?.cancel();
    _durationStreamController?.close();
    _recorder.dispose();
  }

  /// Format seconds to mm:ss string.
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class AudioFileInfo {
  final String path;
  final String fileName;
  final int sizeBytes;
  final DateTime modified;

  const AudioFileInfo({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.modified,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
