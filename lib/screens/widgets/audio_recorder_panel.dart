import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/audio_recording_service.dart';

/// Audio Recorder Panel — v1.2.0
/// Floating panel for recording per-slide narration.
class AudioRecorderPanel extends StatefulWidget {
  final int currentSlideIndex;
  final void Function(String audioPath)? onRecordingComplete;

  const AudioRecorderPanel({
    super.key,
    required this.currentSlideIndex,
    this.onRecordingComplete,
  });

  @override
  State<AudioRecorderPanel> createState() => _AudioRecorderPanelState();
}

class _AudioRecorderPanelState extends State<AudioRecorderPanel> {
  final AudioRecordingService _recorder = AudioRecordingService();
  StreamSubscription<int>? _durationSub;
  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _durationSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _recorder.startRecording(slideIndex: widget.currentSlideIndex);
    if (success && mounted) {
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _elapsedSeconds = 0;
      });
      // Cancel any previous subscription before assigning a new one, so a
      // re-entry cannot leak the old stream listener.
      _durationSub?.cancel();
      _durationSub = _recorder.durationStream?.listen((seconds) {
        if (mounted) setState(() => _elapsedSeconds = seconds);
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecording();
    _durationSub?.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      if (path != null) {
        widget.onRecordingComplete?.call(path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã ghi âm: ${AudioRecordingService.formatDuration(_elapsedSeconds)}')),
        );
      }
    }
  }

  void _pauseRecording() async {
    await _recorder.pauseRecording();
    if (mounted) setState(() => _isPaused = true);
  }

  void _resumeRecording() async {
    await _recorder.resumeRecording();
    if (mounted) setState(() => _isPaused = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isRecording
            ? Colors.red.shade50
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isRecording ? Colors.red : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (_isRecording) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPaused ? Colors.grey : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Timer
          Text(
            AudioRecordingService.formatDuration(_elapsedSeconds),
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),

          // Controls
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.mic, size: 18),
              tooltip: 'Bắt đầu ghi âm',
              onPressed: _startRecording,
              visualDensity: VisualDensity.compact,
            )
          else ...[
            if (_isPaused)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 18),
                tooltip: 'Tiếp tục',
                onPressed: _resumeRecording,
                visualDensity: VisualDensity.compact,
              )
            else
              IconButton(
                icon: const Icon(Icons.pause, size: 18),
                tooltip: 'Tạm dừng',
                onPressed: _pauseRecording,
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.stop, size: 18, color: Colors.red),
              tooltip: 'Dừng ghi âm',
              onPressed: _stopRecording,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
