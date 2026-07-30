import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';
import '../providers/presentation_state.dart';

/// Fullscreen in-app presentation mode.
///
/// Loads the same standalone HTML deck produced by HtmlExportService into a
/// WebView2, reusing its player (arrow keys, progress bar, touch, fullscreen).
class PresentScreen extends StatefulWidget {
  final PresentationState state;

  const PresentScreen({super.key, required this.state});

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
      await _controller.loadStringContent(widget.state.buildHtmlDeck());
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
              // Exit button overlay (webview swallows keyboard focus).
              Positioned(
                top: 12,
                left: 12,
                child: IconButton.filledTonal(
                  tooltip: 'Exit (Esc)',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
