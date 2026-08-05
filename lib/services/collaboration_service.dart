import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../providers/presentation_state.dart';

/// Authenticated local-network collaboration with revisioned snapshot sync.
///
/// Transport is deliberately HTTP polling rather than pretending to provide a
/// WebSocket channel. Every protected request uses a high-entropy session or
/// collaborator token, request bodies are bounded, and stale writes are
/// rejected with the authoritative snapshot.
class CollaborationService {
  static const int maxPayloadBytes = 2 * 1024 * 1024;
  static const int maxSlides = 200;
  static const int maxTitleLength = 500;
  static const int maxHtmlLength = 250000;
  static const int maxNotesLength = 50000;
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration pollInterval = Duration(milliseconds: 900);

  bool _disposed = false;
  HttpServer? _server;
  String? _localIp;
  int _port = 8080;
  CollaborationMode _mode = CollaborationMode.idle;
  final List<CollaboratorInfo> _collaborators = [];
  final Map<String, CollaboratorInfo> _accessTokens = {};
  final StreamController<CollaborationEvent> _eventController =
      StreamController<CollaborationEvent>.broadcast();
  final Random _secureRandom = Random.secure();

  String? _sessionToken;
  String? _clientAccessToken;
  String? _remoteHost;
  int? _remotePort;
  int _revision = 0;
  List<Map<String, dynamic>> _slides = [];
  String _slidesFingerprint = '[]';
  PresentationState? _presentation;
  List<Map<String, dynamic>> Function()? _documentReader;
  FutureOr<void> Function(List<Map<String, dynamic>> slides)? _documentWriter;
  bool _applyingRemoteSnapshot = false;
  Timer? _pollTimer;
  Timer? _pushDebounce;

  bool get isHosting => _mode == CollaborationMode.host;
  bool get isJoined => _mode == CollaborationMode.client;
  bool get isActive => _mode != CollaborationMode.idle;
  CollaborationMode get mode => _mode;
  String? get localIp => _localIp;
  int get port => _port;
  int get revision => _revision;
  List<CollaboratorInfo> get collaborators =>
      List.unmodifiable(_collaborators);
  Stream<CollaborationEvent> get eventStream => _eventController.stream;

  /// Connects collaboration to the real presentation model. Rebinding is safe
  /// and is used by ProxyProvider when the app provider tree rebuilds.
  void bindPresentation(PresentationState presentation) {
    if (identical(_presentation, presentation)) return;
    _presentation?.removeListener(_onLocalPresentationChanged);
    _presentation = presentation;
    _documentReader = () => presentation.slides
        .map((slide) => Map<String, dynamic>.from(slide.toMap()))
        .toList(growable: false);
    _documentWriter = (slides) => presentation.replaceSlidesFromCollaboration(
          slides.map(Slide.fromMap).toList(growable: false),
        );
    presentation.addListener(_onLocalPresentationChanged);
    _captureLocalSlides(incrementRevision: false);
  }

  /// Testable/adaptable document binding for non-Flutter collaboration clients.
  void bindDocument({
    required List<Map<String, dynamic>> Function() readSlides,
    required FutureOr<void> Function(List<Map<String, dynamic>> slides)
        applySlides,
  }) {
    _presentation?.removeListener(_onLocalPresentationChanged);
    _presentation = null;
    _documentReader = readSlides;
    _documentWriter = applySlides;
    _captureLocalSlides(incrementRevision: false);
  }

  /// Signals a local mutation when [bindDocument] is used instead of a
  /// [PresentationState] listener.
  void notifyDocumentChanged() => _onLocalPresentationChanged();

  Future<String?> getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
      if (_localIp != null && _localIp!.isNotEmpty) return _localIp;
    } catch (e) {
      debugPrint('CollaborationService: WiFi IP lookup failed: $e');
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            _localIp = address.address;
            return _localIp;
          }
        }
      }
    } catch (e) {
      debugPrint('CollaborationService: interface lookup failed: $e');
    }
    _localIp = '127.0.0.1';
    return _localIp;
  }

  /// Starts a protected host. Port zero is supported for deterministic tests.
  Future<bool> startHosting({int port = 8080}) async {
    if (_disposed || isActive || port < 0 || port > 65535) return false;
    try {
      _port = port;
      _localIp = await getLocalIpAddress();
      _sessionToken = _newToken(32);
      _revision = 1;
      _captureLocalSlides(incrementRevision: false);

      final router = Router()
        ..get('/health', _handleHealth)
        ..post('/join', _handleJoin)
        ..get('/slides', _handleSlides)
        ..post('/sync', _handleSync);

      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addMiddleware(_securityHeadersMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        port,
        shared: false,
      );
      _port = _server!.port;
      _mode = CollaborationMode.host;
      _emit(CollaborationEventType.sessionStarted, {
        'host': _localIp,
        'port': _port,
      });
      debugPrint('CollaborationService: protected host started on port $_port');
      return true;
    } catch (e) {
      debugPrint('CollaborationService: host start failed: $e');
      await stop();
      return false;
    }
  }

  Future<shelf.Response> _handleHealth(shelf.Request request) async {
    return _jsonResponse(200, {
      'status': 'ok',
      'app': 'GhitaPPT',
      'version': '1.6.0+1',
      'protocol': 2,
    });
  }

  Future<shelf.Response> _handleJoin(shelf.Request request) async {
    if (!_constantTimeEquals(
      request.headers['x-ghita-session-token'] ?? '',
      _sessionToken ?? '',
    )) {
      return _errorResponse(401, 'invalid_session_token');
    }

    try {
      final body = await _readJsonObject(request);
      final name = (body['name'] ?? '').toString().trim();
      final color = (body['color'] ?? '#FF9800').toString();
      if (name.isEmpty || name.length > 64) {
        return _errorResponse(422, 'invalid_collaborator_name');
      }
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
        return _errorResponse(422, 'invalid_collaborator_color');
      }

      final collaborator = CollaboratorInfo(
        id: _newToken(12),
        name: name,
        color: color,
        joinedAt: DateTime.now(),
      );
      final accessToken = _newToken(32);
      _collaborators.add(collaborator);
      _accessTokens[accessToken] = collaborator;
      _emit(CollaborationEventType.userJoined, collaborator);

      return _jsonResponse(200, {
        'success': true,
        'sessionId': 'ghita_${_sessionToken!.substring(0, 12)}',
        'accessToken': accessToken,
        'revision': _revision,
        'slides': _slides,
      });
    } on CollaborationPayloadException catch (e) {
      return _errorResponse(e.statusCode, e.code);
    } catch (_) {
      return _errorResponse(400, 'invalid_json');
    }
  }

  Future<shelf.Response> _handleSlides(shelf.Request request) async {
    if (!_isAuthorizedCollaborator(request)) {
      return _errorResponse(401, 'unauthorized');
    }
    _captureLocalSlides(incrementRevision: true);
    return _jsonResponse(200, {
      'revision': _revision,
      'slides': _slides,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<shelf.Response> _handleSync(shelf.Request request) async {
    if (!_isAuthorizedCollaborator(request)) {
      return _errorResponse(401, 'unauthorized');
    }
    try {
      final body = await _readJsonObject(request);
      final baseRevision = body['baseRevision'];
      if (baseRevision is! int) {
        return _errorResponse(422, 'invalid_base_revision');
      }
      final incomingSlides = _validatedSlides(body['slides']);
      _captureLocalSlides(incrementRevision: true);
      if (baseRevision != _revision) {
        return _jsonResponse(409, {
          'error': 'revision_conflict',
          'revision': _revision,
          'slides': _slides,
        });
      }

      _revision++;
      _slides = incomingSlides;
      _slidesFingerprint = jsonEncode(_slides);
      await _applyRemoteSlides(incomingSlides);
      _emit(CollaborationEventType.slideUpdated, {
        'revision': _revision,
        'slideCount': incomingSlides.length,
      });
      return _jsonResponse(200, {
        'success': true,
        'revision': _revision,
      });
    } on CollaborationPayloadException catch (e) {
      return _errorResponse(e.statusCode, e.code);
    } catch (_) {
      return _errorResponse(400, 'invalid_json');
    }
  }

  /// Joins a host, authenticates, applies the initial snapshot, and starts
  /// revision polling. The session token comes from the host's share URL.
  Future<bool> joinSession({
    required String hostIp,
    required int port,
    required String sessionToken,
    String name = 'User',
  }) async {
    if (_disposed || isActive) return false;
    final normalizedHost = _normalizeHost(hostIp);
    if (normalizedHost == null || port < 1 || port > 65535) return false;
    if (sessionToken.length < 32 || name.trim().isEmpty || name.length > 64) {
      return false;
    }

    final client = HttpClient()..connectionTimeout = requestTimeout;
    try {
      final request = await client
          .post(normalizedHost, port, '/join')
          .timeout(requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-ghita-session-token', sessionToken);
      request.write(jsonEncode({
        'name': name.trim(),
        'color': _randomColor(),
      }));
      final response = await request.close().timeout(requestTimeout);
      final data = await _decodeResponseObject(response);
      if (response.statusCode != 200) return false;

      final accessToken = data['accessToken'];
      final serverRevision = data['revision'];
      if (accessToken is! String ||
          accessToken.length < 32 ||
          serverRevision is! int) {
        return false;
      }
      final initialSlides = _validatedSlides(data['slides']);
      _remoteHost = normalizedHost;
      _remotePort = port;
      _sessionToken = sessionToken;
      _clientAccessToken = accessToken;
      _revision = serverRevision;
      _slides = initialSlides;
      _slidesFingerprint = jsonEncode(initialSlides);
      _mode = CollaborationMode.client;
      await _applyRemoteSlides(initialSlides);
      _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(_pollHost()));
      _emit(CollaborationEventType.sessionJoined, {
        'host': normalizedHost,
        'port': port,
        'revision': _revision,
      });
      return true;
    } catch (e) {
      debugPrint('CollaborationService: join failed: $e');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _pollHost() async {
    if (!isJoined || _disposed) return;
    final response = await _authorizedRequest('GET', '/slides');
    if (response == null) return;
    try {
      final data = await _decodeResponseObject(response);
      if (response.statusCode == 401) {
        _emit(CollaborationEventType.authenticationFailed, null);
        return;
      }
      if (response.statusCode != 200 || data['revision'] is! int) return;
      final serverRevision = data['revision'] as int;
      if (serverRevision <= _revision) return;
      final serverSlides = _validatedSlides(data['slides']);
      _revision = serverRevision;
      _slides = serverSlides;
      _slidesFingerprint = jsonEncode(serverSlides);
      await _applyRemoteSlides(serverSlides);
      _emit(CollaborationEventType.slideUpdated, {
        'revision': _revision,
        'slideCount': serverSlides.length,
      });
    } catch (e) {
      debugPrint('CollaborationService: poll response rejected: $e');
    }
  }

  void _onLocalPresentationChanged() {
    if (_disposed || _applyingRemoteSnapshot || !isActive) return;
    if (isHosting) {
      _captureLocalSlides(incrementRevision: true);
      return;
    }
    _pushDebounce?.cancel();
    _pushDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_pushCurrentSlides()),
    );
  }

  Future<void> _pushCurrentSlides() async {
    if (!isJoined || _disposed) return;
    final current = _presentationSlides();
    final fingerprint = jsonEncode(current);
    if (fingerprint == _slidesFingerprint) return;
    try {
      final response = await _authorizedRequest(
        'POST',
        '/sync',
        body: {
          'baseRevision': _revision,
          'slides': current,
        },
      );
      if (response == null) return;
      final data = await _decodeResponseObject(response);
      if (response.statusCode == 200 && data['revision'] is int) {
        _revision = data['revision'] as int;
        _slides = current;
        _slidesFingerprint = fingerprint;
        return;
      }
      if (response.statusCode == 409 && data['revision'] is int) {
        final authoritative = _validatedSlides(data['slides']);
        _revision = data['revision'] as int;
        _slides = authoritative;
        _slidesFingerprint = jsonEncode(authoritative);
        await _applyRemoteSlides(authoritative);
        _emit(CollaborationEventType.syncConflict, {
          'revision': _revision,
        });
      } else if (response.statusCode == 401) {
        _emit(CollaborationEventType.authenticationFailed, null);
      }
    } catch (e) {
      debugPrint('CollaborationService: sync failed: $e');
    }
  }

  Future<HttpClientResponse?> _authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final host = _remoteHost;
    final port = _remotePort;
    final token = _clientAccessToken;
    if (host == null || port == null || token == null) return null;
    final client = HttpClient()..connectionTimeout = requestTimeout;
    try {
      final request = await client.open(method, host, port, path).timeout(
            requestTimeout,
          );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(requestTimeout);
      // The response owns the socket until consumed by the caller. Closing the
      // client without force allows that response stream to finish normally.
      client.close();
      return response;
    } catch (_) {
      client.close(force: true);
      return null;
    }
  }

  Future<void> leaveSession() async {
    if (!isJoined) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pushDebounce?.cancel();
    _pushDebounce = null;
    _remoteHost = null;
    _remotePort = null;
    _clientAccessToken = null;
    _sessionToken = null;
    _mode = CollaborationMode.idle;
    _emit(CollaborationEventType.sessionStopped, null);
  }

  Future<void> stopHosting() async {
    if (!isHosting && _server == null) return;
    await _server?.close(force: true);
    _server = null;
    _collaborators.clear();
    _accessTokens.clear();
    _sessionToken = null;
    _mode = CollaborationMode.idle;
    _emit(CollaborationEventType.sessionStopped, null);
  }

  Future<void> stop() async {
    if (isHosting || _server != null) {
      await stopHosting();
    } else {
      await leaveSession();
    }
  }

  String? getShareUrl() {
    if (!isHosting || _localIp == null || _sessionToken == null) return null;
    return Uri(
      scheme: 'http',
      host: _localIp,
      port: _port,
      queryParameters: {'token': _sessionToken},
    ).toString();
  }

  String? get sessionTokenForDisplay => isHosting ? _sessionToken : null;

  void _captureLocalSlides({required bool incrementRevision}) {
    final current = _presentationSlides();
    final fingerprint = jsonEncode(current);
    if (fingerprint == _slidesFingerprint) return;
    _slides = current;
    _slidesFingerprint = fingerprint;
    if (incrementRevision && isHosting) _revision++;
  }

  List<Map<String, dynamic>> _presentationSlides() {
    final reader = _documentReader;
    if (reader == null) return List<Map<String, dynamic>>.from(_slides);
    return reader()
        .map((slide) => Map<String, dynamic>.from(slide))
        .toList(growable: false);
  }

  Future<void> _applyRemoteSlides(List<Map<String, dynamic>> rawSlides) async {
    final writer = _documentWriter;
    if (writer == null) return;
    _applyingRemoteSnapshot = true;
    try {
      await Future.sync(() => writer(rawSlides));
    } finally {
      _applyingRemoteSnapshot = false;
    }
  }

  List<Map<String, dynamic>> _validatedSlides(dynamic value) {
    if (value is! List || value.length > maxSlides) {
      throw const CollaborationPayloadException(422, 'invalid_slide_list');
    }
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is! Map) {
        throw const CollaborationPayloadException(422, 'invalid_slide');
      }
      final slide = Map<String, dynamic>.from(item);
      final title = slide['title'];
      final html = slide['htmlContent'];
      final notes = slide['notes'];
      if (title is! String ||
          html is! String ||
          title.length > maxTitleLength ||
          html.length > maxHtmlLength ||
          (notes != null &&
              (notes is! String || notes.length > maxNotesLength))) {
        throw const CollaborationPayloadException(422, 'invalid_slide');
      }
      // Parsing catches malformed optional fields while preserving the exact
      // map representation used by the presentation model.
      Slide.fromMap(slide);
      result.add(slide);
    }
    return result;
  }

  Future<Map<String, dynamic>> _readJsonObject(shelf.Request request) async {
    final declaredLength = int.tryParse(
      request.headers[HttpHeaders.contentLengthHeader] ?? '',
    );
    if (declaredLength != null && declaredLength > maxPayloadBytes) {
      throw const CollaborationPayloadException(413, 'payload_too_large');
    }
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      bytes.addAll(chunk);
      if (bytes.length > maxPayloadBytes) {
        throw const CollaborationPayloadException(413, 'payload_too_large');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    if (decoded is! Map) {
      throw const CollaborationPayloadException(400, 'invalid_json_object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> _decodeResponseObject(
    HttpClientResponse response,
  ) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > maxPayloadBytes) {
        throw const CollaborationPayloadException(413, 'response_too_large');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    if (decoded is! Map) {
      throw const CollaborationPayloadException(400, 'invalid_response');
    }
    return Map<String, dynamic>.from(decoded);
  }

  bool _isAuthorizedCollaborator(shelf.Request request) {
    final authorization = request.headers[HttpHeaders.authorizationHeader];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return false;
    }
    final candidate = authorization.substring(7);
    for (final token in _accessTokens.keys) {
      if (_constantTimeEquals(candidate, token)) return true;
    }
    return false;
  }

  String? _normalizeHost(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 255) return null;
    if (Uri.tryParse('http://$trimmed')?.host case final String host
        when host.isNotEmpty) {
      return host;
    }
    return null;
  }

  shelf.Middleware _securityHeadersMiddleware() {
    return (shelf.Handler innerHandler) {
      return (shelf.Request request) async {
        if (request.method == 'OPTIONS') {
          return _errorResponse(405, 'cors_not_supported');
        }
        final response = await innerHandler(request);
        return response.change(headers: const {
          'Cache-Control': 'no-store',
          'X-Content-Type-Options': 'nosniff',
          'Referrer-Policy': 'no-referrer',
        });
      };
    };
  }

  shelf.Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
    return shelf.Response(
      statusCode,
      body: jsonEncode(body),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    );
  }

  shelf.Response _errorResponse(int statusCode, String code) {
    return _jsonResponse(statusCode, {'error': code});
  }

  String _newToken(int byteLength) {
    final bytes = List<int>.generate(
      byteLength,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _randomColor() {
    final value = _secureRandom.nextInt(0x1000000);
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }

  bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    var difference = leftBytes.length ^ rightBytes.length;
    final length = max(leftBytes.length, rightBytes.length);
    for (var index = 0; index < length; index++) {
      final leftByte = index < leftBytes.length ? leftBytes[index] : 0;
      final rightByte = index < rightBytes.length ? rightBytes[index] : 0;
      difference |= leftByte ^ rightByte;
    }
    return difference == 0;
  }

  void _emit(CollaborationEventType type, dynamic data) {
    if (!_disposed && !_eventController.isClosed) {
      _eventController.add(CollaborationEvent(type: type, data: data));
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _presentation?.removeListener(_onLocalPresentationChanged);
    _presentation = null;
    _documentReader = null;
    _documentWriter = null;
    _pollTimer?.cancel();
    _pushDebounce?.cancel();
    unawaited(_server?.close(force: true));
    _server = null;
    unawaited(_eventController.close());
  }
}

enum CollaborationMode { idle, host, client }

class CollaboratorInfo {
  final String id;
  final String name;
  final String color;
  final DateTime joinedAt;

  const CollaboratorInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
      };
}

enum CollaborationEventType {
  sessionStarted,
  sessionJoined,
  sessionStopped,
  userJoined,
  userLeft,
  slideUpdated,
  syncConflict,
  authenticationFailed,
}

class CollaborationEvent {
  final CollaborationEventType type;
  final dynamic data;

  const CollaborationEvent({required this.type, this.data});
}

class CollaborationPayloadException implements Exception {
  final int statusCode;
  final String code;

  const CollaborationPayloadException(this.statusCode, this.code);

  @override
  String toString() => 'CollaborationPayloadException($statusCode, $code)';
}
