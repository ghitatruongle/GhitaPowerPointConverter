import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

/// Renders a single slide's HTML as a Flutter-rendered text preview.
/// Uses WebView2 when available, with automatic fallback to text rendering.
class SlidePreview extends StatefulWidget {
  final String title;
  final String html;

  const SlidePreview({super.key, required this.title, required this.html});

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
  bool _showWebView = false; // Start with text preview, try WebView2 in background
  String? _pendingHtml;

  @override
  void initState() {
    super.initState();
    // Show text preview immediately, then try WebView2 in background
    _tryWebView2();
  }

  Future<void> _tryWebView2() async {
    try {
      await _controller.initialize().timeout(const Duration(seconds: 3));
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      final initialHtml = SlidePreview.wrapSlideHtml(widget.title, widget.html);
      await _controller.loadStringContent(initialHtml).timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _showWebView = true);
      }
      if (_pendingHtml != null) {
        await _controller.loadStringContent(_pendingHtml!);
        _pendingHtml = null;
      }
    } catch (_) {
      // WebView2 not available or slow — use text preview
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant SlidePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html || oldWidget.title != widget.title) {
      final newHtml = SlidePreview.wrapSlideHtml(widget.title, widget.html);
      if (_showWebView) {
        _controller.loadStringContent(newHtml);
      } else {
        _pendingHtml = newHtml;
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
    // Always show text preview; overlay WebView2 on top if available
    final textPreview = _buildTextPreview(context);
    
    if (!_showWebView && !_failed) {
      // Still trying WebView2 — show text preview for now
      return textPreview;
    }
    
    if (_failed || !_showWebView) {
      // WebView2 failed — use text preview
      return textPreview;
    }

    // WebView2 ready — overlay it on top of text preview
    return Stack(
      children: [
        textPreview,
        RepaintBoundary(
          child: Webview(_controller),
        ),
      ],
    );
  }

  Widget _buildTextPreview(BuildContext context) {
    final bgMatch = RegExp(r"""data-bg-color=["']([^"']+)["']""",
            caseSensitive: false)
        .firstMatch(widget.html);
    final bgHex = bgMatch?.group(1) ?? '#1a1a2e';
    final bgColor = Color(int.parse(bgHex.replaceFirst('#', '0xFF')));

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildHtmlPreview(widget.html),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlPreview(String html) {
    var content = html;
    final h1Matches = RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false).allMatches(content);
    for (final m in h1Matches) {
      final text = _stripTags(m.group(1) ?? '');
      content = content.replaceFirst(m.group(0)!, '## $text');
    }
    final h2Matches = RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false).allMatches(content);
    for (final m in h2Matches) {
      final text = _stripTags(m.group(1) ?? '');
      content = content.replaceFirst(m.group(0)!, '### $text');
    }
    final pMatches = RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false).allMatches(content);
    for (final m in pMatches) {
      final text = _stripTags(m.group(1) ?? '');
      content = content.replaceFirst(m.group(0)!, text);
    }
    final liMatches = RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false).allMatches(content);
    for (final m in liMatches) {
      final text = _stripTags(m.group(1) ?? '');
      content = content.replaceFirst(m.group(0)!, 'BULLET $text');
    }
    content = content.replaceAll(RegExp(r'<[^>]+>'), '');
    content = content.replaceAll('&amp;', '&');
    content = content.replaceAll('&lt;', '<');
    content = content.replaceAll('&gt;', '>');
    content = content.replaceAll('&nbsp;', ' ');
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    final lines = content.trim().split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.where((l) => l.trim().isNotEmpty).map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          );
        }
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              trimmed.substring(4),
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          );
        }
        if (trimmed.startsWith('BULLET ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                Expanded(child: Text(trimmed.substring(7), style: const TextStyle(fontSize: 11, color: Colors.grey))),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            trimmed,
            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          ),
        );
      }).toList(),
    );
  }

  String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
