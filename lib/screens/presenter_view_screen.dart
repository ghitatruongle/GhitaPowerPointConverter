import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/presentation_state.dart';
import '../screens/widgets/slide_preview.dart';

/// Presenter View — split-screen layout with current slide, next slide preview,
/// speaker notes, timer, and slide navigator. Similar to PowerPoint's Presenter View.
class PresenterViewScreen extends StatefulWidget {
  final PresentationState state;
  final int startSlide;

  const PresenterViewScreen({
    super.key,
    required this.state,
    this.startSlide = 0,
  });

  @override
  State<PresenterViewScreen> createState() => _PresenterViewScreenState();
}

class _PresenterViewScreenState extends State<PresenterViewScreen> {
  late int _currentSlide;
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _showNavigator = false;

  @override
  void initState() {
    super.initState();
    // Defense-in-depth: [startSlide] can arrive stale from the editor's
    // current index after slides were removed — clamp so we never index OOB.
    final count = widget.state.slides.length;
    _currentSlide = count == 0 ? 0 : widget.startSlide.clamp(0, count - 1).toInt();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentSlide < widget.state.slides.length - 1) {
      setState(() => _currentSlide++);
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.state.slides;
    if (slides.isEmpty) {
      // Defensive guard: slides can be cleared while this screen is open.
      // Auto-close instead of throwing RangeError below.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No slides to present.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    // Clamp BEFORE indexing: collaboration sync can shrink the deck while
    // this screen is open, and a stale _currentSlide would throw RangeError
    // (the empty-deck guard alone does not protect against a partial shrink).
    if (_currentSlide >= slides.length) {
      _currentSlide = slides.length - 1;
    }
    final current = slides[_currentSlide];
    final nextSlide = _currentSlide < slides.length - 1 ? slides[_currentSlide + 1] : null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextSlide,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevSlide,
          const SingleActivator(LogicalKeyboardKey.space): _nextSlide,
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Left side: Current slide (70%)
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    // Top bar
                    _buildTopBar(theme, slides.length),

                    // Current slide
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: SlidePreview(
                            title: current.title,
                            html: current.htmlContent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: Next slide + Notes (30%)
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey.shade900,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Next slide preview
                      Text(
                        'Next Slide',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: nextSlide != null
                            ? Card(
                                clipBehavior: Clip.antiAlias,
                                child: SlidePreview(
                                  title: nextSlide.title,
                                  html: nextSlide.htmlContent,
                                ),
                              )
                            : Card(
                                child: Center(
                                  child: Text(
                                    'End of presentation',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),

                      // Speaker notes
                      Text(
                        'Speaker Notes',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: current.notes.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Text(
                                    current.notes,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'No notes for this slide',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Timer + navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, int totalSlides) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Exit button
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 8),

          // Slide counter
          Text(
            'Slide ${_currentSlide + 1} / $totalSlides',
            style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
          ),

          const Spacer(),

          // Previous button
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 20,
              color: _currentSlide > 0 ? Colors.white : Colors.grey.shade700,
            ),
            onPressed: _currentSlide > 0 ? _prevSlide : null,
            visualDensity: VisualDensity.compact,
          ),

          // Next button
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 20,
              color: _currentSlide < totalSlides - 1 ? Colors.white : Colors.grey.shade700,
            ),
            onPressed: _currentSlide < totalSlides - 1 ? _nextSlide : null,
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 8),

          // Slide navigator toggle
          IconButton(
            icon: Icon(
              _showNavigator ? Icons.grid_view : Icons.grid_on,
              size: 18,
              color: Colors.grey.shade400,
            ),
            onPressed: () => setState(() => _showNavigator = !_showNavigator),
            visualDensity: VisualDensity.compact,
          ),

          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatTime(_elapsedSeconds),
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
