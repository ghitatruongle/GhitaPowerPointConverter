import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';
import '../providers/presentation_state.dart';

/// Fullscreen in-app presentation mode.
///
/// Loads the same standalone HTML deck produced by HtmlExportService into a
/// WebView2, reusing its player (arrow keys, auto-play, progress bar, touch,
/// fullscreen). A prominent "Thoát" button (or Esc) leaves the presentation.
class PresentScreen extends StatefulWidget {
  final PresentationState state;
  final int startSlide;

  const PresentScreen({super.key, required this.state, this.startSlide = 0});

  @override
  State<PresentScreen> createState() => _PresentScreenState();
}

class _PresentScreenState extends State<PresentScreen> {
  final _controller = WebviewController();
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.black);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadStringContent(
          widget.state.buildHtmlDeck(startIndex: widget.startSlide));
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              if (_failed)
                Center(
                  child: Text(
                    'Present mode unavailable (WebView2 runtime not found).',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              else if (!_ready)
                const Center(
                    child: CircularProgressIndicator(color: Colors.white))
              else
                Positioned.fill(child: Webview(_controller)),
              // Exit button overlay (webview swallows keyboard focus, so a
              // visible in-app button is required — not just Esc).
              Positioned(
                top: 12,
                left: 12,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Thoát'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
