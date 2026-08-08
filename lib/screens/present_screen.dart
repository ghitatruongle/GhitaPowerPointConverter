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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize().timeout(const Duration(seconds: 30));
      await _controller.setBackgroundColor(Colors.black);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      final html = widget.state.buildHtmlDeck(startIndex: widget.startSlide);
      await _controller.loadStringContent(html).timeout(const Duration(seconds: 30));
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _errorMessage = e.toString();
        });
      }
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể khởi chạy trình chiếu',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Lỗi không xác định',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
