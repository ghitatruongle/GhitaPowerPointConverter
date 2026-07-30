import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

/// Renders a single slide's HTML inside a WebView2 (Windows) view.
///
/// Falls back to a plain message when the WebView2 runtime is unavailable
/// so the app keeps working on machines without the Evergreen runtime.
class SlidePreview extends StatefulWidget {
  final String title;
  final String html;

  const SlidePreview({super.key, required this.title, required this.html});

  /// Wrap a slide fragment in a dark 16:9-style page matching the HTML export.
  static String wrapSlideHtml(String title, String html) {
    final cleaned = html
        .replaceAll(RegExp(r'data-bg-color="[^"]*"', caseSensitive: false), '')
        .replaceAll(RegExp(r"data-bg-color='[^']*'", caseSensitive: false), '');
    final bgMatch = RegExp(r"""data-bg-color=["']([^"']+)["']""",
            caseSensitive: false)
        .firstMatch(html);
    final bg = bgMatch?.group(1) ?? '#1a1a2e';
    return '''
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', system-ui, sans-serif;
    background: $bg;
    color: #e0e0e0;
    padding: 5vh 6vw;
    min-height: 100vh;
  }
  h1 { font-size: clamp(1.6rem, 4vw, 3rem); color: #fff; margin-bottom: 0.3em; }
  h2 { font-size: clamp(1.1rem, 2.5vw, 1.8rem); color: #ccc; font-style: italic; margin-bottom: 0.8em; }
  p { font-size: clamp(0.9rem, 1.8vw, 1.3rem); line-height: 1.7; margin-bottom: 0.7em; }
  ul, ol { margin: 0.5em 0 0.5em 1.5em; line-height: 1.8; }
  table { border-collapse: collapse; margin: 1em 0; }
  th, td { padding: 8px 12px; border: 1px solid rgba(255,255,255,0.25); }
  th { background: rgba(255,255,255,0.1); }
  img { max-width: 100%; max-height: 60vh; }
  b, strong { color: #fff; }
  aside.notes { display: none; }
</style></head>
<body>$cleaned</body></html>''';
  }

  @override
  State<SlidePreview> createState() => _SlidePreviewState();
}

class _SlidePreviewState extends State<SlidePreview> {
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
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller
          .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadStringContent(
          SlidePreview.wrapSlideHtml(widget.title, widget.html));
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant SlidePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        (oldWidget.html != widget.html || oldWidget.title != widget.title)) {
      _controller.loadStringContent(
          SlidePreview.wrapSlideHtml(widget.title, widget.html));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_asset_off,
                size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'Preview unavailable\n(WebView2 runtime not found)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Webview(_controller),
    );
  }
}
