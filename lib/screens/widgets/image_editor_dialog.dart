import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/image_editor_service.dart';

/// Image Editor Dialog — v1.2.0
/// Cho phép crop, resize, rotate, flip, và điều chỉnh brightness/contrast.
class ImageEditorDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String? initialName;

  const ImageEditorDialog({
    super.key,
    required this.imageBytes,
    this.initialName,
  });

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  late Uint8List _currentImage;
  bool _isProcessing = false;
  double _brightness = 0;
  double _contrast = 0;
  int _rotation = 0;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageBytes;
  }

  Future<void> _applyResize(int width, int height) async {
    setState(() => _isProcessing = true);
    final result = await ImageEditorService.resizeImage(
      _currentImage,
      width: width,
      height: height,
    );
    if (result != null) {
      setState(() {
        _currentImage = result;
        _isProcessing = false;
      });
    } else {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyRotation(int degrees) async {
    setState(() {
      _isProcessing = true;
      _rotation = (_rotation + degrees) % 360;
    });
    final result = await ImageEditorService.rotateImage(_currentImage, degrees: degrees);
    if (result != null) {
      setState(() {
        _currentImage = result;
        _isProcessing = false;
      });
    } else {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyFlip(bool horizontal) async {
    setState(() => _isProcessing = true);
    final result = await ImageEditorService.flipImage(_currentImage, horizontal: horizontal);
    if (result != null) {
      setState(() {
        _currentImage = result;
        _isProcessing = false;
      });
    } else {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyAdjustments() async {
    if (_brightness == 0 && _contrast == 0) return;
    setState(() => _isProcessing = true);
    final result = await ImageEditorService.adjustImage(
      _currentImage,
      brightness: _brightness,
      contrast: _contrast,
    );
    if (result != null) {
      setState(() {
        _currentImage = result;
        _brightness = 0;
        _contrast = 0;
        _isProcessing = false;
      });
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Chỉnh sửa ảnh',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Image.memory(
                                _currentImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (_isProcessing)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Controls
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Resize
                            Text('Kích thước', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Width',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (value) {
                                      final w = int.tryParse(value) ?? 0;
                                      if (w > 0) _applyResize(w, 0);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Height',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (value) {
                                      final h = int.tryParse(value) ?? 0;
                                      if (h > 0) _applyResize(0, h);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Rotation
                            Text('Xoay', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.rotate_left),
                                    label: const Text('90°'),
                                    onPressed: () => _applyRotation(270),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.rotate_right),
                                    label: const Text('90°'),
                                    onPressed: () => _applyRotation(90),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Flip
                            Text('Lật', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.flip),
                                    label: const Text('Ngang'),
                                    onPressed: () => _applyFlip(true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.flip, size: 16),
                                    label: const Text('Dọc'),
                                    onPressed: () => _applyFlip(false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Adjustments
                            Text('Điều chỉnh', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text('Độ sáng: ${_brightness.toInt()}'),
                            Slider(
                              value: _brightness,
                              min: -100,
                              max: 100,
                              divisions: 20,
                              onChanged: (value) => setState(() => _brightness = value),
                            ),
                            Text('Tương phản: ${_contrast.toInt()}'),
                            Slider(
                              value: _contrast,
                              min: -100,
                              max: 100,
                              divisions: 20,
                              onChanged: (value) => setState(() => _contrast = value),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _applyAdjustments,
                              child: const Text('Áp dụng'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () {
                      final dataUri = ImageEditorService.toDataUri(_currentImage);
                      Navigator.of(context).pop(dataUri);
                    },
                    child: const Text('Sử dụng ảnh này'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
