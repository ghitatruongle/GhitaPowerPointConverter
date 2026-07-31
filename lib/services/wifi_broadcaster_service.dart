import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Local HTTP Broadcaster Service to stream live presentation slides over local Wi-Fi.
class WifiBroadcasterService {
  HttpServer? _server;
  String _currentSlideHtml = '<h1>Waiting for presentation...</h1>';
  int _serverPort = 8090;

  bool get isRunning => _server != null;
  int get port => _serverPort;

  /// Starts the local HTTP presentation server with automatic port fallback.
  Future<String?> startBroadcaster({int port = 8090, int maxPort = 8099}) async {
    for (int tryPort = port; tryPort <= maxPort; tryPort++) {
      try {
        await stopBroadcaster();
        _serverPort = tryPort;
        _server = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort);
        debugPrint('WifiBroadcasterService running on port $_serverPort');

        _server?.listen((HttpRequest request) {
          request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
          final htmlPage = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Live Presentation Broadcaster</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #0f172a; color: white; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 24px; box-sizing: border-box; }
    .card { background: #1e293b; border-radius: 16px; padding: 32px; width: 100%; max-width: 900px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
  </style>
  <script>
    setTimeout(function() { location.reload(); }, 3000);
  </script>
</head>
<body>
  <div class="card">
    $_currentSlideHtml
  </div>
</body>
</html>
''';
          request.response.write(htmlPage);
          request.response.close();
        });

        // Bind succeeded — break out of the port-fallback loop.
        break;
      } catch (e) {
        debugPrint('WifiBroadcasterService: Port $tryPort unavailable, trying next...');
        _server = null;
        if (tryPort == maxPort) {
          debugPrint('WifiBroadcasterService: All ports $port-$maxPort are unavailable.');
          return null;
        }
      }
    }

    // Get primary IPv4 address (outside the bind-retry loop: an interface
    // listing failure must not abandon a successfully bound server).
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return 'http://${addr.address}:$_serverPort';
          }
        }
      }
    } catch (e) {
      debugPrint('WifiBroadcasterService Error listing interfaces: $e');
    }
    return 'http://localhost:$_serverPort';
  }

  /// Updates the current active slide HTML broadcast.
  void updateActiveSlide(String slideHtml) {
    _currentSlideHtml = slideHtml;
  }

  /// Stops the broadcast server.
  Future<void> stopBroadcaster() async {
    await _server?.close(force: true);
    _server = null;
    debugPrint('WifiBroadcasterService stopped.');
  }
}
