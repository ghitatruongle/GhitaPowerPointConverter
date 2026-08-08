import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';
import '../../services/template_service.dart';
import '../../models/slide_template.dart';
import '../../screens/present_screen.dart';
import 'editor_state.dart';
import 'slide_list_panel.dart';
import 'html_editor_panel.dart';
import '../widgets/advanced_export_dialog.dart';
import '../widgets/collaboration_panel.dart';
import '../../l10n/l10n.dart';

/// Main editor shell with PowerPoint-style 3-panel layout:
/// Left: Slide thumbnails | Center: HTML editor + preview | Right: (future Properties)
///
/// This replaces the monolithic HtmlToPPTScreen with a clean, composable layout.
///
/// The EditorState is owned by HomeScreen (single source of truth so the
/// ribbon toolbar and status bar can drive the same editor instance); this
/// shell resolves it from the provider scope instead of creating its own.
class EditorShell extends StatefulWidget {
  const EditorShell({super.key});

  @override
  State<EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends State<EditorShell> {
  EditorState get _editorState =>
      Provider.of<EditorState>(context, listen: false);

  // ---- Export Dialog ----

  Future<void> _showExportDialog() => showDialog<void>(
        context: context,
        builder: (_) => const AdvancedExportDialog(),
      );

  Future<void> _showCollaboration() => showDialog<void>(
        context: context,
        builder: (_) => const CollaborationPanel(),
      );

  // ---- Template Gallery ----

  Future<void> _showTemplateGallery() async {
    final templateService = TemplateService();
    final templates = await templateService.loadTemplates();
    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noTemplates)),
        );
      }
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth * 0.85;
        return AlertDialog(
          title: Text(context.l10n.chooseTemplate),
          content: SizedBox(
            width: dialogWidth > 600 ? 600 : dialogWidth,
            height: 450,
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: template.accentColor,
                      child: Icon(template.icon, color: Colors.white, size: 20),
                    ),
                    title: Text(template.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(template.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        _editorState.applyTemplate(template, context);
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.useTemplate),
                    ),
                    onTap: () => _previewTemplate(template),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _previewTemplate(SlideTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.description,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(context.l10n.htmlPreview,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    template.htmlContent,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.5),
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                      'Effect: ${EditorState.effectName(template.recommendedEffect)}'),
                  avatar: const Icon(Icons.animation, size: 16),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _editorState.applyTemplate(template, context);
            },
            child: Text(context.l10n.useThisTemplate),
          ),
        ],
      ),
    );
  }

  // ---- Clear All ----

  void _confirmClearAll() {
    final state = Provider.of<PresentationState>(context, listen: false);
    if (state.slides.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearAllSlides),
        content: Text(context.l10n.clearAllSlidesMessage(state.slides.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              state.clearSlides();
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(context.l10n.deletedAllSlides),
                  action: SnackBarAction(
                    label: context.l10n.undoAction,
                    onPressed: () => state.undo(),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: Text(context.l10n.clearAllSlides),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentationState = Provider.of<PresentationState>(context);
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _editorState,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
              _editorState.addOrUpdateSlide(context),
          const SingleActivator(LogicalKeyboardKey.keyE, control: true): () =>
              _showExportDialog(),
          // Ctrl+S must SAVE (matches QAT tooltip "Save (Ctrl+S)") — it must
          // NOT open the export dialog.
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () async {
            await presentationState.savePresentation();
          },
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
              presentationState.undo(),
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
              presentationState.redo(),
        },
        // Keep the focusable node inside CallbackShortcuts so its key-event
        // handler is guaranteed to sit on the active focus path. This mirrors
        // the working shortcut structure used by the presentation screen.
        child: Focus(
          autofocus: true,
          child: _buildLayout(context, presentationState, theme),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, PresentationState presentationState,
      ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left panel: Slide thumbnails (12% width)
          SizedBox(
            width: 150,
            child: SlideListPanel(
              onAddSlide: () => _editorState.startNewSlide(context),
              onClearAll: _confirmClearAll,
            ),
          ),

          const SizedBox(width: 4),

          // Center panel: HTML editor + preview (flex: 1)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top action bar (Templates, Export, Present, Clear)
                _buildTopBar(context, presentationState, theme),

                const SizedBox(height: 4),

                // Main editor area
                const Expanded(
                  child: HtmlEditorPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PresentationState presentationState,
      ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Templates
          _actionButton(
            context,
            icon: Icons.palette_outlined,
            label: context.l10n.templates,
            onPressed: _showTemplateGallery,
          ),
          const SizedBox(width: 4),
          // Export
          _actionButton(
            context,
            icon: Icons.download,
            label: context.l10n.export,
            onPressed: _showExportDialog,
          ),
          const SizedBox(width: 4),
          _actionButton(
            context,
            icon: Icons.people_outline,
            label: context.l10n.collaboration,
            onPressed: _showCollaboration,
          ),
          const SizedBox(width: 4),
          // Present
          if (presentationState.slides.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PresentScreen(state: presentationState),
                ));
              },
              icon: const Icon(Icons.play_arrow, size: 14),
              label: Text(context.l10n.present,
                  style: const TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const SizedBox(width: 4),
          // Present From Current
          if (presentationState.slides.isNotEmpty &&
              presentationState.currentSlideIndex >= 0 &&
              presentationState.currentSlideIndex < presentationState.slides.length)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PresentScreen(
                    state: presentationState,
                    startSlide: presentationState.currentSlideIndex,
                  ),
                ));
              },
              icon: const Icon(Icons.play_circle_outline, size: 14),
              label: Text(context.l10n.presentFromCurrent,
                  style: const TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const Spacer(),
          // Slide counter
          Text(
            context.l10n.slideCount(presentationState.slides.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          // Undo/Redo
          IconButton(
            icon: Icon(Icons.undo,
                size: 16,
                color: presentationState.canUndo
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline.withValues(alpha: 0.3)),
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: presentationState.canUndo
                ? () => presentationState.undo()
                : null,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: Icon(Icons.redo,
                size: 16,
                color: presentationState.canRedo
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline.withValues(alpha: 0.3)),
            tooltip: 'Redo (Ctrl+Y)',
            onPressed: presentationState.canRedo
                ? () => presentationState.redo()
                : null,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          // Clear all
          if (presentationState.slides.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
              tooltip: context.l10n.clearAllSlides,
              onPressed: _confirmClearAll,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
