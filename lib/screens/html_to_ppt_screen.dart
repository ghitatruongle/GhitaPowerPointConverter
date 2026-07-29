import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController.text = 'New Slide';
  }

  Future<void> _addSlideFromHtml() async {
    final rawHtml = _htmlController.text.trim();
    if (rawHtml.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HTML content cannot be empty.')),
      );
      return;
    }
    if (rawHtml.length > 100000) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HTML content is too long (max 100KB).')),
      );
      return;
    }
    // Strip dangerous tags (script, iframe, object, embed)
    final sanitizedHtml = rawHtml
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[\s\S]*?<\/iframe>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<object[\s\S]*?<\/object>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<embed[\s\S]*?\/>', caseSensitive: false), '');
    if (sanitizedHtml.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HTML contains only blocked elements.')),
      );
      return;
    }

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

      Provider.of<PresentationState>(context, listen: false).addSlide(slideMap);

      _htmlController.clear();
      _titleController.text = 'New Slide';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slide added successfully!')),
        );
      }
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

  Future<void> _exportToPPT() async {
    final presentationState = Provider.of<PresentationState>(context, listen: false);
    if (presentationState.slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No slides to export! Add a slide first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exportedPath = await presentationState.exportToPPT('Presentation_Output');

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

  @override
  Widget build(BuildContext context) {
    final presentationState = Provider.of<PresentationState>(context);
    final slides = presentationState.slides;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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

          Expanded(
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
                        hintText: '<h1>Presentation Header</h1><p>Slide content details...</p>',
                      ),
                      keyboardType: TextInputType.multiline,
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black12,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addSlideFromHtml,
                icon: const Icon(Icons.add_box),
                label: const Text('Add Slide'),
              ),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportToPPT,
                icon: const Icon(Icons.download),
                label: const Text('Export to PPTX'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _buildSlidesList(presentationState, slides),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidesList(PresentationState state, List<Map<String, dynamic>> slides) {
    if (slides.isEmpty) {
      return const Center(child: Text('No slides yet. Add your first slide!'));
    }

    return ListView.builder(
      itemCount: slides.length,
      itemBuilder: (context, index) {
        final slide = slides[index];
        final String title = slide['title'] ?? 'Slide ${index + 1}';
        final String htmlContent = slide['htmlContent'] ?? '';
        final contentPreview = htmlContent.length > 50 
            ? '${htmlContent.substring(0, 50)}...' 
            : htmlContent;
        
        return ListTile(
          leading: Icon(Icons.article, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text(contentPreview),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => state.removeSlide(index),
          ),
        );
      },
    );
  }
}

