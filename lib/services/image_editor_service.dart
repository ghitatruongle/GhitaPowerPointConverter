import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';

/// Image Editor Service — v1.2.0
/// Handles image picking, editing (crop, resize, rotate, flip, filters), and base64 encoding.
class ImageEditorService {
  /// Pick an image file and return base64 data URI.
  static Future<String?> pickImageAsBase64() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final ext = result.files.single.extension ?? 'png';
        return 'data:image/$ext;base64,$base64Str';
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Resize an image to the given width/height (maintains aspect ratio if one is 0).
  static Future<Uint8List?> resizeImage(Uint8List bytes, {int width = 0, int height = 0}) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final resized = img.copyResize(
        image,
        width: width > 0 ? width : (height > 0 ? (image.width * height / image.height).round() : image.width),
        height: height > 0 ? height : (width > 0 ? (image.height * width / image.width).round() : image.height),
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(img.encodePng(resized));
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return null;
    }
  }

  /// Rotate image by 90/180/270 degrees.
  static Future<Uint8List?> rotateImage(Uint8List bytes, {int degrees = 90}) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final rotated = switch (degrees) {
        90 => img.copyRotate(image, angle: 90),
        180 => img.copyRotate(image, angle: 180),
        270 => img.copyRotate(image, angle: 270),
        _ => image,
      };
      return Uint8List.fromList(img.encodePng(rotated));
    } catch (e) {
      debugPrint('Error rotating image: $e');
      return null;
    }
  }

  /// Flip image horizontally or vertically.
  static Future<Uint8List?> flipImage(Uint8List bytes, {bool horizontal = true}) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final flipped = horizontal ? img.copyFlip(image, direction: img.FlipDirection.horizontal) : img.copyFlip(image, direction: img.FlipDirection.vertical);
      return Uint8List.fromList(img.encodePng(flipped));
    } catch (e) {
      debugPrint('Error flipping image: $e');
      return null;
    }
  }

  /// Apply brightness/contrast adjustment.
  static Future<Uint8List?> adjustImage(Uint8List bytes, {double brightness = 0, double contrast = 0}) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      var adjusted = image;
      if (brightness != 0) {
        // image v4: brightness is a multiplier (1.0 = unchanged), not a delta
        adjusted = img.adjustColor(adjusted, brightness: 1.0 + brightness / 100);
      }
      if (contrast != 0) {
        adjusted = img.adjustColor(adjusted, contrast: 1.0 + contrast / 100);
      }
      return Uint8List.fromList(img.encodePng(adjusted));
    } catch (e) {
      debugPrint('Error adjusting image: $e');
      return null;
    }
  }

  /// Convert edited bytes to base64 data URI.
  static String toDataUri(Uint8List bytes, {String format = 'png'}) {
    final base64Str = base64Encode(bytes);
    return 'data:image/$format;base64,$base64Str';
  }

  /// Generate HTML <img> tag from a data URI.
  static String toImgTag(String dataUri, {String alt = 'Image', String maxWidth = '100%'}) {
    return '<img src="$dataUri" style="max-width: $maxWidth; height: auto; border-radius: 8px;" alt="$alt" />';
  }
}
