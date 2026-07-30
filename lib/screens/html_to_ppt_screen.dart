import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import '../providers/presentation_state.dart';
import '../services/template_service.dart';
import '../models/slide_template.dart';
import 'present_screen.dart';
import 'widgets/slide_preview.dart';
import 'widgets/wysiwyg_toolbar.dart';

class HtmlToPPTScreen extends StatefulWidget {
  const HtmlToPPTScreen({super.key});

  @override
  State<HtmlToPPTScreen> createState() => _HtmlToPPTScreenState();
}

enum ExportFormat { pptx, html, pdf }

class _HtmlToPPTScreenState extends State<HtmlToPPTScreen> {
  final _htmlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();

  // Editing mode: when editing an existing slide, store its index
  int? _editingIndex;

  // Per-slide transition override selected in the editor (null = deck effect)
  SlideEffect? _slideEffectOverride;

  // Live preview state (debounced from the HTML editor)
  Timer? _previewTimer;
  String _previewHtml = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = 'New Slide';
    _htmlController.addListener(_schedulePreviewUpdate);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _htmlController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _schedulePreviewUpdate() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _previewHtml = _htmlController.text);
    });
  }

  void _insertHtmlTag(String open, String close) {
    final text = _htmlController.text;
    final selection = _htmlController.selection;
    if (selection.isValid && selection.start >= 0 && selection.end <= text.length) {
      final selectedText = text.substring(selection.start, selection.end);
      final replacement = '$open$selectedText$close';
      final newText = text.replaceRange(selection.start, selection.end, replacement);
      _htmlController.text = newText;
      _htmlController.selection = TextSelection.collapsed(
        offset: selection.start + open.length + selectedText.length,
      );
    } else {
      _htmlController.text = '$text$open$close';
    }
  }

  // ---- Input Validation ----

  String? _validateAndSanitizeHtml(String rawHtml) {
    if (rawHtml.isEmpty) {
      return 'HTML content cannot be empty.';
    }
    if (rawHtml.length > 100000) {
      return 'HTML content is too long (max 100KB).';
    }
    // Strip dangerous tags (script, iframe, object, embed)
    final sanitizedHtml = rawHtml
        .replaceAll(
            RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<iframe[\s\S]*?<\/iframe>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<object[\s\S]*?<\/object>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<embed[\s\S]*?\/>', caseSensitive: false), '');
    if (sanitizedHtml.trim().isEmpty) {
      return 'HTML contains only blocked elements.';
    }
    return sanitizedHtml; // returns sanitized string if valid
  }

  // ---- Add / Update Slide ----

  Future<void> _addOrUpdateSlide() async {
    final rawHtml = _htmlController.text.trim();
    final validationResult = _validateAndSanitizeHtml(rawHtml);
    if (validationResult is String && validationResult.startsWith('HTML')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationResult)),
        );
      }
      return;
    }

    final sanitizedHtml = validationResult as String;
    final state = Provider.of<PresentationState>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      final document = html_parser.parse(sanitizedHtml);
      String title = _titleController.text.trim();

      // Auto-extract title from <h1> if available
      final h1 = document.querySelector('h1');
      if (h1 != null && h1.text.isNotEmpty) {
        title = h1.text;
      } else if (title.isEmpty) {
        title = 'Untitled Slide';
      }

      final slide = Slide(
        title: title,
        htmlContent: sanitizedHtml,
        notes: _notesController.text.trim(),
        effect: _slideEffectOverride,
      );

      if (_editingIndex != null) {
        // Update existing slide
        state.updateSlide(_editingIndex!, slide);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slide updated!')),
          );
        }
      } else {
        // Add new slide
        state.addSlide(slide);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slide added successfully!')),
          );
        }
      }

      _clearEditor();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Edit existing slide ----

  void _editSlide(int index) {
    final state = Provider.of<PresentationState>(context, listen: false);
    if (index < 0 || index >= state.slides.length) return;

    final slide = state.slides[index];
    _htmlController.text = slide.htmlContent;
    _titleController.text = slide.title;
    _notesController.text = slide.notes;
    setState(() {
      _editingIndex = index;
      _slideEffectOverride = slide.effect;
    });
  }

  // ---- Clear editor ----

  void _clearEditor() {
    _htmlController.clear();
    _titleController.text = 'New Slide';
    _notesController.clear();
    setState(() {
      _editingIndex = null;
      _slideEffectOverride = null;
    });
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
                        _applyTemplate(template);
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

  void _applyTemplate(SlideTemplate template) {
    _htmlController.text = template.htmlContent;
    _titleController.text = _extractTitleFromHtml(template.htmlContent);
    setState(() => _editingIndex = null);

    // Auto-apply recommended effect
    final state = Provider.of<PresentationState>(context, listen: false);
    state.setEffect(template.recommendedEffect);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${template.name}" template! '
            'Effect: ${_effectName(template.recommendedEffect)}'),
        duration: const Duration(seconds: 3),
      ),
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
                      'Effect: ${_effectName(template.recommendedEffect)}'),
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
              _applyTemplate(template);
            },
            child: const Text('Use This Template'),
          ),
        ],
      ),
    );
  }

  String _extractTitleFromHtml(String html) {
    try {
      final doc = html_parser.parse(html);
      final h1 = doc.querySelector('h1');
      if (h1 != null && h1.text.trim().isNotEmpty) {
        return h1.text.trim();
      }
    } catch (_) {}
    return 'New Slide';
  }

  String _effectName(SlideEffect effect) {
    switch (effect) {
      case SlideEffect.fade:
        return 'Fade';
      case SlideEffect.pushLeft:
        return 'Push Left';
      case SlideEffect.pushRight:
        return 'Push Right';
      case SlideEffect.pushUp:
        return 'Push Up';
      case SlideEffect.pushDown:
        return 'Push Down';
      case SlideEffect.wipe:
        return 'Wipe';
      case SlideEffect.splitIn:
        return 'Split In';
      case SlideEffect.splitOut:
        return 'Split Out';
      case SlideEffect.randomBar:
        return 'Random Bars';
      case SlideEffect.checkerboard:
        return 'Checkerboard';
      case SlideEffect.blinds:
        return 'Blinds';
      case SlideEffect.clock:
        return 'Clock';
      case SlideEffect.zoom:
        return 'Zoom';
      default:
        return 'None';
    }
  }

  Future<void> _exportToPPT() async {
    final fileName = await _showExportDialog();
    if (fileName == null) return; // user cancelled (export runs from dialog)
  }

  Future<String?> _showExportDialog() async {
    final nameController = TextEditingController(text: 'Presentation_Output');
    ExportFormat selectedFormat = ExportFormat.pptx;

    return showDialog<String>(
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
                    if (selectedFormat == ExportFormat.pptx) {
                      nameController.text = 'Presentation_Output';
                    } else {
                      nameController.text = 'presentation';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  hintText: selectedFormat == ExportFormat.pptx
                      ? 'My_Presentation'
                      : 'presentation',
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
                Navigator.pop(context, name);
                _performExport(name, selectedFormat);
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
  }

  Future<void> _performExport(String fileName, ExportFormat format) async {
    final presentationState =
        Provider.of<PresentationState>(context, listen: false);
    if (presentationState.slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No slides to export! Add a slide first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Clear all slides ----

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
              state.clearSlides();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All slides cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final presentationState = Provider.of<PresentationState>(context);
    final slides = presentationState.slides;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              () => _addOrUpdateSlide(),
          const SingleActivator(LogicalKeyboardKey.keyE, control: true):
              () => _exportToPPT(),
        },
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left panel: Editor
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Title input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Slide / Presentation Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Speaker Notes (optional)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<SlideEffect?>(
                              value: _slideEffectOverride,
                              hint: const Text('Deck effect',
                                  style: TextStyle(fontSize: 13)),
                              items: [
                                const DropdownMenuItem<SlideEffect?>(
                                  value: null,
                                  child: Text('Deck effect',
                                      style: TextStyle(fontSize: 13)),
                                ),
                                ...SlideEffect.values.map(
                                  (e) => DropdownMenuItem<SlideEffect?>(
                                    value: e,
                                    child: Text(_effectName(e),
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                              onChanged: (val) => setState(
                                  () => _slideEffectOverride = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // HTML editor + live preview
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                WysiwygToolbar(onInsertTag: _insertHtmlTag),
                                const Divider(height: 12),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      TextFormField(
                                        controller: _htmlController,
                                        maxLines: null,
                                        expands: true,
                                        decoration: const InputDecoration(
                                          labelText: 'HTML Content',
                                          border: InputBorder.none,
                                          hintText:
                                              '<h1>Title</h1><p>Content...</p><ul><li>Item</li></ul>',
                                        ),
                                        keyboardType: TextInputType.multiline,
                                      ),
                                if (_isLoading)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black12,
                                      child: const Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                  ),
                              ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_previewHtml.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: SlidePreview(
                              title: _titleController.text,
                              html: _previewHtml,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _showTemplateGallery,
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Templates'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addOrUpdateSlide,
                      icon: Icon(_editingIndex != null ? Icons.save : Icons.add_box),
                      label: Text(_editingIndex != null ? 'Update' : 'Add Slide'),
                    ),
                    if (_editingIndex != null)
                      TextButton.icon(
                        onPressed: _clearEditor,
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                      ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportToPPT,
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                    if (slides.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      PresentScreen(state: presentationState),
                                ));
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Present'),
                      ),
                    if (slides.isNotEmpty)
                      TextButton.icon(
                        onPressed: _confirmClearAll,
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        label: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right panel: Slide list
          Expanded(
            flex: 5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Slides (${slides.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (slides.isNotEmpty)
                          Text(
                            'Drag to reorder',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(child: _buildSlidesList(presentationState, slides)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  );
  }

  Widget _buildSlidesList(
      PresentationState state, List<Slide> slides) {
    if (slides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.slideshow,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No slides yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Write HTML above and tap "Add Slide" to get started!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: slides.length,
      onReorderItem: (oldIndex, newIndex) {
        state.moveSlide(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = lerpDouble(0, 6, animation.value);
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final slide = slides[index];
        final String title = slide.title;
        final String htmlContent = slide.htmlContent;

        return Card(
          key: ValueKey('slide_${slide.timestamp}_$index'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
              ),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  htmlContent.length > 60
                      ? '${htmlContent.substring(0, 60)}...'
                      : htmlContent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                _buildSlideThumbnail(htmlContent),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  tooltip: 'Preview slide',
                  onPressed: () => _previewSlide(slide),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit slide',
                  onPressed: () => _editSlide(index),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Duplicate slide',
                  onPressed: () => state.duplicateSlide(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  tooltip: 'Delete slide',
                  onPressed: () {
                    state.removeSlide(index);
                    final deletedSlide = slide;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted "$title"'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            state.addSlide(deletedSlide.copyWith(
                                timestamp:
                                    DateTime.now().millisecondsSinceEpoch));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () => _editSlide(index),
          ),
        );
      },
    );
  }

  /// Show a rendered preview of a slide in a dialog.
  void _previewSlide(Slide slide) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800,
          height: 480,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(slide.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SlidePreview(
                      title: slide.title, html: slide.htmlContent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a thumbnail preview chip showing slide structure
  Widget _buildSlideThumbnail(String html) {
    final h1Count = _countTag(html, 'h1');
    final h2Count = _countTag(html, 'h2');
    final pCount = _countTag(html, 'p');
    final liCount = _countTag(html, 'li');
    final hasTable = html.contains('<table');

    final chips = <Widget>[];
    if (h1Count > 0) chips.add(_thumbnailChip('H1', Colors.deepOrange));
    if (h2Count > 0) chips.add(_thumbnailChip('H2', Colors.orange));
    if (pCount > 0) chips.add(_thumbnailChip('$pCount¶', Colors.blue));
    if (liCount > 0) chips.add(_thumbnailChip('$liCount●', Colors.green));
    if (hasTable) chips.add(_thumbnailChip('▦', Colors.purple));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: chips,
    );
  }

  Widget _thumbnailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  int _countTag(String html, String tag) {
    final pattern = RegExp('<$tag[\\s>]', caseSensitive: false);
    return pattern.allMatches(html).length;
  }
}

/// Helper to lerp double values
double lerpDouble(double a, double b, double t) => a + (b - a) * t;
