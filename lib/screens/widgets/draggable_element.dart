import 'package:flutter/material.dart';

/// A draggable, resizable element within the visual slide editor.
/// Supports text, shapes, and images with position, size, and rotation.
class DraggableElement extends StatefulWidget {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int zIndex;
  final String type; // 'text', 'shape', 'image'
  final String content;
  final String style;
  final bool isSelected;
  final ValueChanged<DraggableElementData> onPositionChanged;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DraggableElement({
    super.key,
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.zIndex = 0,
    this.type = 'text',
    this.content = '',
    this.style = '',
    this.isSelected = false,
    required this.onPositionChanged,
    this.onTap,
    this.onDelete,
  });

  @override
  State<DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends State<DraggableElement> {
  late double _x;
  late double _y;
  late double _width;
  late double _height;
  bool _isDragging = false;
  bool _isResizing = false;

  // Snap-to-grid settings
  static const double _gridSize = 10;

  @override
  void initState() {
    super.initState();
    _x = widget.x;
    _y = widget.y;
    _width = widget.width;
    _height = widget.height;
  }

  @override
  void didUpdateWidget(DraggableElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && !_isResizing) {
      _x = widget.x;
      _y = widget.y;
      _width = widget.width;
      _height = widget.height;
    }
  }

  double _snapToGrid(double value) {
    return (value / _gridSize).round() * _gridSize;
  }

  void _updatePosition(double dx, double dy) {
    setState(() {
      _x = _snapToGrid(_x + dx);
      _y = _snapToGrid(_y + dy);
    });
    widget.onPositionChanged(DraggableElementData(
      id: widget.id,
      x: _x,
      y: _y,
      width: _width,
      height: _height,
    ));
  }

  void _updateSize(double dw, double dh) {
    setState(() {
      _width = (_width + dw).clamp(40, 800);
      _height = (_height + dh).clamp(30, 600);
    });
    widget.onPositionChanged(DraggableElementData(
      id: widget.id,
      x: _x,
      y: _y,
      width: _width,
      height: _height,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) {
          setState(() => _isDragging = true);
        },
        onPanUpdate: (details) {
          _updatePosition(details.delta.dx, details.delta.dy);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
        },
        child: Transform.rotate(
          angle: widget.rotation * 3.14159 / 180,
          child: Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: widget.isSelected ? 2 : 0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Content
                _buildContent(theme),

                // Resize handle (bottom-right corner)
                if (widget.isSelected)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() => _isResizing = true);
                      },
                      onPanUpdate: (details) {
                        _updateSize(details.delta.dx, details.delta.dy);
                      },
                      onPanEnd: (_) {
                        setState(() => _isResizing = false);
                      },
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                // Delete button
                if (widget.isSelected && widget.onDelete != null)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),

                // Element type badge
                if (widget.isSelected)
                  Positioned(
                    left: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.colorScheme.primary, width: 0.5),
                      ),
                      child: Text(
                        widget.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (widget.type) {
      case 'text':
        return Container(
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            widget.content.isEmpty ? 'Text' : widget.content,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            maxLines: null,
          ),
        );

      case 'shape':
        return Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        );

      case 'image':
        return Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 32,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 4),
              Text(
                'Image',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

/// Data class for element position/size changes.
class DraggableElementData {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;

  const DraggableElementData({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
