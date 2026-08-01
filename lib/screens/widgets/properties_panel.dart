import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';

/// Properties Panel — right sidebar for formatting selected elements,
/// similar to PowerPoint's Format Shape pane.
class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  bool _showSlideProperties = true;
  bool _showTextProperties = false;
  bool _showShapeProperties = false;

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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                  // Slide Properties
                  _buildSection(
                    context,
                    title: 'Slide Properties',
                    isExpanded: _showSlideProperties,
                    onToggle: () => setState(() => _showSlideProperties = !_showSlideProperties),
                    children: [
                      _buildPropertyRow(
                        context,
                        label: 'Background',
                        child: _buildColorPicker(context, Colors.blue.shade900),
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

                  // Text Properties
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
                        child: _buildColorPicker(context, Colors.white),
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
                          value: false,
                          onChanged: (v) {},
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      _buildPropertyRow(
                        context,
                        label: 'Italic',
                        child: Switch(
                          value: false,
                          onChanged: (v) {},
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 16),

                  // Shape Properties
                  _buildSection(
                    context,
                    title: 'Shape',
                    isExpanded: _showShapeProperties,
                    onToggle: () => setState(() => _showShapeProperties = !_showShapeProperties),
                    children: [
                      _buildPropertyRow(
                        context,
                        label: 'Fill',
                        child: _buildColorPicker(context, Colors.transparent),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Border',
                        child: _buildColorPicker(context, Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Border Width',
                        child: SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '1px',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Shadow',
                        child: Switch(
                          value: false,
                          onChanged: (v) {},
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPropertyRow(
                        context,
                        label: 'Transparency',
                        child: SizedBox(
                          width: 80,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: 0,
                              min: 0,
                              max: 1,
                              onChanged: (v) {},
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

  Widget _buildPropertyRow(BuildContext context,
      {required String label, required Widget child}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildColorPicker(BuildContext context, Color currentColor) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: currentColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildTransitionDropdown(BuildContext context, PresentationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<SlideEffect>(
        value: state.slideEffect,
        isDense: true,
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: 'Blank',
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: const [
          DropdownMenuItem(value: 'Blank', child: Text('Blank', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Title', child: Text('Title Slide', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Title+Content', child: Text('Title + Content', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Two Content', child: Text('Two Content', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Section', child: Text('Section Header', style: TextStyle(fontSize: 11))),
        ],
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildFontDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: 'Segoe UI',
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: const [
          DropdownMenuItem(value: 'Segoe UI', child: Text('Segoe UI', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Arial', child: Text('Arial', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Calibri', child: Text('Calibri', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman', style: TextStyle(fontSize: 11))),
          DropdownMenuItem(value: 'Consolas', child: Text('Consolas', style: TextStyle(fontSize: 11))),
        ],
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildSizeDropdown(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<int>(
        value: 14,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
        items: [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('$s', style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildAlignmentRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.format_align_left, size: 16),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          icon: const Icon(Icons.format_align_center, size: 16),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          icon: const Icon(Icons.format_align_right, size: 16),
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }
}
