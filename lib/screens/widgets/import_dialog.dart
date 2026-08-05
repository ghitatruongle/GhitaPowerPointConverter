import 'package:flutter/material.dart';
import '../../services/document_importer_service.dart';
import '../../models/slide.dart';
import '../../utils/error_mapper.dart';

/// Import Dialog — v1.2.0
/// Import slides from Markdown text or web URL.
class ImportDialog extends StatefulWidget {
  final void Function(List<Slide> slides)? onImportSlides;

  const ImportDialog({super.key, this.onImportSlides});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _markdownController = TextEditingController();
  final _urlController = TextEditingController();
  final DocumentImporterService _importer = DocumentImporterService();
  bool _isLoading = false;
  List<Slide>? _previewSlides;
  String _importMode = 'markdown';

  @override
  void dispose() {
    _markdownController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromMarkdown() async {
    final text = _markdownController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final slides = _importer.parseMarkdownToSlides(text);
      setState(() {
        _previewSlides = slides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorMapper.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final slides = await _importer.importFromWebUrl(url);
      setState(() {
        _previewSlides = slides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorMapper.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_upload),
                  const SizedBox(width: 12),
                  Text('Nhập Slides', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'markdown', label: Text('Markdown'), icon: Icon(Icons.article)),
                  ButtonSegment(value: 'url', label: Text('Web URL'), icon: Icon(Icons.link)),
                ],
                selected: {_importMode},
                onSelectionChanged: (v) => setState(() => _importMode = v.first),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _importMode == 'markdown'
                    ? Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _markdownController,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                labelText: 'Markdown Content',
                                hintText: '# Slide 1\n- Point A\n- Point B\n\n# Slide 2\nParagraph text...',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.article),
                              label: const Text('Parse Markdown'),
                              onPressed: _isLoading ? null : _importFromMarkdown,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Web URL',
                              hintText: 'https://example.com/article',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Fetch & Convert'),
                              onPressed: _isLoading ? null : _importFromUrl,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Preview
            if (_previewSlides != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preview: ${_previewSlides!.length} slides', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _previewSlides!.length,
                        itemBuilder: (ctx, i) {
                          final slide = _previewSlides![i];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${i + 1}. ${slide.title}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    slide.htmlContent.replaceAll(RegExp(r'<[^>]+>'), ''),
                                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _previewSlides == null || _previewSlides!.isEmpty
                        ? null
                        : () {
                            widget.onImportSlides?.call(_previewSlides!);
                            Navigator.pop(context);
                          },
                    child: Text('Thêm ${_previewSlides?.length ?? 0} Slides'),
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
