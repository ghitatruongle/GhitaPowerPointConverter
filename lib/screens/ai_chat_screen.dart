import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/presentation_state.dart';

class AiChatScreen extends StatefulWidget {
  final AIProviderManager aiProviderManager;

  const AiChatScreen({super.key, required this.aiProviderManager});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  bool _isGenerating = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvider = widget.aiProviderManager.selectedProvider;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header with provider selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            selectedProvider != null &&
                                    selectedProvider.formatType == 'anthropic'
                                ? Icons.smart_toy_outlined
                                : Icons.psychology_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Assistant',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (selectedProvider != null)
                                Text(
                                  '${selectedProvider.name} · ${selectedProvider.selectedModel}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'System Prompt',
                    onPressed: _showSystemPromptEditor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Provider Settings',
                    onPressed: _showProviderSettings,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Messages area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      final String content = message['content'] ?? '';
                      final List? slides = message['slides'];

                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.8),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUser ? 'You' : (selectedProvider?.name ?? 'AI'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUser
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(content),
                              if (slides != null && slides.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      ...slides.map((s) {
                                        final title =
                                            s['title'] ?? 'Untitled';
                                        return ActionChip(
                                          avatar: const Icon(
                                              Icons.add_to_photos,
                                              size: 16),
                                          label: Text('Add "$title"',
                                              style:
                                                  const TextStyle(fontSize: 11)),
                                          onPressed: () {
                                            Provider.of<PresentationState>(
                                                    context,
                                                    listen: false)
                                                .addSlide({
                                              'title': title,
                                              'htmlContent':
                                                  s['htmlContent'] ?? '',
                                              'timestamp': DateTime.now()
                                                  .millisecondsSinceEpoch,
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Added "$title" to slides!')),
                                            );
                                          },
                                        );
                                      }),
                                      if (slides.length > 1)
                                        ActionChip(
                                          avatar: const Icon(
                                              Icons.add_circle_outline,
                                              size: 16),
                                          label: Text('Add All (${slides.length})',
                                              style:
                                                  const TextStyle(fontSize: 11)),
                                          onPressed: () {
                                            final state = Provider.of<
                                                    PresentationState>(
                                                context,
                                                listen: false);
                                            for (final s in slides) {
                                              state.addSlide({
                                                'title':
                                                    s['title'] ?? 'Untitled',
                                                'htmlContent':
                                                    s['htmlContent'] ?? '',
                                                'timestamp': DateTime.now()
                                                    .millisecondsSinceEpoch,
                                              });
                                            }
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Added all ${slides.length} slides!')),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              if (!isUser && content.contains('<') &&
                                  !content.startsWith('Error:') &&
                                  slides == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.add_to_photos,
                                        size: 16),
                                    label: const Text('Add to Slides',
                                        style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      Provider.of<PresentationState>(context,
                                              listen: false)
                                          .addSlide({
                                        'title': 'AI Generated Slide',
                                        'htmlContent': content,
                                        'timestamp': DateTime.now()
                                            .millisecondsSinceEpoch,
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Added to presentation slides!')),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Input section
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Describe presentation topic or HTML slide content...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty && !_isGenerating) {
                          _messageController.clear();
                          await _generateHtmlForPresentation(text);
                        }
                      },
                    ),
            ),
            onSubmitted: (text) async {
              final trimmed = text.trim();
              if (trimmed.isNotEmpty && !_isGenerating) {
                _messageController.clear();
                await _generateHtmlForPresentation(trimmed);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'AI Presentation Assistant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask AI to generate HTML slides for your presentation!\n'
            'e.g. "Create 3 slides about Machine Learning"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateHtmlForPresentation(String prompt) async {
    setState(() {
      _messages.add({'role': 'user', 'content': prompt});
      _isGenerating = true;
    });

    try {
      // Detect if user wants multiple slides
      final multiSlideMatch =
          RegExp(r'(?:create|generate|make|write)\s+(\d+)\s*(?:slide|presentation|topic)s?',
                  caseSensitive: false)
              .firstMatch(prompt);
      final slideCount = multiSlideMatch != null
          ? int.tryParse(multiSlideMatch.group(1) ?? '') ?? 3
          : 1;

      if (slideCount > 1) {
        final slides = await widget.aiProviderManager
            .generateMultipleSlides(prompt, slideCount: slideCount);

        if (mounted) {
          final content = 'Generated ${slides.length} slides for your topic.';
          setState(() {
            _messages.add({
              'role': 'multi_slide',
              'content': content,
              'slides': slides,
            });
            _isGenerating = false;
          });
        }
      } else {
        final htmlContent =
            await widget.aiProviderManager.generateHtmlFromPrompt(prompt);

        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': htmlContent});
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages
              .add({'role': 'assistant', 'content': 'Error: ${e.toString()}'});
          _isGenerating = false;
        });
      }
    }
  }

  void _showSystemPromptEditor() {
    final manager = widget.aiProviderManager;
    final controller = TextEditingController(text: manager.systemPrompt);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom System Prompt'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'System Prompt',
              hintText:
                  'You are an expert in generating presentation HTML slides...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              manager.updateSystemPrompt(
                  'You are an expert in generating presentation HTML slides. '
                  'Return ONLY valid HTML fragment (no markdown, no explanation). '
                  'Use <h1> for title, <p> for paragraphs, <ul>/<li> for lists. '
                  'No external CSS/JS references.');
              controller.dispose();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System prompt reset to default!')),
              );
            },
            child: const Text('Reset to Default'),
          ),
          ElevatedButton(
            onPressed: () {
              manager.updateSystemPrompt(controller.text.trim());
              controller.dispose();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System prompt saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProviderSettings() {
    final manager = widget.aiProviderManager;
    final currentProvider =
        manager.selectedProvider ?? AIProviderConfig.defaultProvider();
    final apiKeyController = TextEditingController(text: currentProvider.apiKey);
    final nameController = TextEditingController(text: currentProvider.name);
    final baseUrlController =
        TextEditingController(text: currentProvider.baseUrl);
    final temperatureController = TextEditingController(
        text: currentProvider.temperature.toStringAsFixed(1));
    final maxTokensController = TextEditingController(
        text: currentProvider.maxTokens.toString());
    final models = List<String>.from(currentProvider.availableModels);
    String selectedModel = currentProvider.selectedModel;
    String newModelInput = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('AI Provider Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Provider Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: models.contains(selectedModel) ? selectedModel : models.first,
                  decoration: const InputDecoration(
                    labelText: 'Active Model',
                    border: OutlineInputBorder(),
                  ),
                  items: models.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedModel = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Available Models:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...models.map((m) {
                      final isActive = m == selectedModel;
                      return Chip(
                        label: Text(m,
                            style: TextStyle(
                                fontSize: 11,
                                color: isActive
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface)),
                        backgroundColor: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        deleteIcon: Icon(Icons.close, size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onDeleted: () {
                          if (models.length <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Provider must have at least 1 model.')),
                            );
                            return;
                          }
                          setDialogState(() {
                            models.remove(m);
                            if (selectedModel == m) {
                              selectedModel = models.first;
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Add new model',
                          hintText: 'e.g. gpt-4-turbo',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) => newModelInput = val.trim(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add model',
                      onPressed: () {
                        final trimmed = newModelInput.trim();
                        if (trimmed.isEmpty) return;
                        if (models.any((m) => m.toLowerCase() == trimmed.toLowerCase())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$trimmed" already exists.')),
                          );
                          return;
                        }
                        setDialogState(() {
                          models.add(trimmed);
                          selectedModel = trimmed;
                          newModelInput = '';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: temperatureController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (0.0 - 2.0)',
                    hintText: '0.7',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxTokensController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Tokens',
                    hintText: '4096',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                apiKeyController.dispose();
                nameController.dispose();
                baseUrlController.dispose();
                temperatureController.dispose();
                maxTokensController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final temperature =
                    double.tryParse(temperatureController.text.trim()) ?? 0.7;
                final maxTokens =
                    int.tryParse(maxTokensController.text.trim()) ?? 4096;
                if (models.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Provider must have at least 1 model.')),
                  );
                  return;
                }
                if (!models.contains(selectedModel)) {
                  selectedModel = models.first;
                }
                final updated = currentProvider.copyWith(
                  name: nameController.text.trim(),
                  baseUrl: baseUrlController.text.trim(),
                  apiKey: apiKeyController.text.trim(),
                  availableModels: models,
                  selectedModel: selectedModel,
                  temperature: temperature.clamp(0.0, 2.0),
                  maxTokens: maxTokens.clamp(1, 128000),
                );
                manager.updateProvider(updated);
                apiKeyController.dispose();
                nameController.dispose();
                baseUrlController.dispose();
                temperatureController.dispose();
                maxTokensController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provider settings saved!')),
                );
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
