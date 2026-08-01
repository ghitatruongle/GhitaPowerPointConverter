import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';
import '../../screens/widgets/slide_preview.dart';
import '../../screens/widgets/wysiwyg_toolbar.dart';
import '../editor/editor_state.dart';

/// Central editor panel containing the HTML editor, WYSIWYG toolbar,
/// and live preview — the main content editing area.
class HtmlEditorPanel extends StatefulWidget {
  const HtmlEditorPanel({super.key});

  @override
  State<HtmlEditorPanel> createState() => _HtmlEditorPanelState();
}

class _HtmlEditorPanelState extends State<HtmlEditorPanel> {
  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Title + Notes bar
          _buildTitleBar(context, editorState, theme),

          const Divider(height: 1),

          // WYSIWYG toolbar
          WysiwygToolbar(onInsertTag: editorState.insertHtmlTag),

          const Divider(height: 1),

          // Editor + Preview
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HTML editor
                Expanded(
                  flex: editorState.showPreview ? 1 : 3,
                  child: _buildHtmlEditor(context, editorState, theme),
                ),

                // Live preview
                if (editorState.showPreview) ...[
                  VerticalDivider(width: 1, color: theme.dividerColor),
                  Expanded(
                    flex: 1,
                    child: _buildLivePreview(context, editorState, theme),
                  ),
                ],
              ],
            ),
          ),

          // Notes panel (toggleable)
          if (editorState.showNotes) ...[
            const Divider(height: 1),
            _buildNotesPanel(context, editorState, theme),
          ],

          // Bottom action bar
          const Divider(height: 1),
          _buildActionBar(context, editorState, theme),
        ],
      ),
    );
  }

  Widget _buildTitleBar(
      BuildContext context, EditorState editorState, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Row(
        children: [
          // Editing indicator
          if (editorState.isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 12, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Editing #${editorState.editingIndex! + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Title field
          Expanded(
            child: TextField(
              controller: editorState.titleController,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Slide title...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.title, size: 16, color: theme.colorScheme.outline),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),

          // Transition effect dropdown
          _buildEffectDropdown(context, editorState, theme),

          const SizedBox(width: 4),

          // Preview toggle
          IconButton(
            icon: Icon(
              editorState.showPreview ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
            tooltip: 'Toggle Preview',
            onPressed: editorState.togglePreview,
            visualDensity: VisualDensity.compact,
          ),

          // Notes toggle
          IconButton(
            icon: Icon(
              editorState.showNotes ? Icons.notes : Icons.notes_outlined,
              size: 18,
            ),
            tooltip: 'Toggle Notes',
            onPressed: editorState.toggleNotes,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEffectDropdown(
      BuildContext context, EditorState editorState, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<SlideEffect?>(
        value: editorState.slideEffectOverride,
        hint: Text('Effect', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
        underline: const SizedBox.shrink(),
        isDense: true,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
        items: [
          DropdownMenuItem<SlideEffect?>(
            value: null,
            child: Text('Deck effect', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
          ),
          ...SlideEffect.values.map(
            (e) => DropdownMenuItem<SlideEffect?>(
              value: e,
              child: Text(EditorState.effectName(e), style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
        onChanged: (val) {
          editorState.setSlideEffectOverride(val);
        },
      ),
    );
  }

  Widget _buildHtmlEditor(
      BuildContext context, EditorState editorState, ThemeData theme) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            controller: editorState.htmlController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontFamilyFallback: ['monospace'],
              fontSize: 13,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: '<h1>Title</h1>\n<p>Content...</p>\n<ul>\n  <li>Item</li>\n</ul>',
              hintStyle: TextStyle(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                fontFamily: 'Consolas',
                fontFamilyFallback: ['monospace'],
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(8),
            ),
            keyboardType: TextInputType.multiline,
          ),
        ),
        if (editorState.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildLivePreview(
      BuildContext context, EditorState editorState, ThemeData theme) {
    return Column(
      children: [
        // Preview header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              Icon(Icons.preview, size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Zoom controls
              IconButton(
                icon: const Icon(Icons.remove, size: 14),
                onPressed: editorState.zoomOut,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
              Text(
                '${(editorState.zoomLevel * 100).round()}%',
                style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14),
                onPressed: editorState.zoomIn,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
            ],
          ),
        ),
        // Preview content
        Expanded(
          child: editorState.previewHtml.trim().isEmpty
              ? Center(
                  child: Text(
                    'Start typing to see preview',
                    style: TextStyle(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                )
              : ClipRect(
                  child: Transform.scale(
                    scale: editorState.zoomLevel,
                    alignment: Alignment.topCenter,
                    child: SlidePreview(
                      title: editorState.titleController.text,
                      html: editorState.previewHtml,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotesPanel(
      BuildContext context, EditorState editorState, ThemeData theme) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'Speaker Notes',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: editorState.toggleNotes,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
            ],
          ),
          Expanded(
            child: TextField(
              controller: editorState.notesController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Notes for the presenter...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
      BuildContext context, EditorState editorState, ThemeData theme) {
    final presentationState = Provider.of<PresentationState>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      ),
      child: Row(
        children: [
          // Add/Update button
          FilledButton.icon(
            onPressed: editorState.isLoading
                ? null
                : () => editorState.addOrUpdateSlide(context),
            icon: Icon(editorState.isEditing ? Icons.save : Icons.add, size: 16),
            label: Text(
              editorState.isEditing ? 'Update' : 'Add Slide',
              style: const TextStyle(fontSize: 12),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),

          if (editorState.isEditing) ...[
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: editorState.clearEditor,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Cancel', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ],

          const Spacer(),

          // Present button
          if (presentationState.slides.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: SlidePreview(
                        title: presentationState.presentationTitle,
                        html: presentationState.buildHtmlDeck(),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Present', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }
}
