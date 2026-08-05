import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// A decoded image ready to be embedded into an export (PPTX/PDF).
class LoadedImage {
  final Uint8List bytes;
  final String ext; // png, jpg, gif
  final int width;
  final int height;

  LoadedImage({
    required this.bytes,
    required this.ext,
    required this.width,
    required this.height,
  });
}

/// Loads `<img src="...">` sources for export embedding.
///
/// Supports base64 data URIs and local file paths. Remote http/https URLs are
/// intentionally not fetched so exports stay offline and deterministic.
class HtmlImageLoader {
  static final RegExp _dataUriRegExp =
      RegExp(r'^data:image/(png|jpe?g|gif);base64,(.+)$', dotAll: true);

  /// Load an exportable image and, when [maxWidth] is set, downscale it to
  /// that pixel width while preserving aspect ratio. Re-encoding resized
  /// files as PNG keeps the result deterministic across PPTX, PDF and HTML.
  static LoadedImage? load(String src, {int? maxWidth}) {
    final trimmed = src.trim();
    if (trimmed.isEmpty) return null;

    Uint8List? bytes;
    String? ext;

    final dataMatch = _dataUriRegExp.firstMatch(trimmed);
    if (dataMatch != null) {
      try {
        bytes = base64Decode(dataMatch.group(2)!.replaceAll(RegExp(r'\s'), ''));
      } catch (_) {
        return null;
      }
      ext = _normalizeExt(dataMatch.group(1)!);
    } else if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      // Remote images are not downloaded.
      return null;
    } else {
      // Treat as a local file path (absolute or relative).
      try {
        final file = File(trimmed);
        if (!file.existsSync()) return null;
        bytes = file.readAsBytesSync();
      } catch (_) {
        return null;
      }
      final dotIndex = trimmed.lastIndexOf('.');
      if (dotIndex == -1) return null;
      ext = _normalizeExt(trimmed.substring(dotIndex + 1).toLowerCase());
    }

    if (!const ['png', 'jpg', 'gif'].contains(ext)) return null;

    // Decode to obtain intrinsic dimensions (also validates the bytes).
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    if (maxWidth != null && maxWidth > 0 && decoded.width > maxWidth) {
      final resized = img.copyResize(decoded, width: maxWidth);
      return LoadedImage(
        bytes: Uint8List.fromList(img.encodePng(resized)),
        ext: 'png',
        width: resized.width,
        height: resized.height,
      );
    }

    return LoadedImage(
      bytes: bytes,
      ext: ext,
      width: decoded.width,
      height: decoded.height,
    );
  }

  static String _normalizeExt(String raw) => raw == 'jpeg' ? 'jpg' : raw;
}
