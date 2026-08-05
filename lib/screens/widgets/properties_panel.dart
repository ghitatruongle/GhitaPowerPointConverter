import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';

/// Properties Panel — right sidebar for formatting selected elements,
/// similar to PowerPoint's Format Shape pane.
/// v1.2.0: All controls fully wired — no stubs.
class PropertiesPanel extends StatefulWidget {
  /// Insert an HTML tag wrapping the current selection.
  final void Function(String openTag, String closeTag)? onInsertHtmlTag;

  /// Insert raw HTML at cursor position.
  final void Function(String html)? onInsertHtml;

  /// Set slide background color.
  final void Function(String hexColor)? onSetSlideBackground;

  const PropertiesPanel({
    super.key,
    this.onInsertHtmlTag,
    this.onInsertHtml,
    this.onSetSlideBackground,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  bool _showSlideProperties = true;
  bool _showTextProperties = true;
  bool _showShapeProperties = false;

  // Track current selections for visual feedback
  String _selectedFont = 'Segoe UI';
  int _selectedSize = 14;
  String _selectedLayout = 'Blank';
  bool _isBold = false;
  bool _isItalic = false;
  bool _hasShadow = false;
  double _transparency = 0;
  Color _fillColor = Colors.transparent;
  Color _borderColor = Colors.grey;
  double _borderWidth = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentationState = Provider.of<PresentationState>(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Format',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === SLIDE PROPERTIES ===
                  _buildSection(
                    context,
                    title: 'Slide Properties',
                    isExpanded: _showSlideProperties,
                    onToggle: () => setState(() => _showSlideProperties = !_showSlideProperties),
                    children: [
                      _buildPropertyRow(
                        context,
                        label: 'Background',
                        child: _buildInteractiveColorPicker(
                          context,
                          currentColor: _parseBgColor(presentationState),
                          title: 'Chọn màu nền slide',
                          onColorSelected: (color) {
                            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                            widget.onSetSlideBackground?.call(hex);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Transition',
                        child: _buildTransitionDropdown(context, presentationState),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Layout',
                        child: _buildLayoutDropdown(context),
                      ),
                    ],
                  ),

                  const Divider(height: 16),

                  // === TEXT PROPERTIES ===
                  _buildSection(
                    context,
                    title: 'Text',
                    isExpanded: _showTextProperties,
                    onToggle: () => setState(() => _showTextProperties = !_showTextProperties),
                    children: [
                      _buildPropertyRow(
                        context,
                        label: 'Font',
                        child: _buildFontDropdown(context),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Size',
                        child: _buildSizeDropdown(context),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Color',
                        child: _buildInteractiveColorPicker(
                          context,
                          currentColor: Colors.white,
                          title: 'Chọn màu chữ',
                          onColorSelected: (color) {
                            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                            widget.onInsertHtmlTag?.call(
                              '<span style="color: $hex">',
                              '</span>',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Alignment',
                        child: _buildAlignmentRow(context),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Bold',
                        child: Switch(
                          value: _isBold,
                          onChanged: (v) {
                            setState(() => _isBold = v);
                            if (v) {
                              widget.onInsertHtmlTag?.call('<strong>', '</strong>');
                            }
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      _buildPropertyRow(
                        context,
                        label: 'Italic',
                        child: Switch(
                          value: _isItalic,
                          onChanged: (v) {
                            setState(() => _isItalic = v);
                            if (v) {
                              widget.onInsertHtmlTag?.call('<em>', '</em>');
                            }
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 16),

                  // === SHAPE PROPERTIES ===
                  _buildSection(
                    context,
                    title: 'Shape',
                    isExpanded: _showShapeProperties,
                    onToggle: () => setState(() => _showShapeProperties = !_showShapeProperties),
                    children: [
                      _buildPropertyRow(
                        context,
                        label: 'Fill',
                        child: _buildInteractiveColorPicker(
                          context,
                          currentColor: _fillColor,
                          title: 'Chọn màu fill',
                          onColorSelected: (color) {
                            setState(() => _fillColor = color);
                            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                            widget.onInsertHtml?.call(
                              '<div style="background-color: $hex; padding: 12px; border-radius: 8px; margin: 8px 0;">\n'
                              '  <p>Shape content</p>\n</div>',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Border',
                        child: _buildInteractiveColorPicker(
                          context,
                          currentColor: _borderColor,
                          title: 'Chọn màu viền',
                          onColorSelected: (color) {
                            setState(() => _borderColor = color);
                            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                            widget.onInsertHtml?.call(
                              '<div style="border: ${_borderWidth.round()}px solid $hex; padding: 12px; border-radius: 8px; margin: 8px 0;">\n'
                              '  <p>Bordered content</p>\n</div>',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Border Width',
                        child: SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '${_borderWidth.round()}px',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            style: const TextStyle(fontSize: 11),
                            keyboardType: TextInputType.number,
                            onSubmitted: (value) {
                              final w = double.tryParse(value.replaceAll('px', '')) ?? 1;
                              setState(() => _borderWidth = w);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Shadow',
                        child: Switch(
                          value: _hasShadow,
                          onChanged: (v) {
                            setState(() => _hasShadow = v);
                            if (v) {
                              widget.onInsertHtmlTag?.call(
                                '<div style="box-shadow: 2px 4px 8px rgba(0,0,0,0.3); padding: 8px; border-radius: 8px;">',
                                '</div>',
                              );
                            }
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Opacity',
                        child: SizedBox(
                          width: 100,
                          child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 2,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
                            child: Slider(
                              value: 1.0 - _transparency,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              label: '${((1.0 - _transparency) * 100).round()}%',
                              onChanged: (v) {
                                setState(() => _transparency = 1.0 - v);
                                widget.onInsertHtmlTag?.call(
                                  '<div style="opacity: ${v.toStringAsFixed(1)}">',
                                  '</div>',
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Color _parseBgColor(PresentationState state) {
    final idx = state.currentSlideIndex;
    if (idx >= 0 && idx < state.slides.length) {
      final bg = state.slides[idx].bgColor;
      if (bg != null && bg.startsWith('#')) {
        try {
          return Color(int.parse('FF${bg.substring(1)}', radix: 16));
        } catch (_) {}
      }
    }
    return const Color(0xFF1a1a2e);
  }

  // ===========================================================================
  // Section Builder
  // ===========================================================================

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildPropertyRow(BuildContext context, {required String label, required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ===========================================================================
  // Interactive Color Picker
  // ===========================================================================

  Widget _buildInteractiveColorPicker(
    BuildContext context, {
    required Color currentColor,
    required String title,
    required void Function(Color) onColorSelected,
  }) {
    return GestureDetector(
      onTap: () => _showColorDialog(context, currentColor, title, onColorSelected),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
        child: currentColor == Colors.transparent
            ? const Center(child: Text('None', style: TextStyle(fontSize: 9, color: Colors.grey)))
            : null,
      ),
    );
  }

  void _showColorDialog(
    BuildContext context,
    Color initialColor,
    String title,
    void Function(Color) onColorSelected,
  ) {
    Color selected = initialColor;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 280,
            height: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: selected,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 6,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
                      Colors.white, const Color(0xFF1a1a2e), const Color(0xFF16213e),
                      Colors.transparent,
                    ].map((c) => GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onColorSelected(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: selected == c ? Colors.white : Colors.grey.shade300,
                            width: selected == c ? 2 : 1,
                          ),
                        ),
                        child: c == Colors.transparent
                            ? const Center(child: Icon(Icons.block, size: 14, color: Colors.grey))
                            : null,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Dropdowns & Controls
  // ===========================================================================

  Widget _buildTransitionDropdown(BuildContext context, PresentationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<SlideEffect>(
        value: state.slideEffect,
        isDense: true,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: SlideEffect.values
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name, style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        onChanged: (val) {
          if (val != null) state.setEffect(val);
        },
      ),
    );
  }

  Widget _buildLayoutDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedLayout,
        isDense: true,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: const [
          DropdownMenuItem(value: 'Blank', child: Text('Blank', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Title Slide', child: Text('Title Slide', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Title + Content', child: Text('Title + Content', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Two Content', child: Text('Two Content', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Section Header', child: Text('Section Header', style: TextStyle(fontSize: 11))),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedLayout = val);
            // Insert layout-specific HTML template
            String html;
            switch (val) {
              case 'Title Slide':
                html = '<div style="text-align: center; padding-top: 20vh;">\n'
                    '  <h1 style="font-size: 2.5em;">Presentation Title</h1>\n'
                    '  <p style="font-size: 1.2em; color: #aaa; margin-top: 16px;">Subtitle or Author Name</p>\n</div>';
                break;
              case 'Title + Content':
                html = '<h1>Slide Title</h1>\n'
                    '<ul>\n  <li>Main point one</li>\n  <li>Main point two</li>\n  <li>Main point three</li>\n</ul>';
                break;
              case 'Two Content':
                html = '<h1>Comparison</h1>\n'
                    '<div style="display: flex; gap: 24px;">\n'
                    '  <div style="flex: 1;">\n    <h2>Left Column</h2>\n    <p>Content here</p>\n  </div>\n'
                    '  <div style="flex: 1;">\n    <h2>Right Column</h2>\n    <p>Content here</p>\n  </div>\n</div>';
                break;
              case 'Section Header':
                html = '<div style="text-align: center; padding-top: 15vh;">\n'
                    '  <h1 style="font-size: 2em; border-bottom: 3px solid #e65100; display: inline-block; padding-bottom: 8px;">Section Title</h1>\n'
                    '  <p style="color: #aaa; margin-top: 16px;">Brief section description</p>\n</div>';
                break;
              default:
                html = '<h1>New Slide</h1>\n<p>Click to add content</p>';
            }
            widget.onInsertHtml?.call(html);
          }
        },
      ),
    );
  }

  Widget _buildFontDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedFont,
        isDense: true,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: const [
          DropdownMenuItem(value: 'Segoe UI', child: Text('Segoe UI', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Arial', child: Text('Arial', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Calibri', child: Text('Calibri', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Consolas', child: Text('Consolas', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Georgia', child: Text('Georgia', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Verdana', child: Text('Verdana', style: TextStyle(fontSize: 11))),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedFont = val);
            widget.onInsertHtmlTag?.call(
              '<span style="font-family: \'$val\'">',
              '</span>',
            );
          }
        },
      ),
    );
  }

  Widget _buildSizeDropdown(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<int>(
        value: _selectedSize,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('$s', style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedSize = val);
            widget.onInsertHtmlTag?.call(
              '<span style="font-size: ${val}px">',
              '</span>',
            );
          }
        },
      ),
    );
  }

  Widget _buildAlignmentRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.format_align_left, size: 16),
          tooltip: 'Align Left',
          onPressed: () => widget.onInsertHtml?.call('<div style="text-align: left">'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          icon: const Icon(Icons.format_align_center, size: 16),
          tooltip: 'Align Center',
          onPressed: () => widget.onInsertHtml?.call('<div style="text-align: center">'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          icon: const Icon(Icons.format_align_right, size: 16),
          tooltip: 'Align Right',
          onPressed: () => widget.onInsertHtml?.call('<div style="text-align: right">'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }
}
