import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import '../providers/presentation_state.dart';

class HtmlToPPTScreen extends StatefulWidget {
  const HtmlToPPTScreen({super.key});

  @override
  State<HtmlToPPTScreen> createState() => _HtmlToPPTScreenState();
}

class _HtmlToPPTScreenState extends State<HtmlToPPTScreen> {
  final _htmlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();

  // Editing mode: when editing an existing slide, store its index
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'New Slide';
  }

  @override
  void dispose() {
    _htmlController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
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

      final slideMap = {
        'title': title,
        'htmlContent': sanitizedHtml,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (_editingIndex != null) {
        // Update existing slide
        state.updateSlide(_editingIndex!, slideMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slide updated!')),
          );
        }
      } else {
        // Add new slide
        state.addSlide(slideMap);
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
    _htmlController.text = slide['htmlContent'] ?? '';
    _titleController.text = slide['title'] ?? '';
    setState(() {
      _editingIndex = index;
    });
  }

  // ---- Clear editor ----

  void _clearEditor() {
    _htmlController.clear();
    _titleController.text = 'New Slide';
    setState(() => _editingIndex = null);
  }

  // ---- Export ----

  Future<void> _exportToPPT() async {
    final presentationState =
        Provider.of<PresentationState>(context, listen: false);
    if (presentationState.slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No slides to export! Add a slide first.')),
      );
      return;
    }

    // Show save dialog
    final fileName = await _showExportDialog();
    if (fileName == null) return; // user cancelled

    setState(() => _isLoading = true);

    try {
      final exportedPath =
          await presentationState.exportToPPT(fileName);
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

  Future<String?> _showExportDialog() async {
    final nameController = TextEditingController(text: 'Presentation_Output');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Presentation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a file name for your PPTX presentation:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'My_Presentation',
                suffixText: '.pptx',
                border: OutlineInputBorder(),
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
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
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
      child: Column(
        children: [
          // Title input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Slide / Presentation Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // HTML editor
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                            '<h1>Title</h1><p>Slide content...</p><ul><li>Item</li></ul>',
                      ),
                      keyboardType: TextInputType.multiline,
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black12,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addOrUpdateSlide,
                icon: Icon(_editingIndex != null ? Icons.save : Icons.add_box),
                label: Text(_editingIndex != null ? 'Update Slide' : 'Add Slide'),
              ),
              if (_editingIndex != null)
                TextButton.icon(
                  onPressed: _clearEditor,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Edit'),
                ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportToPPT,
                icon: const Icon(Icons.download),
                label: const Text('Export PPTX'),
              ),
              if (slides.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmClearAll,
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text('Clear All',
                      style: TextStyle(color: Colors.red)),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Slides list
          Expanded(
            flex: 3,
            child: _buildSlidesList(presentationState, slides),
          ),
        ],
      ),
    ),
  ),
  );
  }

  Widget _buildSlidesList(
      PresentationState state, List<Map<String, dynamic>> slides) {
    if (slides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.slideshow,
                size: 64,
                color: Theme.of(context).colorScheme.outline),
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

    // Check if ReorderableListView can be used
    return ReorderableListView.builder(
      itemCount: slides.length,
      onReorderItem: (oldIndex, newIndex) {
        // With onReorderItem, newIndex is already adjusted for the removal
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
            final String title = slide['title'] ?? 'Slide ${index + 1}';
        final String htmlContent = slide['htmlContent'] ?? '';
        final contentPreview = htmlContent.length > 50
            ? '${htmlContent.substring(0, 50)}...'
            : htmlContent;

        // Build a simple thumbnail preview chip summary
        final thumbnailWidget = _buildSlideThumbnail(htmlContent);

        return Card(
          key: ValueKey('slide_${slide['timestamp']}_$index'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle,
                  color: Theme.of(context).colorScheme.outline),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contentPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                thumbnailWidget,
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    final deletedSlide = Map<String, dynamic>.from(slide);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted "$title"'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Restore with fresh timestamp and find correct position
                            final restored = Map<String, dynamic>.from(deletedSlide)
                              ..['timestamp'] =
                                  DateTime.now().millisecondsSinceEpoch;
                            state.addSlide(restored);
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
