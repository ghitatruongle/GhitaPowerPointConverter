import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/presentation_state.dart';
import '../../services/template_service.dart';
import '../../models/slide_template.dart';
import '../../screens/present_screen.dart';
import '../../screens/widgets/slide_preview.dart';
import 'editor_state.dart';
import 'slide_list_panel.dart';
import 'html_editor_panel.dart';

/// Main editor shell with PowerPoint-style 3-panel layout:
/// Left: Slide thumbnails | Center: HTML editor + preview | Right: (future Properties)
///
/// This replaces the monolithic HtmlToPPTScreen with a clean, composable layout.
class EditorShell extends StatefulWidget {
  const EditorShell({super.key});

  @override
  State<EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends State<EditorShell> {
  late final EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState();
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  // ---- Export Dialog ----

  Future<void> _showExportDialog() async {
    final nameController = TextEditingController(text: 'Presentation_Output');
    ExportFormat selectedFormat = ExportFormat.pptx;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Presentation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a file name and format:'),
              const SizedBox(height: 12),
              SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(
                    value: ExportFormat.pptx,
                    label: Text('PPTX'),
                    icon: Icon(Icons.slideshow, size: 18),
                  ),
                  ButtonSegment(
                    value: ExportFormat.html,
                    label: Text('HTML'),
                    icon: Icon(Icons.html, size: 18),
                  ),
                  ButtonSegment(
                    value: ExportFormat.pdf,
                    label: Text('PDF'),
                    icon: Icon(Icons.picture_as_pdf, size: 18),
                  ),
                ],
                selected: {selectedFormat},
                onSelectionChanged: (Set<ExportFormat> newSelection) {
                  setDialogState(() {
                    selectedFormat = newSelection.first;
                    nameController.text = selectedFormat == ExportFormat.pptx
                        ? 'Presentation_Output'
                        : 'presentation';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  suffixText: switch (selectedFormat) {
                    ExportFormat.pptx => '.pptx',
                    ExportFormat.html => '.html',
                    ExportFormat.pdf => '.pdf',
                  },
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a file name')),
                  );
                  return;
                }
                Navigator.pop(context, '$name|${selectedFormat.index}');
              },
              child: Text(switch (selectedFormat) {
                ExportFormat.pptx => 'Export PPTX',
                ExportFormat.html => 'Export HTML',
                ExportFormat.pdf => 'Export PDF',
              }),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();

    if (result != null) {
      final parts = result.split('|');
      final name = parts[0];
      final formatIndex = int.parse(parts[1]);
      final format = ExportFormat.values[formatIndex];
      await _performExport(name, format);
    }
  }

  Future<void> _performExport(String fileName, ExportFormat format) async {
    final presentationState =
        Provider.of<PresentationState>(context, listen: false);
    if (presentationState.slides.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No slides to export! Add a slide first.')),
        );
      }
      return;
    }

    _editorState.setLoading(true);

    try {
      String exportedPath;
      switch (format) {
        case ExportFormat.pptx:
          exportedPath = await presentationState.exportToPPT(fileName);
          break;
        case ExportFormat.html:
          exportedPath = await presentationState.exportToHtml(fileName);
          break;
        case ExportFormat.pdf:
          exportedPath = await presentationState.exportToPdf(fileName);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully to: $exportedPath'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: ${e.toString()}')),
        );
      }
    } finally {
      _editorState.setLoading(false);
    }
  }

  // ---- Template Gallery ----

  Future<void> _showTemplateGallery() async {
    final templateService = TemplateService();
    final templates = await templateService.loadTemplates();
    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No templates available.')),
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
          title: const Text('Choose a Template'),
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
                      child: const Text('Use'),
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
              child: const Text('Close'),
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
                const Text('HTML Preview:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _editorState.applyTemplate(template, context);
            },
            child: const Text('Use This Template'),
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
        title: const Text('Clear All Slides'),
        content: Text(
            'Are you sure you want to delete all ${state.slides.length} slides? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              state.clearSlides();
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Deleted all slides'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => state.undo(),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Clear All'),
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
      child: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true):
                () => _editorState.addOrUpdateSlide(context),
            const SingleActivator(LogicalKeyboardKey.keyE, control: true):
                () => _showExportDialog(),
            const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                () => _showExportDialog(),
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                () => presentationState.undo(),
            const SingleActivator(LogicalKeyboardKey.keyY, control: true):
                () => presentationState.redo(),
          },
          child: _buildLayout(context, presentationState, theme),
        ),
      ),
    );
  }

  Widget _buildLayout(
      BuildContext context, PresentationState presentationState, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left panel: Slide thumbnails (15% width)
          SizedBox(
            width: 200,
            child: SlideListPanel(
              onAddSlide: () {
                _editorState.clearEditor();
              },
              onClearAll: _confirmClearAll,
            ),
          ),

          const SizedBox(width: 8),

          // Center panel: HTML editor + preview (flex: 1)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top action bar (Templates, Export, Present, Clear)
                _buildTopBar(context, presentationState, theme),

                const SizedBox(height: 8),

                // Main editor area
                Expanded(
                  child: HtmlEditorPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, PresentationState presentationState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Templates
            _actionButton(
              context,
              icon: Icons.palette_outlined,
              label: 'Templates',
              onPressed: _showTemplateGallery,
            ),

            const SizedBox(width: 4),

            // Export
            _actionButton(
              context,
              icon: Icons.download,
              label: 'Export',
              onPressed: _showExportDialog,
            ),

            const SizedBox(width: 4),

            // Present
            if (presentationState.slides.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        PresentScreen(state: presentationState),
                  ));
                },
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Present', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),

            const Spacer(),

            // Slide counter
            Text(
              '${presentationState.slides.length} slides',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),

            const SizedBox(width: 8),

            // Undo/Redo
            IconButton(
              icon: Icon(Icons.undo, size: 18,
                  color: presentationState.canUndo
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline.withValues(alpha: 0.3)),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: presentationState.canUndo ? () => presentationState.undo() : null,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(Icons.redo, size: 18,
                  color: presentationState.canRedo
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline.withValues(alpha: 0.3)),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: presentationState.canRedo ? () => presentationState.redo() : null,
              visualDensity: VisualDensity.compact,
            ),

            // Clear all
            if (presentationState.slides.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                tooltip: 'Clear All Slides',
                onPressed: _confirmClearAll,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
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

enum ExportFormat { pptx, html, pdf }
